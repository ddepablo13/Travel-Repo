# GTAS Power Apps v2

This package replaces the original four-screen prototype source with a defined native canvas application and a service-controlled submission model. It contains 15 screens, formula files, a private-list provisioning script, a seven-list schema, Power Automate action build sheets, and executable policy acceptance checks.

**Delivery status** — authored source and locally checked rules. Power Apps Studio assembly, real SharePoint permissions, cloud flow execution, native export/import and device testing remain unverified. This folder is a source handoff. A tested .msapp or Power Platform solution export requires a tenant.

## Screens

| Screen | Purpose |
|---|---|
| Home | Own saved drafts and submitted requests |
| Traveler | Traveler identity, program, supervisor and conditional subcontractor |
| Trip | Dates, region, trip type, categories and purpose |
| Itinerary | Multiple dated destinations and approved rate references |
| Rates | Locality, effective dates and rate ID lookup |
| Transport | Conditional air, airport, rental, POV and rail expenses |
| Expenses | Registration, miscellaneous, hotel parking and resort fees |
| Documents | Native SharePoint attachment form |
| Submit | Review, estimated amount, validation and queued submission |
| CommandStatus | Processing result and authorized request/report link |
| Request | Read-only authorization, cost summary and decision history |
| WorkQueue | Requests shared for coordination or review |
| Decision | Assigned-stage approval, return, rejection and PM delegation |
| Closeout | Coordinator completion, actual cost and posting date |
| Reports | Program-scoped monthly export |

The native screens use the NNSA-site-derived navy/blue/gray palette with a gold masthead rule. Segoe UI provides a built-in Power Apps font. Flat work surfaces, consistent 44-pixel controls and visible keyboard focus prioritize forms and approval work. Native canvas controls approximate the glass-inspired visual hierarchy through surface contrast and layering. The app includes no role selector, fabricated production metrics or visible demo label.

## Build in the government development environment

1. Confirm the approved environment, SharePoint site, cloud boundary, licensing and connector availability. Connect PnP.PowerShell as the provisioning administrator using the tenant's approved authentication configuration. The provisioning script expects an existing authenticated connection and an existing service account.
2. Run Deployment/Provision-PrivateLists.ps1 with ServiceAccountLogin against a private, empty test site. Review its WhatIf output first. It refuses all existing list names. This script has been reviewed locally but has not run against SharePoint. Add the unique-field settings described below, and apply Deployment/SECURITY.md before sharing anything.
3. Configure GTASPolicyV2 with explicit policy decisions and resolved PM/coordinator/IT OPS/COR accounts. Use unique ProgramKey per active program. Load approved USD rates with locality, effective dates and source. Import no fictional rates into a live rate table.
4. Create a blank tablet canvas app at 1200 × 744, with scale-to-fit and locked aspect ratio for the initial desktop/tablet release. The fixed canvas layout scales to the viewport. Dedicated small-phone reflow remains future work and needs device validation.
5. Add the six canvas data sources listed in manifest.json using each user's SharePoint connection. The service-only ledger is never connected to the app. Set the data row limit to the tenant's standard; do not use this limit as a security control. Queries on author, owner, program and status must remain delegable. Resolve any Studio delegation warnings on your connector version. Monthly exports use server pagination.
6. Create all screens from the manifest before pasting controls. Apply Canvas/App.OnStart.fx to App.OnStart and Canvas/App.Formulas.fx to App.Formulas. Set App.StartScreen to Home. Set each screen Fill to Theme.Background. Paste each matching YAML control list through Studio's Paste code function. These are authored control snippets, and Studio must validate their installed control versions.
7. Insert DocumentsForm on Documents using the connected SharePoint form designer. Add only its Attachments field, retaining the generated attachment data card, and apply Canvas/DocumentsForm.properties.fx. This connector-generated form is the one manual control insertion. Upload and removal work only after SubmitForm succeeds. Set Home.OnVisible from its formula file if using request links.
8. Run App.OnStart, then App Checker. Resolve every error before previewing. If your Studio control version differs, insert the corresponding classic control and copy the properties across using its own generated YAML. Use English locale separators or convert them consistently.
9. Build the three flows in Flows/IMPLEMENTATION.md. Apply the rule tests and security matrix with separate test accounts. Approval actions operate through the canvas command queue. Email/Teams notifications link to the same record. Optional Approvals cards must use the same authorization and transition checks.
10. Run the tests in VALIDATION.md and record tenant evidence. Add the canvas app, flows, environment variables and connection references to a solution. Export it from Power Platform, import into a second test environment, rebind connections and site/list IDs, and repeat the critical tests. Deliver that verified export to the government production deployment process.

## Required list settings

- GTASLedgerV2 Title must enforce unique values. Derive it from the authenticated actor directory ID and command key.
- GTASRequestsV2 SubmissionKey must enforce unique values. Use draft:<draft ID> for a new request so a saved draft cannot create duplicate authorizations.
- GTASPolicyV2 ProgramKey must enforce unique values. Store one active policy per program.
- Enable versioning on all lists. GTASRequestsV2 and the private document library retain revision history. Exclude invoker edit/delete permission from commands and submitted requests.
- Set draft and command item-level read restrictions to Created By. The provisioner must verify all permission levels and effective access before enabling the app.

## Requirement decisions

The binder and user flow define sequential PM/coordinator, IT OPS, and COR review. The first draft's acting-approver swap is deferred for policy confirmation. Both final approvals remain required and distinct.

Authorized lodging uses the applicable rate. Above-rate quotes require justification and do not automatically increase authorization. First and last overnight M&IE days receive 75%. Interior days receive 100%. The destination active that day determines the rate. The last destination supplies the return-day rate.

Same-day M&IE requires an explicit program policy. Mileage rates are administrator-maintained. Foreign-currency conversion is outside this source release; international rates must be approved USD amounts. If a rate changes during a stay, add a new itinerary segment on the effective date, including the same locality if needed.

Actual cost supports zero and remains independent of authorization. Closing without actual cost is deferred. Monthly reporting groups by departure month and displays actual minus authorized variance. Vouchers, reimbursement, email import, traveler profiles and ServiceNow/ATOM integrations remain outside the current release.

## Source and validation references

[Studio code view](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/code-view)

[Source-code format limits](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/power-apps-yaml)

[Attachments control and saving a form](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/controls/control-attachments)

[SharePoint permissions through Power Automate](https://learn.microsoft.com/en-us/sharepoint/dev/business-apps/power-automate/guidance/manage-list-item-file-permissions)
