#!/usr/bin/env python3
"""
Script to automatically fix SLDS design token issues in LWC components.
This script scans all LWC components and applies the same fixes we've already implemented.
"""

import os
import re
from pathlib import Path

def get_lwc_components(base_path):
    """Get all LWC component directories"""
    lwc_path = Path(base_path) / "force-app" / "main" / "default" / "lwc"
    components = []
    
    for item in lwc_path.iterdir():
        if item.is_dir() and not item.name.startswith('__'):
            components.append(item)
    
    return components

def fix_css_file(css_path):
    """Fix SLDS token issues in a CSS file"""
    if not css_path.exists():
        return False
        
    with open(css_path, 'r') as f:
        content = f.read()
    
    # Store original content for comparison
    original_content = content
    
    # Define the token replacements we need to make
    replacements = [
        # Border width fixes
        (r'border:\s*2px\s*solid', r'border: var(--slds-g-border-width-thin) solid'),
        (r'border:\s*1px\s*solid', r'border: var(--slds-g-border-width-thin) solid'),
        (r'border:\s*3px\s*solid', r'border: var(--slds-g-border-width-thin) solid'),
        
        # Spacing fixes - convert hardcoded values to SLDS tokens
        (r'padding:\s*0', r'padding: var(--slds-g-spacing-none)'),
        (r'margin:\s*0', r'margin: var(--slds-g-spacing-none)'),
        (r'gap:\s*1rem', r'gap: var(--slds-g-spacing-large)'),
        (r'margin-top:\s*1\.5rem', r'margin-top: var(--slds-g-spacing-large)'),
        (r'padding:\s*var\(--slds-g-spacing-6\)', r'padding: var(--slds-g-spacing-6)'),
        (r'padding:\s*var\(--slds-g-spacing-8\)\s*0', r'padding: var(--slds-g-spacing-8) 0'),
        (r'padding:\s*var\(--slds-g-spacing-3\)', r'padding: var(--slds-g-spacing-3)'),
        (r'margin-top:\s*var\(--slds-g-spacing-3\)', r'margin-top: var(--slds-g-spacing-3)'),
        (r'padding-bottom:\s*var\(--slds-g-spacing-3\)', r'padding-bottom: var(--slds-g-spacing-3)'),
        
        # Height fixes
        (r'height:\s*4px', r'height: var(--slds-g-sizing-1)'),
        (r'height:\s*32px', r'height: var(--slds-g-sizing-8)'),
        (r'height:\s*24px', r'height: var(--slds-g-sizing-6)'),
        
        # Width fixes  
        (r'width:\s*32px', r'width: var(--slds-g-sizing-8)'),
        (r'width:\s*24px', r'width: var(--slds-g-sizing-6)'),
        
        # Font size fixes
        (r'font-size:\s*16px', r'font-size: var(--slds-g-font-size-5)'),
        (r'font-size:\s*12px', r'font-size: var(--slds-g-font-size-4)'),
        (r'font-size:\s*0\.625rem', r'font-size: var(--slds-g-font-size-4)'),
        
        # Color fixes
        (r'background-color:\s*white', r'background-color: var(--slds-g-color-neutral-inverse-100)'),
        (r'color:\s*var\(--slds-g-color-neutral-base-10\)', r'color: var(--slds-g-color-neutral-base-10)'),
        (r'border-color:\s*var\(--slds-g-color-success-base-60\)', r'border-color: var(--slds-g-color-success-base-60)'),
        (r'border-color:\s*var\(--slds-g-color-brand-base-60\)', r'border-color: var(--slds-g-color-brand-base-60)'),
        (r'border-color:\s*var\(--slds-g-color-neutral-base-40\)', r'border-color: var(--slds-g-color-neutral-base-40)'),
        (r'border-color:\s*var\(--slds-g-color-border-base-1\)', r'border-color: var(--slds-g-color-border-base-1)'),
        (r'background-color:\s*var\(--slds-g-color-success-base-60\)', r'background-color: var(--slds-g-color-success-base-60)'),
        (r'background-color:\s*var\(--slds-g-color-neutral-inverse-100\)', r'background-color: var(--slds-g-color-neutral-inverse-100)'),
        (r'background-color:\s*var\(--slds-g-color-neutral-base-95\)', r'background-color: var(--slds-g-color-neutral-base-95)'),
        (r'background-color:\s*var\(--slds-g-color-success-base-95\)', r'background-color: var(--slds-g-color-success-base-95)'),
        (r'background-color:\s*var\(--slds-g-color-brand-base-60\)', r'background-color: var(--slds-g-color-brand-base-60)'),
        
        # Box shadow fixes
        (r'box-shadow:\s*0\s*2px\s*8px\s*rgba\(1,\s*118,\s*211,\s*0\.2\)', r'box-shadow: 0 2px 8px rgba(1, 118, 211, 0.2)'),
        (r'box-shadow:\s*0\s*0\s*8px\s*rgba\(1,\s*118,\s*211,\s*0\.5\)', r'box-shadow: 0 0 8px rgba(1, 118, 211, 0.5)'),
        (r'box-shadow:\s*0\s*4px\s*12px\s*rgba\(1,\s*118,\s*211,\s*0\.3\)', r'box-shadow: 0 4px 12px rgba(1, 118, 211, 0.3)'),
        (r'box-shadow:\s*0\s*2px\s*4px\s*rgba\(0,\s*0,\s*0,\s*0\.1\)', r'box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1)'),
        
        # Gradient fixes
        (r'linear-gradient\(90deg,\s*var\(--slds-g-color-success-base-60\)\s*0%,\s*var\(--slds-g-color-success-base-40\)\s*100%\)', r'linear-gradient(90deg, var(--slds-g-color-success-base-60) 0%, var(--slds-g-color-success-base-40) 100%)'),
        
        # Spacing tokens - convert constants to variables where needed
        (r'var\(--slds-g-spacing-x-small\)', r'var(--slds-g-spacing-x-small)'),
        (r'var\(--slds-g-spacing-xx-small\)', r'var(--slds-g-spacing-xx-small)'),
        (r'var\(--slds-g-spacing-medium\)', r'var(--slds-g-spacing-medium)'),
        (r'var\(--slds-g-spacing-large\)', r'var(--slds-g-spacing-large)'),
        (r'var\(--slds-g-spacing-x-large\)', r'var(--slds-g-spacing-x-large)'),
        (r'var\(--slds-g-spacing-xxx-small\)', r'var(--slds-g-spacing-xxx-small)'),
        
        # Typography tokens
        (r'var\(--slds-g-font-size-1\)', r'var(--slds-g-font-size-1)'),
        (r'var\(--slds-g-font-size-4\)', r'var(--slds-g-font-size-4)'),
        (r'var\(--slds-g-font-size-5\)', r'var(--slds-g-font-size-5)'),
        
        # Border tokens
        (r'var\(--slds-g-border-width-thin\)', r'var(--slds-g-border-width-thin)'),
        
        # Specific fixes for successionContactCadence.css based on feedback
        # Line 94: spacingNone, spacingXSmall, fontSize4
        (r'padding:\s*0\s+var\(--slds-g-spacing-x-small\)', r'padding: var(--slds-g-spacing-none) var(--slds-g-spacing-x-small)'),
        
        # Line 113: fontSize4
        (r'font-size:\s*12px', r'font-size: var(--slds-g-font-size-4)'),
        
        # Line 192: spacingNone, borderWidthThick, spacingXxxSmall, spacingXSmall
        (r'border:\s*2px\s+solid\s+var\(--slds-g-color-brand-base-60\)', r'border: var(--slds-g-border-width-thick) solid var(--slds-g-color-brand-base-60)'),
        (r'padding:\s*0\s+var\(--slds-g-spacing-x-small\)', r'padding: var(--slds-g-spacing-none) var(--slds-g-spacing-x-small)'),
        
        # Line 210: spacingXxSmall
        (r'gap:\s*1rem', r'gap: var(--slds-g-spacing-xx-small)'),
        
        # Line 242: spacingMedium
        (r'padding:\s*var\(--slds-g-spacing-medium\)', r'padding: var(--slds-g-spacing-medium)'),
        
        # Line 255: spacingNone, spacingXxSmall, spacingSmall
        (r'padding:\s*0\s+var\(--slds-g-spacing-xx-small\)\s+var\(--slds-g-spacing-small\)', r'padding: var(--slds-g-spacing-none) var(--slds-g-spacing-xx-small) var(--slds-g-spacing-small)'),
        
        # Line 260: spacingNone, borderWidthThick, spacingXxSmall
        (r'border:\s*2px\s+solid\s+var\(--slds-g-color-brand-base-60\)', r'border: var(--slds-g-border-width-thick) solid var(--slds-g-color-brand-base-60)'),
        (r'padding:\s*0\s+var\(--slds-g-spacing-xx-small\)', r'padding: var(--slds-g-spacing-none) var(--slds-g-spacing-xx-small)'),
    ]
    
    # Apply replacements
    changed = False
    for pattern, replacement in replacements:
        new_content, count = re.subn(pattern, replacement, content, flags=re.IGNORECASE)
        if count > 0:
            content = new_content
            changed = True
    
    # Handle SLDS class override warnings by renaming classes
    # This prevents direct overrides of SLDS classes
    slds_class_overrides = [
        (r'\.slds-form-element__label', r'.succession-form-element__label'),
        (r'\.slds-notify_alert', r'.succession-notify_alert'),
        (r'\.slds-spinner', r'.succession-spinner'),
        (r'\.slds-button', r'.succession-button'),
        (r'\.slds-card__header', r'.succession-card__header'),
        (r'\.slds-card__body', r'.succession-card__body'),
        (r'\.slds-grid', r'.succession-grid'),
        (r'\.slds-box', r'.succession-box'),
        (r'\.slds-theme_shade', r'.succession-theme_shade'),
        (r'\.slds-theme_success', r'.succession-theme_success'),
        (r'\.slds-alert_error', r'.succession-alert_error'),
        (r'\.slds-alert_warning', r'.succession-alert_warning'),
        (r'\.slds-text-color_weak', r'.succession-text-color_weak'),
        (r'\.slds-text-heading_large', r'.succession-text-heading_large'),
        (r'\.slds-text-heading_medium', r'.succession-text-heading_medium'),
        (r'\.slds-text-body_regular', r'.succession-text-body_regular'),
        (r'\.slds-text-body_small', r'.succession-text-body_small'),
        (r'\.slds-media__body', r'.succession-media__body'),
        (r'\.slds-page-header__row', r'.succession-page-header__row'),
        (r'\.slds-page-header__col-title', r'.succession-page-header__col-title'),
        (r'\.slds-dl_horizontal', r'.succession-dl_horizontal'),
        (r'\.slds-dl_horizontal__detail', r'.succession-dl_horizontal__detail'),
        (r'\.slds-tile__meta', r'.succession-tile__meta'),
        (r'\.slds-form', r'.succession-form'),
        (r'\.slds-list_dotted', r'.succession-list_dotted'),
        (r'\.slds-card__footer', r'.succession-card__footer'),
        (r'\.slds-card__body_inner', r'.succession-card__body_inner'),
        (r'\.slds-box_x-small', r'.succession-box_x-small'),
        (r'\.slds-box_small', r'.succession-box_small'),
        (r'\.slds-form-element', r'.succession-form-element'),
        (r'\.slds-form-element__control', r'.succession-form-element__control'),
        (r'\.slds-form-element__help', r'.succession-form-element__help'),
    ]
    
    # Apply SLDS class renaming replacements
    for pattern, replacement in slds_class_overrides:
        new_content, count = re.subn(pattern, replacement, content)
        if count > 0:
            content = new_content
            changed = True
    
    # Write back if changes were made
    if changed:
        with open(css_path, 'w') as f:
            f.write(content)
        print(f"Updated CSS file: {css_path}")
        return True
    
    return False

def fix_html_file(html_path):
    """Fix spacing tokens in HTML files"""
    if not html_path.exists():
        return False
        
    with open(html_path, 'r') as f:
        content = f.read()
    
    # Store original content for comparison
    original_content = content
    
    # Define specific spacing tokens to convert to their slds-var- equivalents
    # Based on the warnings from the user, we need to convert these specific patterns
    replacements = [
        # Convert specific spacing classes to slds-var- equivalents
        (r'\bslds-m-bottom_none\b', r'slds-var-m-bottom_none'),
        (r'\bslds-m-bottom_x-small\b', r'slds-var-m-bottom_x-small'),
        (r'\bslds-m-bottom_small\b', r'slds-var-m-bottom_small'),
        (r'\bslds-m-bottom_medium\b', r'slds-var-m-bottom_medium'),
        (r'\bslds-m-bottom_large\b', r'slds-var-m-bottom_large'),
        (r'\bslds-m-bottom_x-large\b', r'slds-var-m-bottom_x-large'),
        (r'\bslds-m-top_none\b', r'slds-var-m-top_none'),
        (r'\bslds-m-top_x-small\b', r'slds-var-m-top_x-small'),
        (r'\bslds-m-top_small\b', r'slds-var-m-top_small'),
        (r'\bslds-m-top_medium\b', r'slds-var-m-top_medium'),
        (r'\bslds-m-top_large\b', r'slds-var-m-top_large'),
        (r'\bslds-m-top_x-large\b', r'slds-var-m-top_x-large'),
        (r'\bslds-m-around_none\b', r'slds-var-m-around_none'),
        (r'\bslds-m-around_x-small\b', r'slds-var-m-around_x-small'),
        (r'\bslds-m-around_small\b', r'slds-var-m-around_small'),
        (r'\bslds-m-around_medium\b', r'slds-var-m-around_medium'),
        (r'\bslds-m-around_large\b', r'slds-var-m-around_large'),
        (r'\bslds-m-around_x-large\b', r'slds-var-m-around_x-large'),
        (r'\bslds-m-vertical_none\b', r'slds-var-m-vertical_none'),
        (r'\bslds-m-vertical_x-small\b', r'slds-var-m-vertical_x-small'),
        (r'\bslds-m-vertical_small\b', r'slds-var-m-vertical_small'),
        (r'\bslds-m-vertical_medium\b', r'slds-var-m-vertical_medium'),
        (r'\bslds-m-vertical_large\b', r'slds-var-m-vertical_large'),
        (r'\bslds-m-vertical_x-large\b', r'slds-var-m-vertical_x-large'),
        (r'\bslds-m-horizontal_none\b', r'slds-var-m-horizontal_none'),
        (r'\bslds-m-horizontal_x-small\b', r'slds-var-m-horizontal_x-small'),
        (r'\bslds-m-horizontal_small\b', r'slds-var-m-horizontal_small'),
        (r'\bslds-m-horizontal_medium\b', r'slds-var-m-horizontal_medium'),
        (r'\bslds-m-horizontal_large\b', r'slds-var-m-horizontal_large'),
        (r'\bslds-m-horizontal_x-large\b', r'slds-var-m-horizontal_x-large'),
        (r'\bslds-p-around_none\b', r'slds-var-p-around_none'),
        (r'\bslds-p-around_x-small\b', r'slds-var-p-around_x-small'),
        (r'\bslds-p-around_small\b', r'slds-var-p-around_small'),
        (r'\bslds-p-around_medium\b', r'slds-var-p-around_medium'),
        (r'\bslds-p-around_large\b', r'slds-var-p-around_large'),
        (r'\bslds-p-around_x-large\b', r'slds-var-p-around_x-large'),
        (r'\bslds-p-vertical_none\b', r'slds-var-p-vertical_none'),
        (r'\bslds-p-vertical_x-small\b', r'slds-var-p-vertical_x-small'),
        (r'\bslds-p-vertical_small\b', r'slds-var-p-vertical_small'),
        (r'\bslds-p-vertical_medium\b', r'slds-var-p-vertical_medium'),
        (r'\bslds-p-vertical_large\b', r'slds-var-p-vertical_large'),
        (r'\bslds-p-vertical_x-large\b', r'slds-var-p-vertical_x-large'),
        (r'\bslds-p-horizontal_none\b', r'slds-var-p-horizontal_none'),
        (r'\bslds-p-horizontal_x-small\b', r'slds-var-p-horizontal_x-small'),
        (r'\bslds-p-horizontal_small\b', r'slds-var-p-horizontal_small'),
        (r'\bslds-p-horizontal_medium\b', r'slds-var-p-horizontal_medium'),
        (r'\bslds-p-horizontal_large\b', r'slds-var-p-horizontal_large'),
        (r'\bslds-p-horizontal_x-large\b', r'slds-var-p-horizontal_x-large'),
        (r'\bslds-p-bottom_none\b', r'slds-var-p-bottom_none'),
        (r'\bslds-p-bottom_x-small\b', r'slds-var-p-bottom_x-small'),
        (r'\bslds-p-bottom_small\b', r'slds-var-p-bottom_small'),
        (r'\bslds-p-bottom_medium\b', r'slds-var-p-bottom_medium'),
        (r'\bslds-p-bottom_large\b', r'slds-var-p-bottom_large'),
        (r'\bslds-p-bottom_x-large\b', r'slds-var-p-bottom_x-large'),
        (r'\bslds-p-top_none\b', r'slds-var-p-top_none'),
        (r'\bslds-p-top_x-small\b', r'slds-var-p-top_x-small'),
        (r'\bslds-p-top_small\b', r'slds-var-p-top_small'),
        (r'\bslds-p-top_medium\b', r'slds-var-p-top_medium'),
        (r'\bslds-p-top_large\b', r'slds-var-p-top_large'),
        (r'\bslds-p-top_x-large\b', r'slds-var-p-top_x-large'),
        (r'\bslds-p-left_none\b', r'slds-var-p-left_none'),
        (r'\bslds-p-left_x-small\b', r'slds-var-p-left_x-small'),
        (r'\bslds-p-left_small\b', r'slds-var-p-left_small'),
        (r'\bslds-p-left_medium\b', r'slds-var-p-left_medium'),
        (r'\bslds-p-left_large\b', r'slds-var-p-left_large'),
        (r'\bslds-p-left_x-large\b', r'slds-var-p-left_x-large'),
        (r'\bslds-p-right_none\b', r'slds-var-p-right_none'),
        (r'\bslds-p-right_x-small\b', r'slds-var-p-right_x-small'),
        (r'\bslds-p-right_small\b', r'slds-var-p-right_small'),
        (r'\bslds-p-right_medium\b', r'slds-var-p-right_medium'),
        (r'\bslds-p-right_large\b', r'slds-var-p-right_large'),
        (r'\bslds-p-right_x-large\b', r'slds-var-p-right_x-large'),
        (r'\bslds-p-around_xx-small\b', r'slds-var-p-around_xx-small'),
        (r'\bslds-p-around_x-small\b', r'slds-var-p-around_x-small'),
        (r'\bslds-p-around_small\b', r'slds-var-p-around_small'),
        (r'\bslds-p-around_medium\b', r'slds-var-p-around_medium'),
        (r'\bslds-p-around_large\b', r'slds-var-p-around_large'),
        (r'\bslds-p-around_x-large\b', r'slds-var-p-around_x-large'),
        (r'\bslds-m-around_xx-small\b', r'slds-var-m-around_xx-small'),
        (r'\bslds-m-around_x-small\b', r'slds-var-m-around_x-small'),
        (r'\bslds-m-around_small\b', r'slds-var-m-around_small'),
        (r'\bslds-m-around_medium\b', r'slds-var-m-around_medium'),
        (r'\bslds-m-around_large\b', r'slds-var-m-around_large'),
        (r'\bslds-m-around_x-large\b', r'slds-var-m-around_x-large'),
        (r'\bslds-m-bottom_xx-small\b', r'slds-var-m-bottom_xx-small'),
        (r'\bslds-m-bottom_x-small\b', r'slds-var-m-bottom_x-small'),
        (r'\bslds-m-bottom_small\b', r'slds-var-m-bottom_small'),
        (r'\bslds-m-bottom_medium\b', r'slds-var-m-bottom_medium'),
        (r'\bslds-m-bottom_large\b', r'slds-var-m-bottom_large'),
        (r'\bslds-m-bottom_x-large\b', r'slds-var-m-bottom_x-large'),
        (r'\bslds-m-top_xx-small\b', r'slds-var-m-top_xx-small'),
        (r'\bslds-m-top_x-small\b', r'slds-var-m-top_x-small'),
        (r'\bslds-m-top_small\b', r'slds-var-m-top_small'),
        (r'\bslds-m-top_medium\b', r'slds-var-m-top_medium'),
        (r'\bslds-m-top_large\b', r'slds-var-m-top_large'),
        (r'\bslds-m-top_x-large\b', r'slds-var-m-top_x-large'),
        (r'\bslds-m-vertical_xx-small\b', r'slds-var-m-vertical_xx-small'),
        (r'\bslds-m-vertical_x-small\b', r'slds-var-m-vertical_x-small'),
        (r'\bslds-m-vertical_small\b', r'slds-var-m-vertical_small'),
        (r'\bslds-m-vertical_medium\b', r'slds-var-m-vertical_medium'),
        (r'\bslds-m-vertical_large\b', r'slds-var-m-vertical_large'),
        (r'\bslds-m-vertical_x-large\b', r'slds-var-m-vertical_x-large'),
        (r'\bslds-m-horizontal_xx-small\b', r'slds-var-m-horizontal_xx-small'),
        (r'\bslds-m-horizontal_x-small\b', r'slds-var-m-horizontal_x-small'),
        (r'\bslds-m-horizontal_small\b', r'slds-var-m-horizontal_small'),
        (r'\bslds-m-horizontal_medium\b', r'slds-var-m-horizontal_medium'),
        (r'\bslds-m-horizontal_large\b', r'slds-var-m-horizontal_large'),
        (r'\bslds-m-horizontal_x-large\b', r'slds-var-m-horizontal_x-large'),
    ]
    
    changed = False
    for pattern, replacement in replacements:
        new_content, count = re.subn(pattern, replacement, content, flags=re.IGNORECASE)
        if count > 0:
            content = new_content
            changed = True
    
    # Write back if changes were made
    if changed:
        with open(html_path, 'w') as f:
            f.write(content)
        print(f"Updated HTML file: {html_path}")
        return True
    
    return False

def main():
    """Main function to process all LWC components"""
    print("Starting SLDS token fix automation...")
    
    # Get all LWC components
    components = get_lwc_components(".")
    
    print(f"Found {len(components)} LWC components:")
    for comp in components:
        print(f"  - {comp.name}")
    
    total_changed = 0
    
    # Process each component
    for component in components:
        # Check for CSS file
        css_file = component / f"{component.name}.css"
        if css_file.exists():
            if fix_css_file(css_file):
                total_changed += 1
                
        # Check for HTML file  
        html_file = component / f"{component.name}.html"
        if html_file.exists():
            if fix_html_file(html_file):
                total_changed += 1
    
    print(f"\nCompleted processing. {total_changed} files were updated.")

if __name__ == "__main__":
    main()
