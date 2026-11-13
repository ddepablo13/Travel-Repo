# Validation record

## Completed locally

- Parsed all 15 screen YAML files as structured control lists.
- Checked control names for uniqueness and navigation targets against the screen manifest.
- Checked all direct Patch targets. Native source writes only drafts and the command inbox.
- Executed 22 policy-reference cases in Flows/Tests.mjs using fictional identities, destinations and rates.
- Inspected source formulas for role-switch controls and references to the legacy GTASRequests data source.
- Checked the source archive's entries and integrity.

Run the policy checks with Node using node Flows/Tests.mjs from this folder. The checks cover own-request access, cross-traveler and cross-program denial, on-behalf submission, rate locality/effective dates, M&IE, same-day policy, missing justification, duplicate itinerary dates, stale approvals, delegation, distinct final approvers, premature completion, zero actual cost and unauthorized posting.

## Requires tenant verification

| Check | Expected result | Current evidence |
|---|---|---|
| Paste all screen controls and bind formulas | App Checker has zero formula errors | Pending Studio |
| SharePoint provisioning | Private lists, expected fields and unique constraints | Pending test site |
| Permissions | Traveler B cannot access Traveler A through app, URL or API | Pending separate identities |
| Attachments | Save, reopen, remove and submit consistent attachment set | Pending native form |
| Flow processing | Queued command resolves to service-authored result | Pending cloud flows |
| Approval cycle | PM, IT OPS, COR enforced with correct assignments | Reference tests only |
| Revision | Old decisions rejected, new cycle starts at PM | Reference tests only |
| Retry | Duplicate and timed-out submissions create one canonical request | Pending ledger integration |
| PDF | Authorized readers only, current cycle's completed approval | Pending connector |
| Notifications | Correct recipients and working record link | Pending connectors |
| Reports | Correct scope, all pages, null actual and signed variance | Pending flow export |
| Desktop / tablet | No clipping, keyboard access, readable scaled layout | Pending native rendering |
| Small phone | Dedicated responsive layout | Deferred |
| Export/import | Second environment imports and passes core tests | Pending tenant export |

The HTML browser workspace is an earlier local prototype and is not evidence of native security, rendering, connector execution or successful Power Apps import.
