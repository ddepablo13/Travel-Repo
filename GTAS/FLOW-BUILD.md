# Power Automate build sheets

Use solution-aware cloud flows. Set site, list, library and default PM, coordinator, IT OPS and COR identities via environment configuration. Confirm the exact connector set in the destination cloud. Use a service connection under an approved identity and a restricted approval/audit list.

## 1. Number drafts

SharePoint **When an item is created** → if Title is empty, update Title with:

`concat('GTAS-',formatDateTime(triggerBody()?['Created'],'yyyy'),'-',formatNumber(triggerBody()?['ID'],'00000'))`

Use one request list as the numbering authority. Keep ID as the immutable internal key. The creation timestamp above uses UTC. Use an approved timezone conversion if year follows local office time.

## 2. Submit and route

For the connected pilot, replace direct Submit Patch with a protected submit command. Derive actor from the platform's authenticated caller context, then check traveler ownership or coordinator membership. Never authorize based on a user-supplied email. Separate mutable draft storage from the service-owned request and approval records if travelers have direct edit rights to drafts. SharePoint UI hiding or app-level filters cannot enforce field security. Use restricted lists and mediated writes, or implement the equivalent with Dataverse security roles and server-side validation.

Read the draft and attachments, validate required fields and rates, recompute costs from normalized itinerary and expense records, and persist an immutable submitted snapshot with cycle, rate source, dates and submitting principal. Use an ETag conditional update or equivalent transactional claim to prevent concurrent submit. Transition Draft or Returned → Submitted → Program Manager. Store configuration-resolved approver identities. Fail to an operator queue on unresolved assignments. Never skip a stage on connector failure.

Build one stage worker using **Create an approval** and **Wait for an approval**, or the tenant-approved equivalent. Use custom responses with one assigned approver. Program Manager sees Approve, Return for revision, Reject and Delegate. Other stages see the first three responses. Store the generated Approval ID before waiting. Include request number and authenticated app link, with only the minimum sensitive information allowed by tenant policy.

| Current stage | Approve | Delegate | Return for revision | Reject |
|---|---|---|---|---|
| Program Manager | IT OPS | Coordinator Review | Returned | Rejected |
| Coordinator Review | IT OPS | Invalid | Returned | Rejected |
| IT OPS | COR | Invalid | Returned | Rejected |
| COR | Approved | Invalid | Returned | Rejected |

Create or claim a unique stage key before issuing the approval. On response, re-read the parent and compare cycle, stage, approval ID and responder to the assignment. Record the actor, timestamp and comment with the decision. Perform the transition with a conditional update. If audit was saved before transition failed, resume the same decision from the stored record. Use a timeout branch and exception queue with request ID, stage and approval ID. If issuance times out before the ID is captured, reconcile with the approval service before issuing again. Retain previous cycles on return and resubmit from Program Manager. Verify identity cannot satisfy both IT OPS and COR under the baseline setup.

## 3. Publish authorization and notify

Trigger on Approved with a valid final decision for the current cycle. Use a deterministic path such as `<request-number>-r<cycle>.pdf`. Populate an approved Word template with number, traveler, itinerary, itemized authorized costs, approval names and dates, and relevant justification. Convert using an approved Word/PDF connector, store in the restricted SharePoint library and write PdfUrl after successful creation. Use create-or-reuse by deterministic path to recover after retries. If PDF conversion is unavailable in the tenant, route to the coordinator for controlled manual publication.

After the link is saved, use the approved Outlook action to notify the traveler and GTAS Coordinator. Add a Teams notification to the authorized coordinator channel or chat, subject to policy. Use a notification log keyed by request/cycle/channel, and surface delivery failures for reconciliation. Keep the request Approved if PDF or notification delivery fails. Do not copy sensitive itinerary or attachment contents into a broad Teams channel.

## 4. Complete, post cost and report

Run a daily scheduled flow in the approved business timezone, or provide a protected coordinator action. Move only Approved trips with return date reached into Travel Completed. A coordinator-only cost command validates a nonnegative actual, posting date and optional notes, and conditionally moves Travel Completed → Closed. Allow closing without cost only after policy confirmation. Never overwrite the authorized snapshot.

For monthly CSV, accept a validated YYYY-MM month and require coordinator/PM access. Query indexed Departure from month start inclusive to next month exclusive. Page through eligible approved/completed/closed requests. Decode all itinerary cities, use ISO dates, and include authorization, nullable actual and nullable actual minus authorized. Escape spreadsheet formula prefixes in free text. Store export in the restricted library and return an authorized link.

## Operational checks

Use role-specific test accounts. Verify a traveler cannot modify service-owned statuses or estimates directly in SharePoint. Verify a PM cannot advance IT OPS or COR, that a returned revision invalidates old decisions, and that retries after partial failure preserve a single effective transition. Review service account ownership, retention, connector availability and access before publishing.
