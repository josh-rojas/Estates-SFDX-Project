# Experience Cloud Setup: UI-Based Approach (Recommended)

**Why UI-Based?**
- Experience Cloud has complex metadata dependencies
- Sites require sequential setup (Network → Site → Profile → Pages)
- Metadata API has API version compatibility issues
- UI automatically handles guest profile creation
- Builder provides visual page design

**Time:** 20 minutes | **Difficulty:** Easy

---

## Step-by-Step Setup

### Step 1: Create Experience Cloud Site (5 min)

1. **Setup → Digital Experiences → All Sites**
2. Click **New**
3. Select template:
   - Choose **Build Your Own (LWR)** ← Modern, fast
   - Click **Get Started**

4. Site Details:
   ```
   Name: Succession Portal
   URL: succession
   ```
5. Click **Create**

**✓ Site created!** Now it needs configuration...

---

### Step 2: Add LWC Component to Site (10 min)

1. From All Sites, click **Builder** next to "Succession Portal"

2. **Create New Page:**
   - Pages menu (left sidebar) → **+ New Page**
   - Page Label: `Succession Form`
   - Page Name: `Succession_Form`
   - Page Type: **Standard Page**
   - Click **Create**

3. **Add Component:**
   - In Builder canvas, click **+ Add Component**
   - Search: `successionPathwayForm`
   - Drag component to page content area
   - Component should fill the entire page

4. **Configure URL Parameters:**
   - Click **Settings** (gear icon, top-right)
   - Advanced → URL Parameters
   - Add parameter: `t` (for token)
   - **Save**

5. **Set as Home Page:**
   - Pages menu → Click "⋮" next to Succession_Form
   - Set as Home Page
   - **Confirm**

6. **Publish:**
   - Click **Publish** (top-right)
   - Wait for publish to complete

---

### Step 3: Activate Site (2 min)

1. In Builder, click **Settings** → **General**
2. **Status: Inactive** → Toggle to **Active**
3. **Save**
4. Note the site URL:
   ```
   https://{org-domain}.my.site.com/succession
   ```

---

### Step 4: Configure Guest User Profile (5 min)

**Auto-generated profile:** `Succession Portal Profile`

1. **Setup → Profiles → Succession Portal Profile**

2. **Enable Apex Classes:**
   - Scroll to **Enabled Apex Class Access**
   - Click **Edit**
   - Add to "Enabled Apex Classes":
     - `SuccessionFormController`
     - `SuccessionFormTokenValidator`
     - `SuccessionFormTokenGenerator`
   - **Save**

3. **Verify Object Permissions:**
   - Scroll to **Custom Object Permissions**
   - Ensure **Read** access for:
     - Case ✓
     - Account ✓
     - FinServ__FinancialAccount__c ✓
   - If missing, click **Edit** and add

4. **Field-Level Security:**
   - Scroll to **Field-Level Security**
   - Click **View** next to Case
   - Ensure these fields are **Visible**:
     - Pathway_Confirmed__c
     - Form_Sent_Date__c
     - Form_Completed_Date__c
     - Contact_Established__c
     - Verification_Status__c
   - Edit if needed

---

### Step 5: Test Form Access (5 min)

**Generate Test Token:**

```apex
// Execute in Developer Console → Debug → Open Execute Anonymous Window
Case testCase = [
    SELECT Id, CaseNumber
    FROM Case
    WHERE Type = 'Succession Management'
    LIMIT 1
];

String token = SuccessionFormTokenGenerator.generateToken(testCase.Id);

// Get site URL
String siteURL = 'https://' + Site.getDomain() + '/succession/form?t=' + token;

System.debug('===== TEST URL =====');
System.debug(siteURL);
System.debug('====================');
```

**Test in Browser:**

1. Copy URL from debug log
2. Open **incognito/private browser** (important - no Salesforce login)
3. Paste URL and press Enter
4. **Expected:** Form loads, shows Step 1/7, no login required
5. **If error:** See troubleshooting below

---

## Success Criteria

- ✅ Site accessible at `https://{org}.my.site.com/succession`
- ✅ Form loads without login
- ✅ Token parameter (`?t=...`) works
- ✅ Form shows 7-step wizard interface
- ✅ Guest user cannot access Setup or other objects

---

## Troubleshooting

### Form Shows "Access Denied"

**Fix:** Guest profile missing Apex permissions
```bash
# Verify via CLI
sf data query \
  --query "SELECT Parent.Name, ApexClass.Name
           FROM SetupEntityAccess
           WHERE ParentId IN (
               SELECT Id FROM Profile
               WHERE Name = 'Succession Portal Profile'
           )" \
  --target-org schwab-sandbox
```
Should return 3 rows (the 3 Apex classes).

---

### Component Not Visible

**Fix:** Component not exposed to Experience Cloud
1. **VS Code:** force-app/main/default/lwc/successionPathwayForm/successionPathwayForm.js-meta.xml
2. Ensure this line exists:
   ```xml
   <isExposed>true</isExposed>
   <targets>
       <target>lightningCommunity__Page</target>
   </targets>
   ```
3. Re-deploy component:
   ```bash
   sf project deploy start \
     --metadata LightningComponentBundle:successionPathwayForm \
     --target-org schwab-sandbox
   ```

---

### "Site Not Found" or 404 Error

**Fix:** Site not activated or URL wrong
1. Setup → Digital Experiences → All Sites
2. Check "Succession Portal" status = **Active**
3. Verify URL path = `/succession`
4. Test: `https://{org}.my.site.com/succession` (no /form)

---

## Optional: Custom Domain

**Production Setup:** `succession.schwabcharitable.org`

1. **Setup → Digital Experiences → Settings**
2. **Domains** tab
3. Add domain: `succession.schwabcharitable.org`
4. Follow DNS verification steps
5. Add SSL certificate
6. Update email templates with new domain

---

## Next Steps After Setup

1. **Update Email Templates:**
   - Add site URL to succession notification emails
   - Template variable: `{!Case.Succession_Form_URL__c}`

2. **Test All 3 Pathways:**
   - Final Grant pathway (grant beneficiary selection)
   - New DAF pathway (email verification)
   - Disclaim pathway (legal attestation)

3. **Load Testing:**
   - Test with 100+ concurrent users
   - Monitor performance via Experience Cloud Analytics

4. **Monitor Usage:**
   - Setup → Digital Experiences → All Sites → Succession Portal → **Workspaces** → Analytics
   - Track: Page views, completion rate, errors

---

## Alternative: CLI-Based Deployment (Not Recommended)

If you must use CLI (e.g., CI/CD pipeline), use Salesforce DX Experience Cloud commands:

```bash
# Create site via CLI (requires sfdx-exp plugin)
sfdx force:community:create \
  --name "Succession Portal" \
  --urlpathprefix succession \
  --templatename "Build Your Own (LWR)" \
  --targetusername schwab-sandbox

# Publish site
sfdx force:community:publish \
  --name "Succession Portal" \
  --targetusername schwab-sandbox
```

**Note:** This still requires manual component configuration in Builder.

---

## FAQ

**Q: Can I deploy this to a scratch org?**
A: Yes, but you need Experience Cloud licenses. Add to project-scratch-def.json:
```json
{
  "features": ["Communities"]
}
```

**Q: Why not use OmniScript/Vlocity DataPacks?**
A: LWC approach is modern, performant, and easier to maintain. OmniStudio was considered but removed (see commit 2ad6e89).

**Q: How do I customize the branding?**
A: Builder → Settings → Theme → Configure colors, fonts, logo

---

**Version:** 1.0
**Last Updated:** 2025-10-03
**Setup Time:** 20 minutes
**Recommended Approach:** ✓ UI-Based (this guide)
