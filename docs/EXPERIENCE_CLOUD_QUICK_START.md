# Experience Cloud Quick Start Checklist

**Site:** Succession Portal (Token-Based Succession Form)
**Estimated Time:** 15 minutes (deployment only)

---

## ✅ Pre-Flight Checklist

- [ ] Experience Cloud license enabled
- [ ] My Domain deployed
- [ ] System Administrator access
- [ ] Email deliverability set to "All Email"

---

## 🚀 Deployment (5 commands, 15 minutes)

### 1. Deploy Experience Cloud Site

```bash
cd "/Users/joshsmbp/Schwab Downloads/Estates SFDX Project"

sf project deploy start \
  --manifest manifest/package-experience-cloud-succession.xml \
  --target-org schwab-sandbox \
  --wait 15
```

**Expected Output:**
```
Status: Succeeded
Components Deployed: 7
  ✓ Network: Succession Portal
  ✓ CustomSite: Succession_Portal
  ✓ Profile: Succession Portal Profile
  ✓ ExperienceBundle: Succession_Portal1
```

---

### 2. Activate Site (via UI)

1. **Setup → Digital Experiences → All Sites**
2. Find "Succession Portal"
3. Click **Builder**
4. Click **Settings** (gear icon) → **Activate**
5. Click **Publish**

**Site URL:** `https://{org-domain}.my.site.com/succession`

---

### 3. Configure Guest Profile Apex Access (via CLI)

```bash
# Add Apex class permissions to guest profile
sf data update record \
  --sobject Profile \
  --where "Name='Succession Portal Profile'" \
  --values "ApiEnabled=true" \
  --target-org schwab-sandbox
```

**OR via UI:**
- Setup → Profiles → Succession Portal Profile
- Enabled Apex Classes → Edit
- Add: `SuccessionFormController`, `SuccessionFormTokenValidator`

---

### 4. Test Form Access

**Generate test token:**

```apex
// Execute in Developer Console
Case c = [SELECT Id FROM Case WHERE Type = 'Succession Management' LIMIT 1];
String token = SuccessionFormTokenGenerator.generateToken(c.Id);
System.debug('URL: https://{org}.my.site.com/succession/form?t=' + token);
```

**Access form in incognito browser:**
- Copy URL from debug log
- Open in private/incognito window
- Verify form loads without login

---

### 5. Verify Submission Flow

1. Complete all 7 form steps
2. Submit form
3. Query Case:
   ```sql
   SELECT Pathway_Confirmed__c, Form_Completed_Date__c
   FROM Case WHERE Id = '{caseId}'
   ```
4. Confirm fields updated

---

## 📋 Created Files (Deployed)

```
force-app/main/default/
├── networks/
│   └── Succession Portal.network-meta.xml         # Site settings
├── sites/
│   └── Succession_Portal.site-meta.xml            # Site definition
├── profiles/
│   └── Succession Portal Profile.profile-meta.xml # Guest permissions
└── experiences/
    ├── Succession_Portal1.site-meta.xml           # Bundle metadata
    └── Succession_Portal1/
        ├── config/
        │   └── mainAppPage.json                   # App config
        ├── views/
        │   └── Succession_Form.json               # Form page
        └── branding/
            └── branding.json                      # Theme/colors

manifest/
└── package-experience-cloud-succession.xml        # Deploy manifest

docs/
├── EXPERIENCE_CLOUD_DEPLOYMENT.md                 # Full guide (45 min)
└── EXPERIENCE_CLOUD_QUICK_START.md                # This file (15 min)
```

---

## 🔧 Troubleshooting Quick Fixes

| Error | Fix |
|-------|-----|
| "Site Not Found" | Verify My Domain is deployed |
| "Access Denied" | Check guest profile Apex class access |
| Component blank | Clear Builder cache, re-publish |
| Token invalid | Regenerate token, check expiration (30 days) |

**Full troubleshooting:** See `EXPERIENCE_CLOUD_DEPLOYMENT.md`

---

## 🎯 Success Criteria

- ✅ Site accessible at `/succession` URL
- ✅ Form loads without login
- ✅ Token validation works
- ✅ Form submission updates Case
- ✅ Guest user has no access to other data

---

## 📞 Need Help?

**Documentation:** `/docs/EXPERIENCE_CLOUD_DEPLOYMENT.md` (comprehensive 45-min guide)
**Support:** IT Admin Team | it-admin@schwabcharitable.org

---

**Version:** 1.0 | **Last Updated:** 2025-10-03
