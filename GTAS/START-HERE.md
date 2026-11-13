# GTAS | GDIT Travel Authorization System

## Present it

Open **GTAS-Demo.html** in an approved browser. The demo uses fictional records and rates, stores requests in browser storage, and simulates roles through the dropdown. It runs offline and sends no notifications. Use a fresh browser profile for a clean seed. Never enter live traveler data in this demo.

1. Open Morgan Ellis's draft. Show the itinerary, expense estimate and GSA-style rate breakdown. Change Organization to Subcontractor to reveal the company field, then switch it back. Submit for review.
2. Switch to Program Manager and delegate to the GTAS Coordinator. Switch to Coordinator and approve. Switch to IT OPS and approve. Switch to COR and approve. To show a revision loop, return the request at IT OPS first, switch to Traveler, edit and resubmit, then repeat the approval sequence.
3. Open the approved request and choose **Print authorization / Save as PDF**. The browser print dialog can save the rendered authorization.
4. Switch to GTAS Coordinator. For the seeded trip, mark travel complete and post an actual job cost. Open the monthly report and export CSV. Variance is actual minus authorized. A blank actual stays blank.
5. Close by asking leadership to confirm approval ownership, the rate source, and where the government pilot should run.

## Transfer and build

This archive is a maker handoff. It includes four Power Apps Studio control snippets, a SharePoint field contract, and Power Automate build instructions. Canvas snippets have been checked as YAML only. The native app, cloud flows and tenant connections require assembly and validation in Power Platform. Use your organization's approved transfer channel.

1. In a government development environment, confirm the cloud boundary, Environment Maker rights, Dataverse solution availability, licensing, SharePoint access, connector policies and approved identities. Build against a new test site with fictional data.
2. Create **GTASRequests** using Schema.csv. Keep the internal names as written. Make SharePoint Title optional until the request-number flow writes it. Enable list versioning. Add the list to the app before pasting controls. Use a blank tablet canvas at roughly 1200 × 720. For the pilot snippets enable scale-to-fit. Verify desktop and tablet in Studio.
3. Create four blank screens named **Queue**, **EditTrip**, **Review**, and **Monthly**, with Queue first. Set screen Fill to `ColorValue("#F7F5EF")`. In the tree, select the matching screen and paste the controls from its YAML file through Studio. If Studio rejects a control version, insert the matching classic control, copy its generated YAML, and transfer the listed formulas to that control. Formulas use the English Power Fx separator conventions. Run App Checker and resolve all diagnostics before proceeding.
4. Add an Edit form bound to GTASRequests and the active record for supporting documents. Use the form Attachments card and SubmitForm, with validation and upload success confirmed before sending a submission. The current snippets do not contain that form. For an item that has already been submitted, keep the evidence snapshot and authorization document in a restricted library with versioning.
5. Implement the flows in FLOW-BUILD.md and replace direct pilot writes with the service-owned submit path described there before enabling real approvals. The snippets currently implement basic request entry, destinations, estimate, status and a limited report. Transportation and registration/other costs are aggregated inputs in Studio, while the browser demo shows the full conditional breakdown. Add per-mode controls using the browser demo's field layout and calculations before production. Add a coordinator actual-cost form or secured command and a history display. For reporting beyond the 20-row Studio preview, use the paginated export flow.
6. Add the app, flows, connection references and environment variables to a solution in the development tenant. Export from Power Platform after validation. Import into a separate approved test environment, rebind connection references and site/list settings, then repeat the acceptance cases. Use a managed export for production if the organization follows managed-solution deployment. A single app file carries the canvas app, so move the data and automation dependencies separately if using that route.

[Microsoft Learn — Studio code view](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/code-view) · [Canvas export and import options](https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/export-import-app) · [Export solutions](https://learn.microsoft.com/en-us/power-apps/maker/data-platform/export-solutions)

## Decisions to confirm

- The workbook and user flow require Program Manager, IT OPS, then COR. The binder confirms both final roles are required. The v0.1 draft mentions alternating IT OPS and COR when acting. The baseline uses the later sequential rule. Confirm acting assignments before configuring substitutes.
- Use the applicable lodging rate for authorized lodging. An above-rate quote requires justification and does not raise the amount automatically. Hotel parking and resort fees are separate. Exclude hotel internet and government vehicles per the binder.
- Apply 75% M&IE to the first and last days of an overnight itinerary and full M&IE on interior days. The demo uses the destination effective that day and assigns the final day's M&IE to the last stop. Same-day trips omit lodging and M&IE pending policy confirmation. International rate sources, mileage rates, meals provided and exceptions need policy-owner decisions before live use.
- The monthly report groups by departure month. Close without actual cost only where policy permits. Actual cost posting is for reporting and does not initiate a voucher or reimbursement.
- Production rate lookups, Teams, email, PDF generation and guest/subcontractor access depend on the target tenant. ATOM, ServiceNow, email ingestion and vouchers are outside this release.

## Acceptance cases

- Save a draft and reopen it after reload. Test a subcontractor with and without a company, missing destinations, reversed dates, duplicate destination start days, optional email and optional files.
- Three-day two-stop estimate: first day Arlington at $185 lodging and $80 M&IE, next two days Richmond at $140 lodging and $74 M&IE. Expected lodging $325, M&IE $189.50, base total $514.50 before transportation and extras. An above-rate quote without justification blocks submission.
- Approve directly and through delegation. Return and resubmit, reject at each stage, attempt a duplicate response and attempt a decision as the wrong account. Prove no PDF is generated before COR approval.
- Open the final PDF as an authorized traveler and as an unrelated account. Check email and Teams recipient scope. Complete travel only after return, post $0 and a positive cost, and verify signed variance and blank pending actuals.
- Reimport the exported package in a separate approved environment. Validate connection rebinding, row access, flow failure recovery and reporting at more than one page of records.
