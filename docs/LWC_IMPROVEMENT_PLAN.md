# LWC Improvement Implementation Plan

**Created:** October 29, 2025
**Priority:** Address Critical & High Priority Items
**Timeline:** Phased approach

## Immediate Actions (This Session)

### Phase 1A: Critical Accessibility Fixes (30 min)

**Goal:** Fix accessibility violations that affect usability

#### 1. Add Reduced Motion Support (All Components with Animations)

**File:** [successionContactCadence.css](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.css)

**Changes:**
```css
/* Wrap existing animations */
@media (prefers-reduced-motion: no-preference) {
  @keyframes pulse-warning {
    0%, 100% { border-color: #ff9900; box-shadow: 0 0 0 rgba(255, 153, 0, 0.4); }
    50% { border-color: #ffb75d; box-shadow: 0 0 8px rgba(255, 153, 0, 0.6); }
  }

  @keyframes shimmer {
    0% { background-position: -1000px 0; }
    100% { background-position: 1000px 0; }
  }

  .card-current.negative-outcome {
    animation: pulse-warning 2s ease-in-out infinite;
  }

  .card-locked::after {
    animation: shimmer 2s infinite linear;
  }
}

/* Static fallback for reduced motion */
@media (prefers-reduced-motion: reduce) {
  .card-current.negative-outcome {
    border: 2px solid var(--slds-g-color-warning-base-60, #ff9900);
    /* No animation */
  }

  .card-locked::after {
    display: none; /* Remove shimmer */
  }

  .card-locked {
    opacity: 0.6; /* Static visual indicator */
    background: repeating-linear-gradient(
      45deg,
      #f5f5f5,
      #f5f5f5 10px,
      #e8e8e8 10px,
      #e8e8e8 20px
    );
  }
}
```

**Impact:** Users with vestibular disorders or motion sensitivity can use the component safely

---

#### 2. Add Focus Indicators

**File:** [successionContactCadence.css](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.css)

**Changes:**
```css
/* Add visible focus states for toggle buttons */
.toggle-button-left:focus,
.toggle-button-right:focus {
  outline: 2px solid var(--slds-g-color-brand-base-60, #0176d3);
  outline-offset: 2px;
  z-index: 10;
}

/* Enhanced focus for keyboard users */
.toggle-button-left:focus-visible,
.toggle-button-right:focus-visible {
  outline: 3px solid var(--slds-g-color-brand-base-60, #0176d3);
  outline-offset: 3px;
  box-shadow: 0 0 0 4px rgba(1, 118, 211, 0.2);
}

/* Card action buttons */
.card button:focus-visible {
  outline: 2px solid var(--slds-g-color-brand-base-60, #0176d3);
  outline-offset: 2px;
}
```

**Impact:** Keyboard users can see where focus is

---

#### 3. Fix Error Notification Pattern

**File:** [recordPathwaySelection.html](../force-app/main/default/lwc/recordPathwaySelection/recordPathwaySelection.html)

**Find:**
```html
<div class="slds-notify slds-notify_alert slds-alert_error" role="alert">
  <h2>Error</h2>
  <p>{errorMessage}</p>
</div>
```

**Replace with:**
```html
<div class="slds-scoped-notification slds-theme_error" role="alert">
  <div class="slds-media">
    <div class="slds-media__figure">
      <lightning-icon icon-name="utility:error"
                      variant="error"
                      size="small"
                      alternative-text="Error">
      </lightning-icon>
    </div>
    <div class="slds-media__body">
      <p><strong>Error:</strong> {errorMessage}</p>
    </div>
  </div>
</div>
```

**Impact:** Consistent SLDS error pattern, better screen reader support

---

#### 4. Add aria-live for Dynamic Updates

**File:** [recordPathwaySelection.html](../force-app/main/default/lwc/recordPathwaySelection/recordPathwaySelection.html)

**Find:**
```html
<template if:true={showSuccess}>
  <div class="slds-box slds-theme_success">
```

**Replace with:**
```html
<template if:true={showSuccess}>
  <div class="slds-box slds-theme_success" aria-live="polite" aria-atomic="true">
```

**Impact:** Screen readers announce success confirmation

---

### Phase 1B: High Priority SLDS Token Migration (45 min)

**Goal:** Replace most critical hardcoded colors for theme compatibility

#### 5. Create Token Variable Map

**File:** [successionContactCadence.css](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.css)

**Add at top of file:**
```css
/**
 * SLDS Design Token Mapping
 * Provides fallbacks for older SLDS versions
 */
:host {
  /* Brand Colors */
  --color-brand: var(--slds-g-color-brand-base-60, #0176d3);
  --color-brand-dark: var(--slds-g-color-brand-base-70, #0070d2);

  /* Success Colors */
  --color-success: var(--slds-g-color-success-base-60, #4bca81);
  --color-success-dark: var(--slds-g-color-success-base-70, #2e844a);

  /* Error Colors */
  --color-error: var(--slds-g-color-error-base-60, #ea001e);
  --color-error-dark: var(--slds-g-color-error-base-70, #c23934);

  /* Warning Colors */
  --color-warning: var(--slds-g-color-warning-base-60, #ff9900);
  --color-warning-light: var(--slds-g-color-warning-base-50, #ffb75d);

  /* Neutral Colors */
  --color-neutral-100: var(--slds-g-color-neutral-base-100, #ffffff);
  --color-neutral-95: var(--slds-g-color-neutral-base-95, #f3f3f3);
  --color-neutral-90: var(--slds-g-color-neutral-base-90, #ecebea);

  /* Spacing */
  --spacing-small: var(--slds-g-spacing-2, 0.5rem);
  --spacing-medium: var(--slds-g-spacing-4, 0.75rem);
  --spacing-large: var(--slds-g-spacing-6, 1rem);
}
```

---

#### 6. Replace Critical Color Usage

**File:** [successionContactCadence.css](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.css)

**Find and Replace:**

```css
/* SUCCESS STATES */
/* Before */
background: linear-gradient(to bottom, #4bca81 0%, #3ba755 50%, #2e844a 100%);
/* After */
background: linear-gradient(to bottom, var(--color-success) 0%, #3ba755 50%, var(--color-success-dark) 100%);

/* Before */
border-color: #4bca81;
/* After */
border-color: var(--color-success);

/* ERROR STATES */
/* Before */
border-color: #ea001e;
/* After */
border-color: var(--color-error);

/* Before */
background: #ea001e;
/* After */
background: var(--color-error);

/* WARNING STATES */
/* Before */
border-color: #ff9900;
/* After */
border-color: var(--color-warning);

/* BRAND/CURRENT STATES */
/* Before */
border-color: #0176d3;
/* After */
border-color: var(--color-brand);

/* Before */
background: #0176d3;
/* After */
background: var(--color-brand);
```

**Impact:** Component works in dark mode, high contrast mode, and respects org theming

---

### Phase 1C: Error Pattern Fixes (All Components) (30 min)

#### 7. successionPublicForm Error Pattern

**File:** [successionPublicForm.html](../force-app/main/default/lwc/successionPublicForm/successionPublicForm.html)

**Before:**
```html
<div class="slds-notify slds-notify_alert slds-alert_error" role="alert">
  <span class="slds-assistive-text">Error</span>
  <h2>{errorMessage}</h2>
</div>
```

**After:**
```html
<div class="slds-scoped-notification slds-theme_error" role="alert">
  <div class="slds-media">
    <div class="slds-media__figure">
      <lightning-icon icon-name="utility:error"
                      variant="error"
                      size="small"
                      alternative-text="Error">
      </lightning-icon>
    </div>
    <div class="slds-media__body">
      <p>{errorMessage}</p>
    </div>
  </div>
</div>
```

---

#### 8. Remove Global SLDS Class Overrides

**File:** [successionPublicForm.css](../force-app/main/default/lwc/successionPublicForm/successionPublicForm.css)

**Before:**
```css
.slds-text-body_regular {
  color: #333333;
  line-height: 1.6;
}

.slds-text-heading_small {
  color: #333333;
  font-weight: 600;
}
```

**After:**
```css
/* Use component-scoped classes instead */
.succession-public-form .form-text {
  color: var(--slds-g-color-neutral-base-10, #181818);
  line-height: 1.6;
}

.succession-public-form .form-heading {
  color: var(--slds-g-color-neutral-base-10, #181818);
  font-weight: 600;
}
```

**Update HTML to use new classes:**
```html
<p class="form-text">...</p>
<h3 class="form-heading">...</h3>
```

---

## Testing After Phase 1

### Manual Testing Checklist

- [ ] **Reduced Motion:** Turn on "Reduce Motion" in OS settings, verify animations are disabled
- [ ] **Keyboard Navigation:** Tab through all components, verify focus indicators are visible
- [ ] **Screen Reader:** Use NVDA/JAWS to verify error announcements and success confirmations
- [ ] **Theme Switching:** Test in Light, Dark, and High Contrast modes (if available)
- [ ] **Responsive:** Test at 320px, 768px, 1024px widths

### Automated Testing

```bash
# Install axe DevTools or run Lighthouse
npm install --save-dev @axe-core/cli
npx axe https://your-org.lightning.force.com/lightning/n/Succession_Form
```

---

## Phase 2: Medium Priority (Next Session)

### 9. caseHierarchyViewer Token Fixes

**File:** [caseHierarchyViewer.css](../force-app/main/default/lwc/caseHierarchyViewer/caseHierarchyViewer.css)

**Replace non-standard spacing tokens:**
```css
/* Before */
margin-left: var(--slds-g-varSpacingMedium);

/* After - Use standard spacing scale */
margin-left: var(--slds-g-spacing-4, 0.75rem);
```

**Fix background token usage:**
```css
/* Before */
background: var(--slds-g-color-neutral-inverse-100);

/* After */
background: var(--slds-g-color-neutral-base-100, #ffffff);
```

---

### 10. createSuccessionCase Button Variants

**File:** [createSuccessionCase.html](../force-app/main/default/lwc/createSuccessionCase/createSuccessionCase.html)

**Use proper button variants:**
```html
<!-- Keep primary action as brand -->
<lightning-button variant="brand" label="Create Case" onclick={handleSubmit}>
</lightning-button>

<!-- Secondary actions as neutral -->
<lightning-button variant="neutral" label="Cancel" onclick={handleCancel}>
</lightning-button>
```

**Remove custom button styling from CSS - let SLDS handle it**

---

### 11. recordPathwaySelection Button Hierarchy

**File:** [recordPathwaySelection.html](../force-app/main/default/lwc/recordPathwaySelection/recordPathwaySelection.html)

**Before (all brand):**
```html
<lightning-button variant="brand" label="Final Grant" ...>
<lightning-button variant="brand" label="New DAF Account" ...>
<lightning-button variant="brand" label="Disclaim Assets" ...>
```

**After (visual hierarchy):**
```html
<!-- Most common pathway -->
<lightning-button variant="brand" label="Final Grant" ...>

<!-- Alternative pathways -->
<lightning-button variant="neutral" label="New DAF Account" ...>
<lightning-button variant="neutral" label="Disclaim Assets" ...>
```

---

## Phase 3: Polish & Optimization (Future)

- [ ] Replace custom shadows with SLDS elevation tokens
- [ ] Add `slds-truncate` with `title` for long text
- [ ] Optimize CSS by removing redundant rules
- [ ] Add component-level documentation
- [ ] Create Storybook stories for visual regression testing

---

## Success Metrics

**After Phase 1 Completion:**
- ✅ 0 critical accessibility violations (axe DevTools)
- ✅ WCAG AA color contrast compliance
- ✅ Keyboard navigation works in all components
- ✅ Animations respect user preferences
- ✅ Error patterns follow SLDS standards

**After Phase 2 Completion:**
- ✅ 80%+ colors use SLDS tokens
- ✅ Components work in dark/HC themes
- ✅ No SLDS utility class overrides
- ✅ Proper button variant hierarchy

---

## Files to Modify (Summary)

### Phase 1A & 1B (Immediate)
1. `successionContactCadence.css` - Tokens, animations, focus
2. `recordPathwaySelection.html` - Error pattern, aria-live
3. `successionPublicForm.html` - Error pattern
4. `successionPublicForm.css` - Remove global overrides

### Phase 2 (Next Session)
5. `caseHierarchyViewer.css` - Fix tokens
6. `createSuccessionCase.html` - Button variants
7. `recordPathwaySelection.html` - Button hierarchy

---

## Rollback Plan

If changes cause visual regressions:

1. **Git:** All changes in feature branch for easy rollback
2. **Testing:** Preview changes in sandbox before deploying
3. **Backup:** Keep original CSS files in `docs/backup/` folder
4. **Incremental:** One component at a time, test before moving to next

---

## Next Steps

1. ✅ Document created
2. [ ] Get approval for Phase 1 changes
3. [ ] Create feature branch: `feature/lwc-accessibility-improvements`
4. [ ] Implement Phase 1A (accessibility fixes)
5. [ ] Test in sandbox
6. [ ] Implement Phase 1B (token migration)
7. [ ] Deploy and validate
8. [ ] Update progress in LWC_VISUAL_IMPROVEMENTS.md
