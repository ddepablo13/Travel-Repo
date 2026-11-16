# GTAS tenant-based rebuild

Use GTAS-Tenant-Rebuilt.msapp. GTAS.msapp is an identical copy.

This replaces the earlier YAML-only package that failed to open. It was rebuilt from the actual app export you supplied on November 16, preserving its native control templates, authoring metadata, and SharePoint connection definition.

## Open
1. Download the new .msapp file, then open it from Power Apps Studio in your authorized development environment.
2. The original connected request screen opens first. Reauthorize its existing SharePoint connection if requested.
3. Select **GTAS workspace** to reach the additional 15 workflow screens.
4. Before using that expanded workflow, connect GTASDraftsV2, GTASRequestsV2, GTASCommandsV2, GTASAccessV2, GTASRatesV2, and GTASPolicyV2. Follow GTAS/PowerApps-v2/README.md for schema and deployment requirements.
5. Review App Checker and test with separate traveler and approver accounts before publishing.

## Verification and limits
- Microsoft canvas packaging library loaded the modified sources and generated the native app with zero errors. Its source-checksum warning is expected after editing.
- The generated file was successfully loaded and unpacked again with zero errors.
- ZIP integrity passed; 17 native control documents contain App plus 16 screens, with unique control IDs.
- Corrected gallery metadata, Segoe UI font references, and the Documents form layout.
- These checks do not validate Power Apps Studio import, Power Fx binding, connector operations, or account isolation. Studio import remains unverified.
- Six additional list bindings, Power Automate deployment, and server-enforced permissions remain tenant setup. Reference flow logic is not a deployed approval flow.
- The original connected screen and its permissions are preserved; this rebuild does not establish traveler isolation.
- This file includes the tenant connection metadata from your export. It is not a tenant-neutral template.
- The original export was not modified.

SHA-256: 08225847b871bfad12e3ef49f7a3cb5316ac0ad26aeacc02fcc9d409b5130320
