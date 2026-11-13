# Open GTAS.msapp

GTAS.msapp is a native canvas-app file packaged with Microsoft Power Platform CLI 2.15.1 using its SourceCode layout. It contains 15 screens, the app formulas, and a native attachments form. Download the file itself from GitHub using Download raw file.

## Open and configure

1. Open Power Apps Studio in your authorized development environment.
2. Use Open / Browse to select GTAS.msapp.
3. Add SharePoint connections to the six lists below, using the list names exactly as shown.
4. Run App.OnStart, inspect App Checker, and resolve connection, formula or control-version issues reported by your tenant.
5. Deploy the service-owned command processor and apply the permissions in the PowerApps-v2 deployment guide.
6. Validate with separate traveler and approver accounts before saving and publishing.

Required data sources:

- GTASDraftsV2
- GTASRequestsV2
- GTASCommandsV2
- GTASAccessV2
- GTASRatesV2
- GTASPolicyV2

The companion guide is in GTAS/PowerApps-v2/README.md in Travel-Repo. The service-only ledger is configured by that deployment process and is not connected directly to the app.

## What is included

The file contains the native traveler, trip, itinerary, transportation, expenses, document, submission, processing, request, approval, coordinator and report screens. The attachments form is already present in this file, so skip the manual form-insertion step in the earlier source handoff.

The file deliberately contains no tenant-specific connection credentials or live SharePoint URLs. Data-source references remain unresolved until the six target lists are connected. Power Automate flows and SharePoint permissions are external dependencies and are not carried inside a standalone canvas-app file.

## Verification performed

- Microsoft CLI pack succeeded.
- Microsoft CLI unpack of the resulting file succeeded.
- All 17 app/screen/editor YAML files were preserved byte-for-byte through the pack/unpack round trip.
- ZIP integrity checks passed, and packed.json enables loading the native YAML source.
- App and screen documents passed the applicable Microsoft v3 source-schema constraints. The upstream schema contains an invalid regular expression in an unused code-component definition, so schema meta-validation was skipped. No code components are used.
- Studio import, formula binding against the six real lists, connector execution and tenant access isolation have not been tested here.

File SHA-256:
cb5be9b4456ee1b69e1ae23845808d5ad0f3f4d692118bf3e78e7cbdf762d9e6

## Attribution

The packaging reference uses standard metadata from Microsoft's MIT-licensed PowerApps-Tooling fixtures. The accompanying Microsoft-Tooling-LICENSE.txt retains that license.

[Microsoft canvas pack and unpack documentation](https://learn.microsoft.com/power-platform/developer/cli/reference/canvas)
