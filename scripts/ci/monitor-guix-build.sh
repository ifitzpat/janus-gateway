#!/usr/bin/env bash
# Monitor Guix build workflow status for Janus Gateway

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
BRANCH="claude/create-janus-guix-package-011CV22VWjyzoXGBpR6A6R6T"
WATCH=false
INTERVAL=30
REPO="${REPO:-ifitzpat/janus-gateway}"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Monitor the status of Guix build workflows for Janus Gateway.

OPTIONS:
    --branch BRANCH      Branch to monitor (default: $BRANCH)
    --watch              Continuously watch until completion
    --interval SECONDS   Refresh interval in watch mode (default: $INTERVAL)
    --help               Display this help message

ENVIRONMENT:
    REPO                 Repository in format owner/repo (default: $REPO)
    GITHUB_TOKEN         GitHub token for authentication

EXAMPLES:
    $0 --branch master
    $0 --watch
    $0 --watch --interval 15
    REPO=myuser/janus-gateway $0 --branch master --watch

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
        --watch)
            WATCH=true
            shift
            ;;
        --interval)
            INTERVAL="$2"
            shift 2
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

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed.${NC}"
    echo "Please install it: apt-get install jq / brew install jq"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Function to format duration
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [ $hours -gt 0 ]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [ $minutes -gt 0 ]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# Function to get status color
status_color() {
    case $1 in
        success|completed)
            echo -e "${GREEN}"
            ;;
        failure|failed)
            echo -e "${RED}"
            ;;
        in_progress|queued)
            echo -e "${YELLOW}"
            ;;
        *)
            echo -e "${NC}"
            ;;
    esac
}

# Function to display workflow status
display_status() {
    local clear_screen=${1:-false}

    if [ "$clear_screen" = true ]; then
        clear
    fi

    echo -e "${BLUE}=== Janus Gateway Guix Build Status ===${NC}"
    echo -e "${BLUE}Repository: ${REPO}${NC}"
    echo -e "${BLUE}Branch: ${BRANCH}${NC}"
    echo ""

    # Get the latest workflow run
    local run_data
    run_data=$(gh run list --repo "$REPO" --workflow=guix-build.yml --branch "$BRANCH" --limit 1 --json databaseId,status,conclusion,name,displayTitle,createdAt,updatedAt,headSha,number,url)

    if [ "$(echo "$run_data" | jq 'length')" -eq 0 ]; then
        echo -e "${YELLOW}No workflow runs found for branch: $BRANCH${NC}"
        return 1
    fi

    local run_id run_number status conclusion title created_at updated_at sha url
    run_id=$(echo "$run_data" | jq -r '.[0].databaseId')
    run_number=$(echo "$run_data" | jq -r '.[0].number')
    status=$(echo "$run_data" | jq -r '.[0].status')
    conclusion=$(echo "$run_data" | jq -r '.[0].conclusion // "in_progress"')
    title=$(echo "$run_data" | jq -r '.[0].displayTitle')
    created_at=$(echo "$run_data" | jq -r '.[0].createdAt')
    updated_at=$(echo "$run_data" | jq -r '.[0].updatedAt')
    sha=$(echo "$run_data" | jq -r '.[0].headSha' | cut -c1-7)
    url=$(echo "$run_data" | jq -r '.[0].url')

    # Calculate duration
    local created_ts updated_ts duration
    created_ts=$(date -d "$created_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s 2>/dev/null || echo 0)
    updated_ts=$(date -d "$updated_at" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated_at" +%s 2>/dev/null || echo 0)
    duration=$((updated_ts - created_ts))

    # Display run information
    echo -e "${CYAN}Run #${run_number}${NC} (ID: ${run_id})"
    echo -e "Commit: ${sha}"
    echo -e "Title: ${title}"
    echo -e "Status: $(status_color "$conclusion")${conclusion}${NC}"
    echo -e "Duration: $(format_duration $duration)"
    echo -e "URL: ${url}"
    echo ""

    # Get job details
    echo -e "${CYAN}Job Details:${NC}"
    local jobs_data
    jobs_data=$(gh run view "$run_id" --repo "$REPO" --json jobs --jq '.jobs')

    echo "$jobs_data" | jq -r '.[] | "\(.name)|\(.status)|\(.conclusion // "pending")"' | while IFS='|' read -r name job_status job_conclusion; do
        local display_status="$job_conclusion"
        if [ "$display_status" = "null" ] || [ "$display_status" = "pending" ]; then
            display_status="$job_status"
        fi
        echo -e "  • ${name}: $(status_color "$display_status")${display_status}${NC}"
    done

    echo ""

    # Return status for watch mode
    if [ "$status" = "completed" ]; then
        return 0
    else
        return 1
    fi
}

# Main execution
if [ "$WATCH" = true ]; then
    echo -e "${BLUE}Starting continuous monitoring (refresh every ${INTERVAL}s)${NC}"
    echo -e "${BLUE}Press Ctrl+C to stop${NC}"
    echo ""

    first_run=true
    while true; do
        if [ "$first_run" = true ]; then
            first_run=false
            display_status false
        else
            display_status true
        fi

        if [ $? -eq 0 ]; then
            # Get final conclusion
            local final_status
            final_status=$(gh run list --repo "$REPO" --workflow=guix-build.yml --branch "$BRANCH" --limit 1 --json conclusion --jq '.[0].conclusion')

            echo ""
            if [ "$final_status" = "success" ]; then
                echo -e "${GREEN}✓ Workflow completed successfully!${NC}"

                # Ask if user wants to download artifacts
                echo ""
                echo -e "${BLUE}Download build artifacts? [y/N]${NC}"
                read -r -t 10 response || response="n"

                if [[ "$response" =~ ^[Yy]$ ]]; then
                    local run_id
                    run_id=$(gh run list --repo "$REPO" --workflow=guix-build.yml --branch "$BRANCH" --limit 1 --json databaseId --jq '.[0].databaseId')

                    echo -e "${BLUE}Downloading artifacts...${NC}"
                    gh run download "$run_id" --repo "$REPO" --dir "./guix-build-artifacts"
                    echo -e "${GREEN}✓ Artifacts downloaded to ./guix-build-artifacts${NC}"
                fi
            else
                echo -e "${RED}✗ Workflow failed with status: ${final_status}${NC}"
                echo -e "${BLUE}View logs with:${NC}"
                local run_id
                run_id=$(gh run list --repo "$REPO" --workflow=guix-build.yml --branch "$BRANCH" --limit 1 --json databaseId --jq '.[0].databaseId')
                echo "  gh run view $run_id --repo $REPO --log"
            fi
            break
        fi

        sleep "$INTERVAL"
    done
else
    display_status false
fi
