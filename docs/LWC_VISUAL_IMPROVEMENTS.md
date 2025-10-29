# LWC Visual & Accessibility Improvements

**Status:** Phase 2 - UI Polish & Accessibility Enhancements
**Priority:** Medium (Visual/UX improvements, not functional blockers)
**Last Updated:** October 29, 2025

## Overview

This document tracks visual design, accessibility, and SLDS compliance improvements identified during a comprehensive LWC audit. All 5 LWC components are functionally correct but have opportunities for visual polish, theme compatibility, and accessibility enhancements.

## Priority Levels

- 🔴 **P0 - Critical:** Accessibility violations, WCAG compliance issues
- 🟡 **P1 - High:** SLDS token usage, theme compatibility
- 🟢 **P2 - Medium:** Visual polish, animation improvements
- ⚪ **P3 - Low:** Code cleanup, optimization

---

## Component-Specific Improvements

### 1. successionContactCadence (Most Custom Styling)

**Current Issues:**
- Heavy use of hardcoded hex colors and gradients
- Multiple animations without `prefers-reduced-motion` support
- Custom CSS conflicting with SLDS utilities
- No visible focus states for interactive elements

**Priority Improvements:**

#### 🔴 P0 - Accessibility
- [ ] Add visible focus indicators for `.toggle-button-left`, `.toggle-button-right`
- [ ] Wrap animations in `@media (prefers-reduced-motion: no-preference)`
- [ ] Provide static fallback visuals for users who prefer reduced motion
- [ ] Ensure keyboard navigation works for all interactive elements

#### 🟡 P1 - SLDS Tokens
- [ ] Replace hardcoded colors with SLDS tokens:
  ```css
  /* Before */
  background: #0176d3;
  border-color: #ea001e;
  color: #ff9900;

  /* After */
  background: var(--slds-g-color-brand-base-60);
  border-color: var(--slds-g-color-error-base-60);
  color: var(--slds-g-color-warning-base-60);
  ```
- [ ] Replace gradient backgrounds with token-based alternatives
- [ ] Use `var(--slds-g-color-success-base-60)` for success states
- [ ] Use `var(--slds-g-color-neutral-base-100)` for neutral surfaces

#### 🟢 P2 - Visual Polish
- [ ] Simplify custom shadows or use token-based shadows
- [ ] Add `slds-truncate` with `title` attributes for long text
- [ ] Ensure no horizontal scrolling at 320px width
- [ ] Validate grid column behavior at all breakpoints

#### ⚪ P3 - Code Cleanup
- [ ] Remove ineffective `lightning-textarea { width: 100% }` (shadow DOM isolated)
- [ ] Consolidate repeated spacing values into CSS custom properties

**Files to Modify:**
- [successionContactCadence.css](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.css)
- [successionContactCadence.html](../force-app/main/default/lwc/successionContactCadence/successionContactCadence.html) (for ARIA attributes)

---

### 2. successionPublicForm

**Current Issues:**
- Global SLDS class overrides (`.slds-text-body_regular`, `.slds-text-heading_small`)
- Gradient headers may have contrast issues
- Error alert pattern uses non-standard class combo

**Priority Improvements:**

#### 🔴 P0 - Accessibility
- [ ] Verify white text on gradient header meets WCAG AA contrast (4.5:1)
- [ ] Ensure `rgba(255,255,255,0.9)` on backgrounds meets contrast requirements

#### 🟡 P1 - SLDS Compliance
- [ ] Replace error alert markup with `slds-scoped-notification slds-theme_error`
  ```html
  <!-- Before -->
  <div class="slds-notify slds-notify_alert slds-alert_error" role="alert">

  <!-- After -->
  <div class="slds-scoped-notification slds-theme_error" role="alert">
    <div class="slds-media">
      <div class="slds-media__figure">
        <lightning-icon icon-name="utility:error" ...></lightning-icon>
      </div>
      <div class="slds-media__body">
        <p>{errorMessage}</p>
      </div>
    </div>
  </div>
  ```
- [ ] Stop overriding `.slds-text-*` classes; apply custom colors on component-scoped wrappers
- [ ] Use component-specific classes instead of global SLDS overrides

#### 🟢 P2 - Visual Polish
- [ ] Consider using SLDS default font stack instead of forcing "Salesforce Sans"
- [ ] Add padding/spacing using SLDS utilities in markup vs CSS

**Files to Modify:**
- [successionPublicForm.css](../force-app/main/default/lwc/successionPublicForm/successionPublicForm.css)
- [successionPublicForm.html](../force-app/main/default/lwc/successionPublicForm/successionPublicForm.html)

---

### 3. caseHierarchyViewer

**Current Issues:**
- Non-standard SLDS token names (`--slds-g-varSpacingMedium`)
- Inverse tokens used incorrectly as backgrounds
- Hardcoded shadows on hover

**Priority Improvements:**

#### 🔴 P0 - Accessibility
- [ ] Ensure expand/collapse uses `<button>` with `aria-expanded` and `aria-controls`
- [ ] Verify keyboard navigation across hierarchical nodes
- [ ] Add `aria-labelledby` for expandable sections

#### 🟡 P1 - SLDS Tokens
- [ ] Replace non-standard spacing tokens:
  ```css
  /* Before */
  margin-left: var(--slds-g-varSpacingMedium);

  /* After - Use SLDS utilities in HTML instead */
  /* In HTML: class="slds-var-m-left_medium" */
  /* Or use standard tokens: */
  margin-left: var(--slds-g-spacing-4);
  ```
- [ ] Fix background token usage:
  ```css
  /* Before */
  background: var(--slds-g-color-neutral-inverse-100);

  /* After */
  background: var(--slds-g-color-neutral-base-100);
  ```
- [ ] Use SLDS utilities (`slds-box`, `slds-theme_default`) instead of custom backgrounds

#### 🟢 P2 - Visual Polish
- [ ] Remove custom hover shadows or use token-based alternatives
- [ ] Add `slds-scrollable_y` for tall lists with max-height
- [ ] Use SLDS utilities in markup for spacing instead of CSS margins

**Files to Modify:**
- [caseHierarchyViewer.css](../force-app/main/default/lwc/caseHierarchyViewer/caseHierarchyViewer.css)
- [caseHierarchyViewer.html](../force-app/main/default/lwc/caseHierarchyViewer/caseHierarchyViewer.html)

---

### 4. createSuccessionCase

**Current Issues:**
- Hardcoded button colors that may not apply due to shadow DOM
- Direct overrides of SLDS utility classes
- Custom success/error alert colors

**Priority Improvements:**

#### 🟡 P1 - SLDS Compliance
- [ ] Use `lightning-button` variants instead of custom colors:
  ```html
  <!-- Before -->
  <lightning-button class="create-succession-case-button">

  <!-- After -->
  <lightning-button variant="brand">  <!-- or variant="success" -->
  ```
- [ ] Remove utility class overrides; use component-scoped wrappers:
  ```css
  /* Before */
  .slds-var-p-around_medium { padding: 0.5rem; }

  /* After */
  .create-case-container .custom-padding { padding: 0.5rem; }
  ```
- [ ] Use `slds-theme_success` and `slds-theme_error` for alerts

#### 🟢 P2 - Visual Polish
- [ ] Verify text contrast on success/error backgrounds (WCAG AA)
- [ ] Add responsive padding on component wrapper, not utility classes

**Files to Modify:**
- [createSuccessionCase.css](../force-app/main/default/lwc/createSuccessionCase/createSuccessionCase.css)
- [createSuccessionCase.html](../force-app/main/default/lwc/createSuccessionCase/createSuccessionCase.html)

---

### 5. recordPathwaySelection

**Current Issues:**
- Error alert uses non-standard class combo
- All three pathway buttons use `variant="brand"` (priority ambiguity)
- Success confirmation may not announce to screen readers

**Priority Improvements:**

#### 🔴 P0 - Accessibility
- [ ] Add `aria-live="polite"` to success confirmation container:
  ```html
  <div class="slds-box slds-theme_success" aria-live="polite">
  ```
- [ ] Ensure error region has proper ARIA attributes and assistive text

#### 🟡 P1 - SLDS Compliance
- [ ] Fix error alert pattern to use `slds-scoped-notification slds-theme_error`
- [ ] Adjust button variants for visual hierarchy:
  ```html
  <!-- Keep most common action as brand -->
  <lightning-button variant="brand" label="Final Grant">
  <!-- Use neutral for alternatives -->
  <lightning-button variant="neutral" label="New DAF Account">
  <lightning-button variant="neutral" label="Disclaim Assets">
  ```

#### 🟢 P2 - Visual Polish
- [ ] Consider using `lightning-radio-group` with `lightning-tile` for pathway selection
- [ ] Ensure long labels wrap with sensible line-height
- [ ] Add min-height to prevent layout shifts during loading

**Files to Modify:**
- [recordPathwaySelection.html](../force-app/main/default/lwc/recordPathwaySelection/recordPathwaySelection.html)

---

## Global Improvements (All Components)

### 🔴 P0 - Critical Accessibility

**Focus Management:**
- [ ] Ensure all interactive elements have visible focus indicators
- [ ] Never remove outlines; add `:focus-visible` enhancements if needed
- [ ] Test keyboard navigation flow in each component

**Screen Reader Support:**
- [ ] Add `aria-live` regions for dynamic content updates
- [ ] Ensure `role="alert"` on error messages
- [ ] Include assistive text for icons (`<span class="slds-assistive-text">`)

**Motion Sensitivity:**
```css
/* Wrap ALL animations in this media query */
@media (prefers-reduced-motion: no-preference) {
  @keyframes pulse-warning { ... }
  @keyframes shimmer { ... }
  .animated-element {
    animation: pulse-warning 2s infinite;
  }
}

/* Provide static fallback */
@media (prefers-reduced-motion: reduce) {
  .animated-element {
    /* Static visual indicator instead */
    border: 2px solid var(--slds-g-color-warning-base-60);
  }
}
```

### 🟡 P1 - SLDS Token Migration

**Color Replacement Map:**
```css
/* Brand Colors */
#0176d3 → var(--slds-g-color-brand-base-60)
#0070d2 → var(--slds-g-color-brand-base-70)

/* Error/Danger */
#ea001e → var(--slds-g-color-error-base-60)
#c23934 → var(--slds-g-color-error-base-70)

/* Warning */
#ff9900 → var(--slds-g-color-warning-base-60)
#ffb75d → var(--slds-g-color-warning-base-50)

/* Success */
#4bca81 → var(--slds-g-color-success-base-60)
#2e844a → var(--slds-g-color-success-base-70)

/* Neutral Surfaces */
#f3f3f3 → var(--slds-g-color-neutral-base-95)
#ffffff → var(--slds-g-color-neutral-base-100)
```

**Spacing Tokens:**
```css
/* Use SLDS utilities in HTML instead of CSS */
margin: 0.75rem → class="slds-var-m-around_medium"
padding: 1rem → class="slds-var-p-around_large"

/* Or use standard spacing tokens */
var(--slds-g-spacing-2)  /* 0.5rem / 8px */
var(--slds-g-spacing-4)  /* 0.75rem / 12px */
var(--slds-g-spacing-6)  /* 1rem / 16px */
```

### 🟢 P2 - Code Quality

**Component-Scoped CSS:**
```css
/* Bad - Overrides global SLDS */
.slds-var-m-top_medium { margin-top: 2rem !important; }

/* Good - Component-scoped */
.succession-contact-cadence .custom-spacing { margin-top: 2rem; }
```

**Shadow DOM Awareness:**
```css
/* Bad - Won't apply due to shadow DOM */
lightning-textarea { width: 100%; }

/* Good - Style wrapper or use component attributes */
.textarea-container { width: 100%; }
```

---

## Testing Checklist

Before marking improvements complete, verify:

### Visual Testing
- [ ] Component renders correctly in Light, Dark, and High Contrast modes
- [ ] Colors meet WCAG AA contrast ratios (4.5:1 for text, 3:1 for UI components)
- [ ] Responsive layout works at 320px, 768px, and 1024px widths
- [ ] No horizontal scrolling on small screens

### Accessibility Testing
- [ ] Keyboard navigation works (Tab, Shift+Tab, Enter, Escape)
- [ ] Screen reader announces all state changes (NVDA/JAWS)
- [ ] Focus indicators are visible on all interactive elements
- [ ] Animations respect `prefers-reduced-motion` setting

### Functional Testing
- [ ] All user interactions still work correctly
- [ ] Loading states display properly
- [ ] Error states are clear and actionable
- [ ] Success confirmations are noticeable

---

## Implementation Strategy

### Phase 1: Critical Fixes (Week 1)
Focus on P0 accessibility issues that affect usability:
1. Add focus indicators and keyboard navigation
2. Implement `prefers-reduced-motion` support
3. Fix ARIA attributes and screen reader announcements
4. Verify WCAG color contrast

### Phase 2: SLDS Token Migration (Week 2)
Migrate hardcoded colors to SLDS tokens for theme compatibility:
1. Replace all hex colors with SLDS design tokens
2. Fix error notification patterns
3. Update spacing to use SLDS utilities
4. Remove SLDS class overrides

### Phase 3: Visual Polish (Week 3)
UI refinements and code cleanup:
1. Improve button variant hierarchy
2. Add text truncation and overflow handling
3. Optimize animations and transitions
4. Clean up ineffective shadow DOM selectors

### Phase 4: Testing & Validation (Week 4)
Comprehensive testing across themes and devices:
1. Visual regression testing
2. Accessibility audit with automated tools (axe DevTools)
3. Manual keyboard and screen reader testing
4. Responsive testing at standard breakpoints

---

## Resources

### SLDS Documentation
- [Design Tokens](https://www.lightningdesignsystem.com/design-tokens/)
- [Accessibility Guidelines](https://www.lightningdesignsystem.com/accessibility/overview/)
- [Component Blueprints](https://www.lightningdesignsystem.com/components/overview/)

### Accessibility Standards
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### Testing Tools
- [axe DevTools](https://www.deque.com/axe/devtools/) - Automated accessibility testing
- [WAVE Browser Extension](https://wave.webaim.org/extension/) - Visual accessibility feedback
- [Lighthouse](https://developers.google.com/web/tools/lighthouse) - Performance and accessibility audits

---

## Progress Tracking

| Component                  | P0 Accessibility | P1 SLDS Tokens | P2 Polish | Status      |
|----------------------------|------------------|----------------|-----------|-------------|
| successionContactCadence   | 0/4              | 0/5            | 0/4       | Not Started |
| successionPublicForm       | 0/2              | 0/3            | 0/2       | Not Started |
| caseHierarchyViewer        | 0/3              | 0/4            | 0/3       | Not Started |
| createSuccessionCase       | 0/0              | 0/3            | 0/2       | Not Started |
| recordPathwaySelection     | 0/2              | 0/2            | 0/3       | Not Started |

**Overall Progress:** 0/51 tasks completed (0%)

---

## Notes

- These are **visual and UX polish improvements**, not functional bugs
- All components work correctly in the demo environment
- Prioritize based on upcoming demo requirements and available time
- Consider addressing during maintenance windows to avoid disrupting working features
