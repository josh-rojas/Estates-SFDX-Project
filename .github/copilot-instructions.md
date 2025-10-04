## Quick orientation for AI coding agents

This repository is a Salesforce SFDX project focused on the "Succession" feature set (OmniStudio + Apex + LWCs + Flows). Below are concise, actionable points an automated coding agent should follow to be immediately productive.

1. Project layout & key locations
   - Salesforce source: `force-app/` (see `sfdx-project.json` — `force-app` is the default package directory).
   - OmniStudio Data Packs and manifests: `omnistudio-datapacks/` (e.g. `SuccessionManagementComplete.json`).
   - Documentation: `docs/` (INDEX.md links to architecture, test-data guidance, and validation issues).
   - Manifests for deployments: `manifest/` (multiple `package-*.xml` files).
   - Apex/test helpers and scripts: `scripts/apex/` and `force-app/main/default/classes` (search for `SuccessionTestDataFactory`).

2. Big-picture architecture (short)
   - OmniStudio components (OmniScripts, DataRaptors, FlexCards) drive the UI workflows.
   - Apex Test Data Factory (`SuccessionTestDataFactory`) is used widely for generating test scenarios; docs in `docs/test-data-factory-usage.md`.
   - Flows and custom fields are tightly coupled to OmniStudio components; many components rely on specific custom fields (see `omnistudio-datapacks/README.md` dependencies and `docs/field-documentation-succession.md`).

3. Build / test / lint commands (explicit)
   - Lint JavaScript (LWC/Aura): `npm run lint` (runs `eslint **/{aura,lwc}/**/*.js`).
   - Run unit tests (LWC Jest): `npm test` or `npm run test:unit`.
   - Watch/debug LWC tests: `npm run test:unit:watch` / `npm run test:unit:debug`.
   - Generate coverage: `npm run test:unit:coverage`.
   - Prettier formatting: `npm run prettier` and verify with `npm run prettier:verify`.
   - Commits trigger `husky` + `lint-staged` (auto-format and run ESLint/Jest for related files).

4. Deployment & data pack notes
   - CI / manual deploys use SFDX CLI and the `manifest/` package XML files. `sfdx force:source:deploy` or packaging flows are typical.
   - OmniStudio Data Pack workflow: development uses individual JSONs in `force-app/`; release bundles use `omnistudio-datapacks/SuccessionManagementComplete.json`.
   - If Vlocity/OmniStudio Build Tool is available, example CLI commands from the repo docs:
     - Export: `vlocity packExport -job DataPackJob.yaml`
     - Deploy: `vlocity packDeploy -job DataPackJob.yaml`

5. Project-specific conventions and gotchas
   - Use both individual component files (for development) and the Data Pack manifest (for release notes and bundled installs).
   - Tests may be blocked by org validation rules; check `docs/VALIDATION_ISSUES_CURRENT_STATUS.md` and `docs/VALIDATION_RULE_FIX.md` before assuming failing tests are code regressions.
   - Source API version is defined in `sfdx-project.json` (`65.0`); keep new Apex/LWC code compatible.
   - Semantic versioning for data packs: bump `omnistudio-datapacks/*.json` per docs when adding components.

6. Where to find examples in the repo
   - OmniStudio Data Pack explanation and example: `omnistudio-datapacks/README.md` (includes DataPack name and component list).
   - Test data generation example (Apex anonymous snippet) in `omnistudio-datapacks/README.md` — search for `SuccessionTestDataFactory.generateMultipleSuccessorsScenario()`.
   - Deployment manifest examples: files under `manifest/` (e.g. `package-omnistudio-succession-hierarchy.xml`).

7. Integration and external dependencies
   - Financial Services Cloud and OmniStudio (v258.4+) are required for runtime compatibility (noted in datapack README).
   - SFDX CLI, Vlocity/OmniStudio Build tools (optional but used for DataPack operations), and Node/NPM for local tests.

8. Guidance for code changes and PRs
   - Keep changes focused: update individual component JSONs in `force-app/` and update corresponding entries in `omnistudio-datapacks/` when adding/removing components.
   - Update `docs/` (INDEX.md or specific doc) for any architectural or validation-rule changes.
   - Run `npm run prettier` and `npm run lint` locally before pushing; CI enforces these via hooks.

9. Quick search terms to locate important code
   - `SuccessionTestDataFactory` — test data entry points (Apex).
   - `SuccessionManagementComplete` — datapack manifest bundle name.
   - `Pathway_Confirmed__c` / other custom field names — fields that appear across components (see `omnistudio-datapacks/README.md` dependencies).

10. When uncertain, consult these docs first
   - `docs/INDEX.md` — overview and links to authoritative docs.
   - `omnistudio-datapacks/README.md` — component lists and install notes.
   - `docs/VALIDATION_ISSUES_CURRENT_STATUS.md` — common test blockers.

If anything here is unclear or you need deeper coverage of a specific area (Apex tests, LWC patterns, or deployment CI), tell me which area and I'll expand the instructions/examples.
