# Diagramming Guides

This folder collects all diagramming-related documentation so it can be extracted into a dedicated repository later. For now it lives inside the Estates SFDX project to keep the AI agent prompt, styling guide, and supporting assets version-controlled with the rest of the implementation.

## Contents

- `d2-agent-guide.md` (coming next): system prompt, styling standards, and workflows for AI agents that generate Salesforce-compliant D2 diagrams using the TALA layout engine by default.

## Future Extraction Plan

When this content graduates into its own repository:

1. Copy this folder wholesale into the new repo root.
2. Update any relative links that point back into `docs/` inside this project.
3. Publish rendering scripts (e.g., `scripts/render_d2.sh`) or lightweight wrappers as part of the new repo's tooling instructions.
