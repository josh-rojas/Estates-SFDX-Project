# D2 Diagrams

**Last Updated:** November 2, 2025  
**Version:** 1.0

---

## Overview

This directory contains D2 diagram sources and rendered SVG outputs for the Succession Management System documentation. D2 is a modern diagram scripting language that allows us to version control our diagrams alongside our code.

---

## Directory Structure

```
docs/diagrams/
├── README.md           # This file
├── d2/                 # D2 source files (.d2)
│   ├── architecture.d2
│   ├── automation_sequence.d2
│   ├── case_state.d2
│   └── data_model_erd.d2
└── svg/                # Rendered SVG outputs
    ├── architecture.svg
    ├── automation_sequence.svg
    ├── case_state.svg
    └── data_model_erd.svg
```

---

## Available Diagrams

### 1. architecture.d2 → architecture.svg

**Purpose:** Component architecture diagram showing system layers

**Shows:**
- UI Layer: 5 Lightning Web Components
- Controller Layer: 5 Apex classes
- Automation Layer: Trigger + Generator
- Data Layer: Standard objects

**Used In:** `docs/01-architecture-automation-data.md`

**Key Features:**
- Primary automation path (trigger-based) shown with thick purple lines
- Inactive flows shown with dashed red lines
- Data flow from UI → Controller → Automation → Data

---

### 2. automation_sequence.d2 → automation_sequence.svg

**Purpose:** Sequence-like flow diagram showing trigger-based automation

**Shows:**
- User → LWC → Case → Trigger → Generator → Tasks → Chatter
- Step-by-step pathway task automation
- Key implementation details

**Used In:** `docs/01-architecture-automation-data.md`

**Key Features:**
- Shows exact file locations for each component
- Highlights SYSTEM_MODE usage in task creation
- Notes that flows are inactive

---

### 3. case_state.d2 → case_state.svg

**Purpose:** State machine diagram for 4-phase workflow

**Shows:**
- Contact Cadence → Pathway Selection → Pathway Execution → Closure
- State transitions with guard conditions
- Circuit breaker loop for contact cadence

**Used In:** `docs/01-architecture-automation-data.md`

**Key Features:**
- Shows key Case fields that drive transitions
- Includes SLA tracking notes
- Shows multi-successor handling

---

### 4. data_model_erd.d2 → data_model_erd.svg

**Purpose:** Entity-relationship diagram for standard objects

**Shows:**
- Case, Task, Account, Contact, FinancialAccount, FinancialAccountRole
- Relationships: 1:N, N:1, self-referential
- Key fields used by automation

**Used In:** `docs/01-architecture-automation-data.md`

**Key Features:**
- Person Account pattern highlighted
- Automation entry point noted
- Relationship cardinalities shown

---

## Regenerating Diagrams

### Prerequisites

**Install D2:**
```bash
# Install D2 (if not already installed)
curl -fsSL https://d2lang.com/install.sh | sh -s --

# Verify installation
d2 --version
```

**Expected Output:**
```
v0.7.1
```

---

### Quick Regeneration

**Regenerate all diagrams:**
```bash
# From repository root
./scripts/render_d2.sh
```

**This will:**
1. Render all `.d2` files in `docs/diagrams/d2/`
2. Output SVG files to `docs/diagrams/svg/`
3. Use ELK layout engine (default)
4. Apply theme 200 (neutral colors)
5. Add 20px padding
6. Disable sketch mode (clean lines)

---

### Custom Layout Engine

**Use TALA layout engine (if available):**
```bash
# Set D2_LAYOUT environment variable
D2_LAYOUT=tala ./scripts/render_d2.sh
```

**Available Layout Engines:**
- `elk` - Eclipse Layout Kernel (default, bundled with D2)
- `dagre` - Dagre layout algorithm (bundled with D2)
- `tala` - Terrastruct Automatic Layout Algorithm (requires license)

**Note:** TALA is not available in the bundled D2 version. It requires a Terrastruct license or special build. The render script defaults to ELK, which provides excellent layout quality.

---

### Manual Rendering

**Render a specific diagram:**
```bash
# Ensure D2 is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Render with ELK layout
d2 --layout elk --theme 200 --pad 20 --sketch=false \
  docs/diagrams/d2/architecture.d2 \
  docs/diagrams/svg/architecture.svg

# Render with TALA layout (if available)
d2 --layout tala --theme 200 --pad 20 --sketch=false \
  docs/diagrams/d2/architecture.d2 \
  docs/diagrams/svg/architecture.svg
```

---

## Editing Diagrams

### D2 Syntax Basics

**Nodes:**
```d2
# Simple node
node_name: Node Label

# Node with shape
node_name: Node Label {
  shape: rectangle
}
```

**Connections:**
```d2
# Simple connection
node1 -> node2

# Connection with label
node1 -> node2: Label

# Connection with style
node1 -> node2: Label {
  style.stroke: purple
  style.stroke-width: 3
}
```

**Containers:**
```d2
# Container with children
container: Container Label {
  child1: Child 1
  child2: Child 2
  
  child1 -> child2
}
```

**Styling:**
```d2
# Node styling
node: Label {
  style.fill: "#e3f2fd"
  style.stroke: "#1976d2"
  style.font-color: "#000"
}

# Connection styling
node1 -> node2: {
  style.stroke: red
  style.stroke-width: 2
  style.stroke-dash: 3
}
```

---

### Example: Add New Component to Architecture Diagram

**Edit:** `docs/diagrams/d2/architecture.d2`

```d2
# Add new LWC to UI layer
ui_layer: UI Layer {
  # ... existing components ...
  
  # Add new component
  new_lwc: newComponentName {
    shape: rectangle
    style.fill: "#e3f2fd"
    style.stroke: "#1976d2"
  }
}

# Add connection to controller
ui_layer.new_lwc -> controller_layer.new_controller: calls
```

**Regenerate:**
```bash
./scripts/render_d2.sh
```

**Verify:**
```bash
# View SVG in browser or editor
open docs/diagrams/svg/architecture.svg
```

---

## D2 Resources

### Official Documentation

- **D2 Language:** https://d2lang.com/
- **D2 Playground:** https://play.d2lang.com/
- **D2 GitHub:** https://github.com/terrastruct/d2
- **D2 Examples:** https://d2lang.com/tour/intro

### Layout Engines

- **ELK:** https://www.eclipse.org/elk/
- **Dagre:** https://github.com/dagrejs/dagre
- **TALA:** https://terrastruct.com/tala (commercial)

### Themes

D2 includes several built-in themes:

- `0` - Neutral (default)
- `1` - Neutral Grey
- `2` - Flagship Terrastruct
- `3` - Cool Classics
- `4` - Mixed Berry Blue
- `5` - Grape Soda
- `6` - Aubergine
- `7` - Colorblind Clear
- `8` - Vanilla Nitro Cola
- `100` - Terminal
- `101` - Terminal Grayscale
- `200` - Origami (used in this project)

**Change theme:**
```bash
# Edit scripts/render_d2.sh
# Change --theme 200 to --theme <number>
```

---

## Troubleshooting

### Issue: D2 Command Not Found

**Symptom:**
```
bash: d2: command not found
```

**Solution:**
```bash
# Add D2 to PATH
export PATH="$HOME/.local/bin:$PATH"

# Or reinstall D2
curl -fsSL https://d2lang.com/install.sh | sh -s --
```

---

### Issue: Render Script Not Executable

**Symptom:**
```
bash: ./scripts/render_d2.sh: Permission denied
```

**Solution:**
```bash
# Make script executable
chmod +x scripts/render_d2.sh

# Run again
./scripts/render_d2.sh
```

---

### Issue: TALA Layout Not Available

**Symptom:**
```
Error: layout engine "tala" not found
```

**Solution:**
TALA is not available in the bundled D2 version. Use ELK instead:
```bash
# Use default (ELK)
./scripts/render_d2.sh

# Or explicitly set ELK
D2_LAYOUT=elk ./scripts/render_d2.sh
```

---

### Issue: Diagram Not Rendering Correctly

**Symptom:**
- Nodes overlapping
- Connections crossing incorrectly
- Layout looks wrong

**Solution:**
1. Try different layout engine:
   ```bash
   D2_LAYOUT=dagre ./scripts/render_d2.sh
   ```

2. Adjust diagram structure:
   - Simplify complex connections
   - Use containers to group related nodes
   - Add explicit positioning hints

3. Check D2 syntax:
   ```bash
   # Validate D2 file
   d2 --dry-run docs/diagrams/d2/architecture.d2
   ```

---

## Best Practices

### 1. Keep Diagrams Simple

- Focus on one concept per diagram
- Avoid too many nodes (max 20-30)
- Use containers to group related items
- Minimize connection crossings

### 2. Use Consistent Styling

- Use same colors for same types of components
- Use same shapes for same layers
- Use consistent line styles (solid, dashed, dotted)
- Use consistent font sizes

### 3. Version Control

- Commit both `.d2` source and `.svg` output
- Add meaningful commit messages
- Review diffs before committing
- Keep diagrams in sync with code

### 4. Documentation

- Embed diagrams in markdown with relative paths
- Add alt text for accessibility
- Explain diagram purpose and key features
- Update diagrams when architecture changes

---

## Maintenance

### When to Update Diagrams

**Update diagrams when:**
- Adding new LWC components
- Adding new Apex classes
- Changing automation logic
- Adding new objects or fields
- Changing data model relationships
- Changing workflow states

### Update Process

1. **Edit D2 source file** in `docs/diagrams/d2/`
2. **Regenerate SVG** with `./scripts/render_d2.sh`
3. **Verify output** by viewing SVG
4. **Update documentation** if diagram purpose changed
5. **Commit changes** with descriptive message

### Review Schedule

- **Weekly:** Review diagrams for accuracy
- **Monthly:** Update diagrams for any changes
- **Quarterly:** Comprehensive diagram audit

---

**Document Status:** Last verified November 2, 2025 | Commit: [current]
