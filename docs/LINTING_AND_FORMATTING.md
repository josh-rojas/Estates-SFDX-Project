# Code Quality Guide

For everyone working on this Salesforce project - no technical jargon!

## The Commands You'll Use

```bash
npm run cleanup           # Clean up my code formatting
npm test                  # Test my code
npm run ready-to-commit   # Am I ready to save?
npm run full-check        # Complete validation
```

---

## When to Run Each Command

### 🔧 Daily Work

#### `npm run cleanup`

**Makes your code look neat and consistent**

```bash
npm run cleanup
```

**What it does:**

- Fixes spacing, indentation, and formatting
- Cleans up code style issues
- Makes everything look professional

**When:** After writing code, before saving

**Example:**

```bash
# 1. Write your code
# 2. Clean it up
npm run cleanup

# 3. Save it
git add .
git commit -m "Add new feature"
```

---

#### `npm test`

**Checks if your code works correctly**

```bash
npm test
```

**What it does:** Runs automated tests on your components

**When:** After writing code to make sure it works

---

#### `npm run auto-test`

**Automatically tests as you code**

```bash
npm run auto-test
```

**What it does:** Reruns tests every time you save a file

**When:** While actively writing code and tests together

**Tip:** Press `q` to stop when you're done

---

### ✅ Before Git Commit

#### `npm run ready-to-commit`

**Checks if everything is good to save**

```bash
npm run ready-to-commit
```

**What it does:**

1. Checks code formatting
2. Checks code quality
3. Runs all tests
4. Tells you if anything needs fixing

**When:** Before running `git commit` (optional - git does this automatically!)

**If it fails:**

```bash
# Clean up formatting first
npm run cleanup

# Try again
npm run ready-to-commit

# If still failing, read the error message and fix manually
```

**Good news:** Git runs this automatically, so you rarely need to!

---

### 🤖 Automated Pipeline

#### `npm run full-check`

**Complete validation (what automation runs)**

```bash
npm run full-check
```

**What it does:**

1. Checks code formatting
2. Checks code quality
3. Tests with coverage tracking
4. Scans for security issues

**When:**

- Runs automatically in GitHub/Jenkins on every pull request
- Run manually before creating a pull request

**Note:** This is slower (20-50 seconds) because it includes security scanning

---

## Git Saves Your Code Automatically

**Good news:** You don't need to remember these commands!

When you run `git commit`, these happen **automatically**:

1. ✨ Formats your code
2. 🔧 Fixes code style issues
3. 🧪 Runs tests

If anything fails, git **stops the save** and tells you what's wrong.

**To skip (not recommended):**

```bash
git commit --no-verify
```

---

## Common Workflows

### Typical Day of Coding

```bash
# 1. Write your code in VS Code

# 2. (Optional) Clean it up - git does this anyway
npm run cleanup

# 3. (Optional) Test it
npm test

# 4. Save it - git runs checks automatically
git add .
git commit -m "Add new feature"
# → Git checks: format ✓ quality ✓ tests ✓
# → If everything passes: Save complete! ✅
# → If something fails: Fix it first ❌
```

**Shortcut:** Just write code and commit. Git handles the rest!

---

### Before Creating a Pull Request

```bash
# Run the full check locally
npm run full-check

# If it passes, your pull request will pass ✅
```

---

### When Git Blocks Your Save

**If git won't let you commit:**

```bash
# 1. Read what went wrong
# Example: "Code formatting issues found"

# 2. Clean up the code
npm run cleanup

# 3. Check if you're ready now
npm run ready-to-commit

# 4. If still failing, fix manually
# Common issues: unused code, missing error handling

# 5. Try saving again
git commit -m "Add new feature"
```

---

## Script Reference

### What Each Script Does

| Command                   | Speed           | Changes Files? | Purpose               |
| ------------------------- | --------------- | -------------- | --------------------- |
| `npm run cleanup`         | Fast (2-5s)     | ✅ Yes         | Clean up formatting   |
| `npm test`                | Fast (5-10s)    | ❌ No          | Test your code        |
| `npm run auto-test`       | Continuous      | ❌ No          | Auto-test as you code |
| `npm run ready-to-commit` | Medium (10-20s) | ❌ No          | Ready to save?        |
| `npm run full-check`      | Slow (20-50s)   | ❌ No          | Complete validation   |

### Scripts by Section

| Section                | Scripts                        | When You Use Them         |
| ---------------------- | ------------------------------ | ------------------------- |
| **DAILY WORK**         | `cleanup`, `test`, `auto-test` | While coding              |
| **BEFORE GIT COMMIT**  | `ready-to-commit`              | Before saving (optional)  |
| **AUTOMATED PIPELINE** | `full-check`                   | Runs automatically on PRs |

---

## For Business Stakeholders

**You don't run these commands!** Developers use them for code quality.

**What you see:**

- ✅ **Green checks** on pull requests = Code is good
- ❌ **Red X** on pull requests = Code needs fixes

**Automation runs:** `npm run full-check` on every pull request

---

## VS Code Setup (Highly Recommended)

### Install These Extensions

These make VS Code automatically fix your code as you type:

- [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)

### Auto-Format When Saving

Add to [.vscode/settings.json](../.vscode/settings.json):

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  }
}
```

**Result:** Code cleans up automatically every time you save! No manual `npm run cleanup` needed.

---

## Troubleshooting

### "ready-to-commit says there's an issue but cleanup doesn't fix it"

**Cause:** Some problems need manual fixes

**Common issues:**

- **Unused code** → Delete it
- **Missing error handling** → Add try/catch
- **Logic problems** → Fix the code

**How to fix:**

1. Read the error carefully
2. Find the file and line number
3. Fix the issue
4. Run `npm run ready-to-commit` again

---

### "Git commit is slow"

**Cause:** Tests running on your changes

**Normal times:**

- Small changes (1-2 files): 5-10 seconds
- Medium changes (5-10 files): 15-30 seconds
- Large changes (20+ files): 30-60 seconds

**Tips:**

- Save in smaller batches (fewer files = faster)
- Use `npm run auto-test` while coding for instant feedback

---

### "Code keeps reformatting weirdly"

**This is intentional!** Everyone's code looks the same.

**Why it's good:**

- Team consistency
- No arguing about code style
- Focus on logic, not formatting

**Special cases:** Use `// prettier-ignore` comments (rare)

---

### "How do I clean up just one file?"

**VS Code (easiest):**

1. Open the file
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows)
3. Type "Format Document"
4. Press Enter

**Command line:**

```bash
npx prettier --write path/to/file.js
```

---

### "How do I test just one component?"

```bash
npm test -- path/to/myComponent.test.js
```

---

### "How do I debug a failing test?"

**Option 1: VS Code (best):**

1. Open the test file
2. Click the debug icon next to the test
3. Set breakpoints
4. Click "Debug Test"

**Option 2: Add logging:**

```javascript
test("my test", () => {
  console.log("Value is:", myValue);
  expect(myValue).toBe(true);
});
```

---

## Quick Reference Card

| What You Want to Do | Run This                  |
| ------------------- | ------------------------- |
| Clean up my code    | `npm run cleanup`         |
| Test my code        | `npm test`                |
| Test while I code   | `npm run auto-test`       |
| Check before saving | `npm run ready-to-commit` |
| Full validation     | `npm run full-check`      |

---

## FAQ

**Q: Which command do I run most?**
A: Just `npm test`. Git handles cleanup automatically.

**Q: Do I need to run ready-to-commit before saving?**
A: No - git runs it automatically. But you can run it for faster feedback.

**Q: What's the difference between ready-to-commit and full-check?**
A: `ready-to-commit` is fast. `full-check` is slow but more thorough (includes security scan).

**Q: Why did git block my save?**
A: Something failed (formatting, quality, or tests). Read the error and fix it.

**Q: Can I skip git's automatic checks?**
A: Yes with `git commit --no-verify`, but **don't**. The automated checks will catch it anyway.

**Q: How do I know what to fix?**
A: Read the error message. It tells you the file, line number, and what's wrong.

---

## For New Developers

**Week 1:** Install VS Code extensions, turn on auto-format, just code and save

**Week 2:** Run `npm test` after writing code

**Week 3:** Run `npm run ready-to-commit` to catch issues early

**Week 4:** Understand `npm run full-check` and automation

**Remember:**

- Git's automatic checks are your friend
- `npm run cleanup` fixes most issues
- Read error messages - they're helpful!
- Ask for help - everyone starts somewhere!

---

## Configuration Files

If you're curious where these are configured:

- **Code quality rules:** [eslint.config.js](../eslint.config.js)
- **Formatting rules:** [.prettierrc.json](../.prettierrc.json)
- **Files to skip:** [.prettierignore](../.prettierignore)
- **Git automation:** [.husky/](.husky/)
- **What git checks:** `lint-staged` in [package.json](../package.json)

---

**Questions?** Ask in Slack or check [package.json](../package.json) for script details.
