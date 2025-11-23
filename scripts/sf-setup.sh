#!/bin/bash
# Salesforce CLI Setup Script
# Defines aliases and functions for common Salesforce development tasks

# ==============================================================================
# Configuration
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ==============================================================================
# Aliases
# ==============================================================================

# Auth
alias sf-login="sf org login web --set-default --alias succession-org"
alias sf-open="sf org open"

# Deployment
alias sf-deploy="sf project deploy start --manifest manifest/package.xml"
alias sf-deploy-validate="sf project deploy validate --manifest manifest/package.xml"
alias sf-deploy-cancel="sf project deploy cancel"

# Retrieval
alias sf-retrieve="sf project retrieve start --manifest manifest/package.xml"

# Testing
alias sf-test="sf apex run test --test-level RunLocalTests --code-coverage --result-format human"
alias sf-test-all="sf apex run test --test-level RunAllTestsInOrg --code-coverage --result-format human"

# Data
alias sf-data-import="sf data tree import --plan data/sample-data-plan.json"
alias sf-data-export="sf data tree export --query \"SELECT Id, Name FROM Account\" --output-dir data --plan"

# Logs
alias sf-logs="sf apex get log --number 10"
alias sf-tail="sf apex tail log --color"

# ==============================================================================
# Functions
# ==============================================================================

# Deploy to a specific org
# Usage: sf-deploy-to <org-alias>
function sf-deploy-to() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify an org alias.${NC}"
        echo "Usage: sf-deploy-to <org-alias>"
        return 1
    fi
    echo -e "${BLUE}Deploying to $1...${NC}"
    sf project deploy start --manifest manifest/package.xml --target-org "$1"
}

# Run tests in a specific org
# Usage: sf-test-in <org-alias>
function sf-test-in() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify an org alias.${NC}"
        echo "Usage: sf-test-in <org-alias>"
        return 1
    fi
    echo -e "${BLUE}Running local tests in $1...${NC}"
    sf apex run test --test-level RunLocalTests --code-coverage --result-format human --target-org "$1"
}

# Run a specific test class
# Usage: sf-test-class <ClassName> [org-alias]
function sf-test-class() {
    if [ -z "$1" ]; then
        echo -e "${RED}Error: Please specify a test class name.${NC}"
        echo "Usage: sf-test-class <ClassName> [org-alias]"
        return 1
    fi
    
    local target_org=""
    if [ -n "$2" ]; then
        target_org="--target-org $2"
    fi

    echo -e "${BLUE}Running test class $1...${NC}"
    sf apex run test --class-names "$1" --code-coverage --result-format human $target_org
}

# Assign default permission sets
function sf-assign-perms() {
    echo -e "${BLUE}Assigning Permission Sets...${NC}"
    sf org assign permset --name Succession_Management_Access
    sf org assign permset --name Succession_Field_Access
    echo -e "${GREEN}Done.${NC}"
}

# ==============================================================================
# Initialization
# ==============================================================================

echo -e "${GREEN}Salesforce CLI aliases loaded!${NC}"
echo -e "  ${YELLOW}sf-login${NC}       - Login to default org"
echo -e "  ${YELLOW}sf-deploy${NC}      - Deploy to default org"
echo -e "  ${YELLOW}sf-test${NC}        - Run local tests"
echo -e "  ${YELLOW}sf-test-class${NC}  - Run specific test class"
echo -e "  ${YELLOW}sf-logs${NC}        - Get recent logs"
echo ""
