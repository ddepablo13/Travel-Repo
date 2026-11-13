# Identity and record access

The deployment uses seven new lists ending in V2. Keep legacy prototype lists disconnected from this app. All SharePoint connections in the canvas app use the signed-in user's connection.

The canvas controls write only GTASDraftsV2 and GTASCommandsV2. A service-owned Power Automate processor performs changes to submitted requests. The server derives the actor from the command item's immutable Created By identity. A submitted ownerEmail is a requested traveler identity and never an authorization credential.

## Permissions to apply before sharing

| Resource | Traveler / app users | Service account | Program staff |
|---|---|---|---|
| Drafts | Read and edit only items they created | Full control | Own drafts, including on-behalf drafts |
| Commands | Add items and read own items, no edit/delete | Full control | Same as travelers |
| Requests | Read individual shared records only | Full control | Read individual records within approved assignment/scope |
| Access assignments | Read individually shared own assignments | Full control | Administrators maintain |
| Rates and policies | Read only | Read; designated administrators maintain | Designated rate/policy administrators maintain |
| Authorization documents | Read individual request folder only | Full control | Same readers as the parent request |
| Report exports | Read export shared to requesting authorized reporter only | Full control | Access rechecked for each report |

Create dedicated permission levels from Read. For commands add Add Items only, with no Edit Items, Delete Items, Manage Lists, Manage Permissions or Override List Behaviors. For drafts add Add Items and Edit Items and retain read, excluding Manage Lists and Override List Behaviors. Set the lists' advanced item settings to Read items created by the user and edit items created by the user. Verify those restrictions using ordinary test accounts. Do not grant travelers site-member Edit or Full Control on these lists.

The provisioning script creates private lists and retains the provisioning administrator and service account. It does not grant application users access automatically. Break permissions on an empty dedicated site or remove broad inherited site membership before running it, because list creation and inheritance breaking are separate operations. Keep the site private until provisioning is complete.

For submitted records, start from a private list with service-only write. Break each item's inheritance without copying permissions. Grant Read to the authoritative traveler, current approver, and the permitted coordinator/reporter principals for that program. Administrators remain privileged administrators. When approval assignment changes, recalculate the complete allowed read set, then remove obsolete approver grants. A user who also owns the request or coordinates the program retains access through that independent role. Apply the same policy to documents and snapshots. Never grant all employees Read at the requests-list level.

A coordinator's on-behalf draft stays private to the coordinator. On return, the traveler or authorized coordinator starts a new draft from the returned canonical snapshot. The service checks the existing request's owner, program and revision cycle. This avoids using the coordinator's Created By identity as the traveler's ownership.

## Server checks

1. Read the immutable command by ID. Ignore user-supplied State, result fields, actor, approver and cost totals.
2. Resolve command Created By to the directory identity. Read enabled access assignments from the protected access list.
3. For Submit, require the actor to own the draft and either be the requested traveler or be an enabled coordinator for the requested program. Resolve the traveler to a real directory account before sharing. A contact email is optional and never confers access.
4. For Decide, require actor equals current AssignedEmail, current cycle equals ExpectedCycle, and expected stage equals current status. The response UI cannot choose the next approver.
5. For Complete and Close, require current program coordinator membership and validate dates/state/cycle.
6. For Report, require CanReport for the requested program before querying any rows. Restrict the export itself.
7. Re-evaluate authorization when processing queued work. A revoked assignment must invalidate queued commands.
8. Keep the default error message for an inaccessible ID equivalent to an unknown ID, to avoid revealing another traveler's request existence.

## Required isolation test

Create Traveler A, Traveler B, PM, IT OPS, COR, coordinator for P1, coordinator for P2, and an administrator. Submit a P1 request as A. As B, test the app list, direct SharePoint URL, REST read, attachments, PDF, direct command injection, and modified ownerEmail. All must fail to disclose A's information or modify the request. Test that P2's coordinator cannot read or act on P1. Test that the PM cannot write Status directly or approve IT OPS/COR. Repeat after delegation, revision and role revocation. Capture evidence in VALIDATION.md.

The included JavaScript reference tests verify policy decisions with supplied identities. Only these tenant tests verify actual SharePoint isolation.

## References

[Run-only connection identities](https://learn.microsoft.com/en-us/power-automate/create-team-flows)

[SharePoint item permissions in Power Automate](https://learn.microsoft.com/en-us/sharepoint/dev/business-apps/power-automate/guidance/manage-list-item-file-permissions)

[SharePoint REST permission inheritance](https://learn.microsoft.com/en-us/sharepoint/dev/sp-add-ins/set-custom-permissions-on-a-list-by-using-the-rest-interface)
