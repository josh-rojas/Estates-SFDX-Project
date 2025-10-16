#!/bin/bash

# Test Data Validation Script
# Purpose: Validate test data quality after Snowfakery generation
# Ensures all Person Accounts have valid email addresses and proper data

echo "🔍 Validating test data quality..."

# Check for NULL emails
echo "Checking for NULL email addresses..."
NULL_EMAILS=$(sf data query --query "SELECT COUNT() FROM Account WHERE IsPersonAccount = true AND PersonEmail = null" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$NULL_EMAILS" -gt 0 ]; then
    echo "❌ Found $NULL_EMAILS Person Accounts with NULL emails"
    echo "   Run: sf data query --query \"SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail = null\" --target-org schwab-sandbox"
    exit 1
else
    echo "✅ No NULL email addresses found"
fi

# Check for invalid email formats
echo "Checking for invalid email formats..."
INVALID_EMAILS=$(sf data query --query "SELECT COUNT() FROM Account WHERE IsPersonAccount = true AND PersonEmail NOT LIKE '%@%.%'" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$INVALID_EMAILS" -gt 0 ]; then
    echo "❌ Found $INVALID_EMAILS Person Accounts with invalid email formats"
    echo "   Run: sf data query --query \"SELECT Id, Name, PersonEmail FROM Account WHERE IsPersonAccount = true AND PersonEmail NOT LIKE '%@%.%'\" --target-org schwab-sandbox"
    exit 1
else
    echo "✅ All email addresses have valid format"
fi

# Check for opted-out emails
echo "Checking for opted-out email addresses..."
OPTED_OUT=$(sf data query --query "SELECT COUNT() FROM Account WHERE IsPersonAccount = true AND PersonHasOptedOutOfEmail = true" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$OPTED_OUT" -gt 0 ]; then
    echo "⚠️  Found $OPTED_OUT Person Accounts with opted-out emails"
    echo "   This may be intentional for SLA escalation scenarios"
    echo "   Run: sf data query --query \"SELECT Id, Name, PersonEmail, PersonHasOptedOutOfEmail FROM Account WHERE IsPersonAccount = true AND PersonHasOptedOutOfEmail = true\" --target-org schwab-sandbox"
else
    echo "✅ No opted-out email addresses found"
fi

# Check for missing Contact relationships
echo "Checking Person Account Contact relationships..."
MISSING_CONTACTS=$(sf data query --query "SELECT COUNT() FROM Account WHERE IsPersonAccount = true AND PersonContactId = null" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$MISSING_CONTACTS" -gt 0 ]; then
    echo "❌ Found $MISSING_CONTACTS Person Accounts without Contact relationships"
    echo "   This will cause issues with Financial Account Roles"
    exit 1
else
    echo "✅ All Person Accounts have Contact relationships"
fi

# Check for missing Financial Account Roles
echo "Checking Financial Account Role completeness..."
MISSING_ROLES=$(sf data query --query "SELECT COUNT() FROM FinServ__FinancialAccount__c WHERE Id NOT IN (SELECT FinServ__FinancialAccount__c FROM FinServ__FinancialAccountRole__c WHERE FinServ__Role__c = 'Primary Owner')" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$MISSING_ROLES" -gt 0 ]; then
    echo "❌ Found $MISSING_ROLES Financial Accounts without Primary Owner roles"
    echo "   This will cause issues with succession processing"
    exit 1
else
    echo "✅ All Financial Accounts have Primary Owner roles"
fi

# Check for missing Successor roles
MISSING_SUCCESSORS=$(sf data query --query "SELECT COUNT() FROM FinServ__FinancialAccount__c WHERE Id NOT IN (SELECT FinServ__FinancialAccount__c FROM FinServ__FinancialAccountRole__c WHERE FinServ__Role__c = 'Successor')" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$MISSING_SUCCESSORS" -gt 0 ]; then
    echo "❌ Found $MISSING_SUCCESSORS Financial Accounts without Successor roles"
    echo "   This will cause issues with succession processing"
    exit 1
else
    echo "✅ All Financial Accounts have Successor roles"
fi

# Check for valid Successor allocations
echo "Checking Successor allocation validity..."
INVALID_ALLOCATIONS=$(sf data query --query "SELECT COUNT() FROM FinServ__FinancialAccountRole__c WHERE FinServ__Role__c = 'Successor' AND (SuccessorAllocation__c = null OR SuccessorAllocation__c <= 0 OR SuccessorAllocation__c > 100)" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$INVALID_ALLOCATIONS" -gt 0 ]; then
    echo "❌ Found $INVALID_ALLOCATIONS Successor roles with invalid allocations"
    echo "   Allocations must be between 1-100"
    echo "   Run: sf data query --query \"SELECT Id, SuccessorAllocation__c, FinServ__RelatedContact__r.Name FROM FinServ__FinancialAccountRole__c WHERE FinServ__Role__c = 'Successor' AND (SuccessorAllocation__c = null OR SuccessorAllocation__c <= 0 OR SuccessorAllocation__c > 100)\" --target-org schwab-sandbox"
    exit 1
else
    echo "✅ All Successor allocations are valid"
fi

# Check for Case data completeness
echo "Checking Case data completeness..."
MISSING_CASES=$(sf data query --query "SELECT COUNT() FROM Case WHERE RecordType.DeveloperName = 'EstateAdministration' AND (AccountId = null OR FinServ__FinancialAccount__c = null)" --target-org schwab-sandbox --json | jq -r '.result.records[0].expr0')

if [ "$MISSING_CASES" -gt 0 ]; then
    echo "❌ Found $MISSING_CASES Cases missing Account or Financial Account relationships"
    echo "   This will cause issues with succession processing"
    exit 1
else
    echo "✅ All Cases have required relationships"
fi

echo ""
echo "🎉 Test data validation completed successfully!"
echo "✅ All critical data quality checks passed"
echo ""
echo "📊 Summary:"
echo "   - Email addresses: Valid format and not NULL"
echo "   - Person Account relationships: Complete"
echo "   - Financial Account Roles: Complete"
echo "   - Successor allocations: Valid"
echo "   - Case relationships: Complete"
echo ""
echo "🚀 Test data is ready for demo!"