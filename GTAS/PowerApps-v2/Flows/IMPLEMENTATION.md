# Power Automate implementation

These are executable-policy references and action-level build instructions. Cloud flows must be created, bound, and tested in the tenant. The JavaScript module is a local acceptance reference and is not invoked by the canvas app or Power Automate.

## Flow 1 — Process a GTAS command

Create a solution-aware automated flow using SharePoint **When an item is created**, bound to GTASCommandsV2 with the service account connection. Restrict flow ownership to administrators. Use trigger concurrency 1 for the first release so all state transitions serialize. Initialize local command state from the trigger ID, regardless of the item's supplied State. Scheduled retries must go through this same serialized worker or an equivalent single queue consumer.

Use a Try scope, Catch scope configured after failure/timeout, and Finalize scope. Catch writes an operator-visible error and a safe user-facing ResultMessage. It must never advance approval after an error.

### Common actions

1. **Get item** from Commands by ID. Resolve Created By email and directory identity as actor. Validate Title is a GUID-form command key and Operation is one of Submit, Decide, Complete, Close, Report.
2. Query commands by Created By plus Title. If this actor/key has a previously completed command, copy its safe result to this row and exit. If the same key is associated with different operation, payload, or request, reject it. A key is scoped to actor to prevent one user reserving another user's keys.
3. Persist a service-owned processing claim in a private ledger or the canonical request's AppliedCommandKeys before side effects. The command list itself allows an invoker to create arbitrary initial field values, so it is never sufficient evidence that processing already succeeded. Use only service-authored ledger state for idempotency.
4. Load current server data, role assignments, program policy, and request where applicable. Enforce SECURITY.md. Update State to Processing. For an item created with a forged success field, the canvas may display that user's own forged row, but the canonical request and documents stay service-controlled.
5. Dispatch to a Switch on Operation. Every branch must finish by writing State, ResultMessage, ResultRequestId and optional ResultUrl.
6. Keep a durable ledger keyed by actor ID and command key with payload hash, operation, request ID, phase and result. Provision this ledger as service-only storage in the target tenant. Before creating a canonical record, reserve its logical submission key in the ledger, then record the resulting request ID. On an ambiguous timeout, reconcile by that logical key before repeating the create. The provisioned SubmissionKey field on Requests enforces uniqueness. For an initial submission use draft:<draft ID> as this key. Resubmitting the same draft returns its existing request when the snapshot matches, or rejects it with instructions to revise from the canonical record when it differs. For revisions use the existing request ID and ExpectedCycle as the single-use revision key. The command ledger key remains actor ID plus command key.
7. For existing-request transitions, GET the item ETag and use SharePoint HTTP conditional MERGE with If-Match. On HTTP 412, re-read and revalidate cycle and stage. Never retry a stale decision by accepting the newer stage.

Example service-controlled status update, with placeholders bound to preceding actions:

    Method: POST
    Uri: _api/web/lists/getbytitle('GTASRequestsV2')/items(<requestId>)
    Headers:
      IF-MATCH: <ETag read from the request>
      X-HTTP-Method: MERGE
      Accept: application/json;odata=nometadata
      Content-Type: application/json;odata=nometadata
    Body:
      {"Status":"IT OPS","AssignedEmail":"<policy IT OPS email>"}

Use a SharePoint HTTP action under the service connection. Determine and validate the current entity representation in the destination tenant before enabling the flow.

### Submit

Read the referenced draft as the service and verify its Created By equals the command actor. Parse the command's snapshot with the schema in command-contract.json. The snapshot is the immutable content submitted by the user. Validate all header values and destinations using Rules.mjs as the acceptance reference. Client-side validation improves usability and is repeated on the server.

Read all required rate IDs from GTASRatesV2 and the enabled policy for the program. Rates require USD, locality match, source and effective dates covering every allocated day. Store a snapshot of rates used. Lodging uses the approved cap, even with a justified above-cap quote. Split a stay into rate periods in the processing representation when a policy permits a rate change within a stay. The current UI requires each destination segment to fit a single rate period. Same-day M&IE is policy-controlled. Omit excluded transportation categories and reject negative or malformed active costs.

For attachments, require saved draft content to match the submitted snapshot. Capture the draft version and attachment names/content, copy to a private request folder, then re-read the version and attachment manifest. Abort and request resubmission if they changed. Treat copying as a staged operation. Do not publish until the complete submitted snapshot and attachment set are consistent.

Create or revise the canonical request. A revision is allowed only from Returned with the same owner and program and matching ExpectedCycle. Increment Cycle, persist the snapshot, rate snapshot and recomputed amount, clear prior PDF link, and reset to Program Manager. Keep prior cycles and PDFs for audit with their own revision paths. Resolve PM, coordinator, IT OPS and COR from server policy. Reject missing routes or identical IT OPS/COR principals.

Stage the request privately, apply traveler and program-reader access, and set the initial assigned approver. Publish Submitted and then Program Manager history events, maintaining UTC timestamp, actor, cycle, action and comment. The current state becomes Program Manager. Return the canonical ID only after permissions are applied successfully.

### Decide

The payload is outcome, comment and expectedStage. Envelope ExpectedCycle must match the current cycle. Require actor equals AssignedEmail.

| Current stage | Approve | Return | Reject | Delegate |
|---|---|---|---|---|
| Program Manager | IT OPS | Returned | Rejected | Coordinator Review |
| Coordinator Review | IT OPS | Returned | Rejected | Reject command |
| IT OPS | COR | Returned | Rejected | Reject command |
| COR | Approved | Returned | Rejected | Reject command |

Choose next AssignedEmail from policy. Record the stage result once per cycle/stage and command key. Reconcile permissions when assignment changes. A completed approval stage cannot be re-executed by an old response.

Use the canvas decision screen as the release's decision entry point. Email and Teams link to that record. If the tenant adds Approvals connector cards, map their authenticated response and approval ID into the same service transition logic, and disable or reconcile duplicate decision channels.

### Complete

Require a coordinator assignment for the program. Check Approved, ExpectedCycle, and return date on or before the current date in the configured business timezone. Set Travel Completed.

### Close

Require coordinator and Travel Completed. Validate actual is a finite nonnegative number, including zero. Require a valid posting date between return date and today. Write Actual, Posted and CostNotes, preserve Authorized, append history and set Closed. Closing without an actual cost requires an additional explicitly configured policy and is not enabled in this UI.

### Report

Require a valid YYYY-MM and program report permission. Query Departure >= first day and < first day of next month with ProgramKey restriction and pagination. Include Approved, Travel Completed and Closed. Parse snapshot destinations. Columns are Traveler, Destination, Departure, Return, Authorized, Actual, Variance. Leave actual and variance empty when Actual is null. Variance equals Actual minus Authorized. Escape CSV cells with leading spreadsheet-formula characters. Store privately, grant read to the requesting reporter, and return ResultUrl.

## Flow 2 — Publish approved authorization

Trigger on a request entering Approved. Verify the recorded successful COR event for the current cycle. Claim request/cycle in the private ledger. Populate the tenant-approved Word template and convert to PDF using available approved connectors. Use request-number/cycle as the deterministic filename. Store the PDF privately, apply the parent read policy, and then set PdfUrl. If PDF conversion fails, keep Approved, mark publication failure in the ledger, and notify the coordinator for retry.

The Word template must contain request number, cycle, traveler, organization/company, supervisor, program, purpose/categories, dates, all destinations, daily rates and sources, itemized transport/expenses, authorized total, above-rate justifications and the dated approval history. Do not include actual-job-cost fields on the original authorization.

## Flow 3 — Notify and reconcile

Trigger from committed stage events in the ledger. Send authorized recipients a link to the canvas record. Use minimal email/Teams text and confirm recipient scope against current policy. Write channel delivery status separately so notification failures cannot roll back approval or create duplicate approvals. A scheduled reconciliation flow identifies stuck processing leases, missing PDFs and notification failures. Requeue only operations that the ledger says are safe to retry.

## Initial expressions

Request number from immutable canonical list ID:

    concat('GTAS-',formatDateTime(utcNow(),'yyyy'),'-',formatNumber(outputs('Create_request')?['body/ID'],'00000'))

Actor from SharePoint command Created By, after retrieving the item:

    toLower(outputs('Get_command')?['body/Author/Email'])

Resolve the exact action output shape from a real test run. Do not substitute a Power Apps input for Created By.

Month start after strict month validation:

    concat(variables('Month'),'-01')

Next month:

    formatDateTime(addToTime(concat(variables('Month'),'-01T00:00:00Z'),1,'Month'),'yyyy-MM-dd')

Keep numeric SharePoint IDs distinct from the display request number. The original request number remains fixed across revisions.
