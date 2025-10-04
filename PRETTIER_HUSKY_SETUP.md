# Prettier & Husky Setup Verification

**Status**: ✅ FULLY CONFIGURED AND WORKING

**Last Updated**: October 4, 2025

---

## Installation Summary

### Prettier Configuration

- **Version**: 3.6.2
- **Plugin - Apex**: prettier-plugin-apex@2.2.6
- **Plugin - XML**: @prettier/plugin-xml@3.4.2
- **Status**: ✅ Installed and working

### Husky Pre-commit Hooks

- **Version**: 9.1.7
- **Lint-staged**: 16.2.3
- **Status**: ✅ Installed, configured, and executable

---

## Quick Verification Checklist

Run these commands to verify everything is working:

```bash
# 1. Check npm dependencies
npm ls prettier prettier-plugin-apex @prettier/plugin-xml husky lint-staged --depth=0

# 2. Verify Prettier works
npx prettier --version

# 3. Test Prettier formatting
npm run prettier:verify

# 4. Check Husky hook is executable
test -x .husky/pre-commit && echo "✅ Hook is executable" || echo "❌ Hook needs fixing"

# 5. View hook content
cat .husky/pre-commit

# 6. Verify Git hooks path
git config core.hooksPath
```

**Expected Output**:

```
prettier@3.6.2
prettier-plugin-apex@2.2.6
@prettier/plugin-xml@3.4.2
husky@9.1.7
lint-staged@16.2.3
✅ Hook is executable
.husky/_
```

---

## What Happens on Git Commit

When you run `git commit`, Husky automatically runs:

1. **Prettier** - Formats all staged files matching:
   - `.cls`, `.trigger` (Apex)
   - `.xml`, `.cmp`, `.component`, `.page` (Metadata)
   - `.js`, `.html`, `.css` (LWC/Aura)
   - `.json`, `.yaml`, `.yml`, `.md` (Configuration/Docs)

2. **ESLint** - Lints JavaScript in `aura/` and `lwc/` directories

3. **Jest Tests** - Runs related LWC unit tests for changed components

**If any check fails**: Commit is blocked until issues are fixed.

---

## VS Code Integration

**Format on Save**: ✅ Enabled

**Settings Location**: `.vscode/settings.json`

**Manual Formatting**:

- Mac: `Shift + Option + F`
- Windows/Linux: `Shift + Alt + F`
- Or: Right-click → Format Document

---

## Command Reference

```bash
# Format all files
npm run prettier

# Check formatting without changes
npm run prettier:verify

# Run all pre-commit checks manually
npm run precommit

# Lint JavaScript
npm run lint

# Run LWC tests
npm run test:unit

# Bypass pre-commit hooks (use sparingly!)
git commit --no-verify -m "message"
```

---

## Troubleshooting

### Issue: VS Code shows "Cannot find module 'prettier'"

**Solution**:

```bash
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"
npm install
# Reload VS Code: Cmd+Shift+P → "Developer: Reload Window"
```

### Issue: Pre-commit hook not running

**Solution**:

```bash
# Re-initialize Husky
npx husky install

# Make hook executable
chmod +x .husky/pre-commit

# Verify
test -x .husky/pre-commit && echo "Fixed!"
```

### Issue: Husky hook is missing content

**Solution**:

```bash
cat > .husky/pre-commit << 'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npm run precommit
EOF

chmod +x .husky/pre-commit
```

### Issue: ESLint errors blocking commits

**Solution**:

```bash
# Auto-fix ESLint issues
npm run lint -- --fix

# Or bypass once (not recommended)
git commit --no-verify -m "message"
```

---

## Configuration Files

| File                           | Purpose                                                  |
| ------------------------------ | -------------------------------------------------------- |
| `.prettierrc`                  | Prettier rules (trailingComma: none, plugins, overrides) |
| `.prettierignore`              | Files/directories to skip formatting                     |
| `.husky/pre-commit`            | Git pre-commit hook that runs lint-staged                |
| `package.json` → `lint-staged` | Defines what commands run on staged files                |
| `package.json` → `scripts`     | npm commands (prettier, lint, test, precommit)           |
| `.vscode/settings.json`        | VS Code Prettier integration                             |

---

## Maintenance

### Update Prettier and Plugins

```bash
npm update prettier prettier-plugin-apex @prettier/plugin-xml
```

### Update Husky

```bash
npm update husky lint-staged
npx husky install  # Re-initialize after update
```

### Add/Remove File Types

Edit `package.json` → `lint-staged` section:

```json
{
  "lint-staged": {
    "**/*.{cls,trigger,xml,js}": ["prettier --write"]
  }
}
```

---

## Team Guidelines

1. **Never commit without formatting** - Let Husky do its job
2. **Use `--no-verify` sparingly** - Only for emergencies
3. **Keep plugins updated** - Check monthly for updates
4. **Format before code review** - Run `npm run prettier` before creating PR
5. **Report issues** - If hooks break, notify team immediately

---

## Success Indicators

✅ Running `git commit` shows:

```
⚡️ Preparing lint-staged...
⚡️ Running tasks for staged files...
⚡️ prettier --write
⚡️ eslint
⚡️ sfdx-lwc-jest --bail --findRelatedTests --passWithNoTests
✔ All tasks completed successfully
```

✅ VS Code formats files automatically on save

✅ No "Cannot find module 'prettier'" errors in VS Code

✅ `npm run prettier:verify` shows no unformatted files

---

## Contact

For issues or questions:

1. Check this document first
2. Run verification checklist above
3. Check `CLAUDE.md` → "Code Quality & Formatting" section
4. Review Git commit history for recent changes

---

**Last Verified**: October 4, 2025  
**Verified By**: Claude Code  
**Status**: ✅ All systems operational
