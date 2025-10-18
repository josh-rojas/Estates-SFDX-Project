# Documentation Index

**Last Updated:** October 15, 2025

---

## 📚 Essential Documentation (Read in Order)

1. **[System Architecture](01-SYSTEM-ARCHITECTURE.md)**  
   Architecture, data model, components, design decisions, Person Account compatibility

2. **[Deployment & CI/CD](02-DEPLOYMENT-AND-CICD.md)**  
   Deployment procedures, CumulusCI, GitHub Actions, troubleshooting

3. **[Admin Runbook](03-ADMIN-RUNBOOK.md)**  
   Service Cloud setup, Email-to-Case, demo prep, day-to-day operations

4. **[Field Reference](04-FIELD-REFERENCE.md)**  
   All 20 custom fields documented (16 Case + 2 Activity + 2 Account)

5. **[Testing & Demo Data](05-TESTING-AND-DATA.md)**  
   Test scenarios, Snowfakery data generation, multi-successor testing

6. **[Security & Compliance](06-SECURITY.md)**  
   Permissions, FLS, email compliance, production hardening

---

## 📂 Archive

- **[archive/2025-10-14/](archive/2025-10-14/)** - Historical audits, deployment logs, migration notes

---

## 🚀 Quick Links

**Getting Started:**
- Deploy: See [02-DEPLOYMENT-AND-CICD.md](02-DEPLOYMENT-AND-CICD.md#quick-start)
- Setup demo: See [03-ADMIN-RUNBOOK.md](03-ADMIN-RUNBOOK.md#demo-prep-checklist)
- Test data: See [05-TESTING-AND-DATA.md](05-TESTING-AND-DATA.md#quick-start)

**Reference:**
- Field meanings: [04-FIELD-REFERENCE.md](04-FIELD-REFERENCE.md)
- Component list: [01-SYSTEM-ARCHITECTURE.md](01-SYSTEM-ARCHITECTURE.md#component-inventory)
- Security model: [06-SECURITY.md](06-SECURITY.md)

---

## 🗺️ Diagrams Index

Curated visuals (prefer PlantUML; Mermaid used for process flow). Images are pre-rendered to `docs/diagrams/images`.

- Architecture Process (Mermaid)
  - `docs/diagrams/images/mermaid/succession-phases.png`
- Data Model (ERD)
  - `docs/diagrams/images/erd/data-model.png`
- Component Architecture (PlantUML)
  - `docs/diagrams/images/plantuml/component-architecture.png`
- Pathway Task Automation (Mermaid)
  - `docs/diagrams/images/mermaid/pathway-task-automation.png`
- Contact Cadence – Unlock Sequence (Mermaid)
  - `docs/diagrams/images/mermaid/contact-cadence-sequence.png`
- Status Coordination – State Machine (PlantUML)
  - `docs/diagrams/images/plantuml/status-coordination-state.png`
- Multi-Successor Case Hierarchy (PlantUML)
  - `docs/diagrams/images/plantuml/multi-successor-object.png`
- CI/CD Pipeline (PlantUML)
  - `docs/diagrams/images/plantuml/ci-cd-pipeline.png`

Render all diagrams again with:

- `scripts/render_diagrams.sh` (renders `.puml` and `.mmd` from `docs/diagrams/src` to PlantUML/Mermaid folders)

Source files live in:

- `docs/diagrams/src`

---

## 📊 Documentation Stats

- **Essential docs:** 6
- **Archived docs:** 20+
- **Total reduction:** 29 → 6 files (79% reduction)
- **Coverage:** Architecture, deployment, operations, reference, testing, security
