#!/usr/bin/env bash
# Trigger Guix build workflow for Janus Gateway

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
BRANCH="claude/create-janus-guix-package-011CV22VWjyzoXGBpR6A6R6T"
WAIT=false
REPO="${REPO:-ifitzpat/janus-gateway}"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Trigger the Guix build workflow for Janus Gateway.

OPTIONS:
    --branch BRANCH    Branch to build (default: $BRANCH)
    --wait             Wait for the workflow to complete
    --help             Display this help message

ENVIRONMENT:
    REPO              Repository in format owner/repo (default: $REPO)
    GITHUB_TOKEN      GitHub token for authentication

EXAMPLES:
    $0 --branch master
    $0 --branch master --wait
    REPO=myuser/janus-gateway $0 --wait

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --wait)
            WAIT=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it from https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

echo -e "${BLUE}Triggering Guix build workflow...${NC}"
echo -e "${BLUE}Repository: ${REPO}${NC}"
echo -e "${BLUE}Branch: ${BRANCH}${NC}"

# Trigger the workflow
if gh workflow run guix-build.yml --repo "$REPO" --ref "$BRANCH"; then
    echo -e "${GREEN}✓ Workflow triggered successfully${NC}"
else
    echo -e "${RED}✗ Failed to trigger workflow${NC}"
    exit 1
fi

if [ "$WAIT" = true ]; then
    echo -e "${YELLOW}Waiting for workflow to start...${NC}"
    sleep 5

    # Get the latest run ID for this workflow
    RUN_ID=$(gh run list --repo "$REPO" --workflow=guix-build.yml --branch "$BRANCH" --limit 1 --json databaseId --jq '.[0].databaseId')

    if [ -n "$RUN_ID" ]; then
        echo -e "${BLUE}Watching workflow run #${RUN_ID}...${NC}"
        gh run watch "$RUN_ID" --repo "$REPO" --exit-status

        # Check final status
        STATUS=$(gh run view "$RUN_ID" --repo "$REPO" --json conclusion --jq '.conclusion')

        if [ "$STATUS" = "success" ]; then
            echo -e "${GREEN}✓ Workflow completed successfully${NC}"
            exit 0
        else
            echo -e "${RED}✗ Workflow failed with status: ${STATUS}${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ Could not find workflow run${NC}"
        exit 1
    fi
else
    echo ""
    echo -e "${BLUE}To monitor the workflow status, run:${NC}"
    echo "  gh run list --repo $REPO --workflow=guix-build.yml --branch $BRANCH"
    echo ""
    echo -e "${BLUE}Or use the monitoring script:${NC}"
    echo "  ./scripts/ci/monitor-guix-build.sh --branch $BRANCH"
fi
