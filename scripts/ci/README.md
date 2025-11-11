# Guix Build CI Scripts

This directory contains scripts to help manage and monitor Guix build workflows for Janus Gateway via GitHub Actions.

## Overview

The Guix build workflow provides reproducible builds of Janus Gateway using the GNU Guix package manager. These scripts make it easy to trigger builds and monitor their progress without leaving your terminal.

## Scripts

### `trigger-guix-build.sh`

Manually trigger a Guix build workflow for a specific branch.

**Usage:**
```bash
./scripts/ci/trigger-guix-build.sh [OPTIONS]

OPTIONS:
    --branch BRANCH    Branch to build (default: claude/create-janus-guix-package-011CV22VWjyzoXGBpR6A6R6T)
    --wait             Wait for the workflow to complete
    --help             Display help message
```

**Examples:**
```bash
# Trigger build for current branch
./scripts/ci/trigger-guix-build.sh --branch master

# Trigger build and wait for completion
./scripts/ci/trigger-guix-build.sh --branch master --wait

# Use with custom repository
REPO=myuser/janus-gateway ./scripts/ci/trigger-guix-build.sh --wait
```

### `monitor-guix-build.sh`

Monitor the status of Guix build workflows with real-time updates.

**Usage:**
```bash
./scripts/ci/monitor-guix-build.sh [OPTIONS]

OPTIONS:
    --branch BRANCH      Branch to monitor (default: claude/create-janus-guix-package-011CV22VWjyzoXGBpR6A6R6T)
    --watch              Continuously watch until completion
    --interval SECONDS   Refresh interval in watch mode (default: 30)
    --help               Display help message
```

**Examples:**
```bash
# Check current status
./scripts/ci/monitor-guix-build.sh --branch master

# Watch continuously (refresh every 30s)
./scripts/ci/monitor-guix-build.sh --watch

# Watch with custom refresh interval
./scripts/ci/monitor-guix-build.sh --watch --interval 15

# Monitor specific repository
REPO=myuser/janus-gateway ./scripts/ci/monitor-guix-build.sh --branch master --watch
```

## Prerequisites

Both scripts require the following tools to be installed:

1. **GitHub CLI (`gh`)** - [Installation guide](https://cli.github.com/)
   ```bash
   # Ubuntu/Debian
   sudo apt install gh

   # macOS
   brew install gh

   # Or download from https://cli.github.com/
   ```

2. **jq** - JSON processor (required for monitor script)
   ```bash
   # Ubuntu/Debian
   sudo apt install jq

   # macOS
   brew install jq
   ```

3. **Authentication** - You must be authenticated with GitHub CLI:
   ```bash
   gh auth login
   ```

## Workflow Overview

The Guix build workflow (`.github/workflows/guix-build.yml`) performs the following steps:

1. **Checkout** - Retrieves the Janus Gateway source code
2. **Cache Restore** - Restores previously cached Guix store for faster builds
3. **Guix Installation** - Sets up Guix with main and Nonguix channels
4. **Configuration** - Configures substitute servers for binary downloads
5. **Build** - Compiles Janus Gateway using the `janus.scm` package definition
6. **Artifacts** - On success, caches the Guix store for future builds

## Common Workflows

### Quick Status Check

Check the current status of a build:
```bash
./scripts/ci/monitor-guix-build.sh --branch master
```

### Trigger and Monitor

Trigger a new build and watch it complete:
```bash
# In one terminal
./scripts/ci/trigger-guix-build.sh --branch master

# In another terminal (or use --wait with trigger)
./scripts/ci/monitor-guix-build.sh --branch master --watch
```

### Download Build Artifacts

After a successful build, the monitor script will prompt you to download artifacts. You can also download manually:
```bash
# Get the run ID
RUN_ID=$(gh run list --repo ifitzpat/janus-gateway --workflow=guix-build.yml --branch master --limit 1 --json databaseId --jq '.[0].databaseId')

# Download artifacts
gh run download $RUN_ID --repo ifitzpat/janus-gateway --dir ./guix-artifacts
```

## Environment Variables

Both scripts support the following environment variables:

- `REPO` - Repository in format `owner/repo` (default: `ifitzpat/janus-gateway`)
- `GITHUB_TOKEN` - GitHub token for authentication (usually not needed if using `gh auth login`)

**Example:**
```bash
export REPO="myuser/janus-gateway"
./scripts/ci/trigger-guix-build.sh --branch feature-branch
```

## Troubleshooting

### Authentication Errors

If you see authentication errors:
```bash
gh auth status  # Check current auth status
gh auth login   # Re-authenticate if needed
```

### Workflow Not Found

If the workflow is not found:
- Ensure the `.github/workflows/guix-build.yml` file exists in your branch
- Check that you've pushed your branch to GitHub
- Verify the repository name is correct with `REPO` environment variable

### Script Permissions

Make scripts executable:
```bash
chmod +x scripts/ci/*.sh
```

### Branch Not Found

If monitoring shows "No workflow runs found":
- Ensure the branch has been pushed to GitHub
- Trigger a build first using the trigger script
- Check that the branch name is spelled correctly

## Integration with Local Development

### Local Guix Builds

If you have Guix installed locally, you can build without CI:
```bash
cd /path/to/janus-gateway
export GUIX_PACKAGE_PATH="$(pwd):$GUIX_PACKAGE_PATH"
guix build -f janus.scm
```

### Testing Before Push

Test your package definition locally before triggering CI:
```bash
# Build locally
guix build -f janus.scm

# If successful, commit and push
git add janus.scm
git commit -m "Update Guix package definition"
git push

# Trigger CI build
./scripts/ci/trigger-guix-build.sh --branch $(git branch --show-current) --wait
```

## Features

### Color-Coded Output

Both scripts use color-coded output for easy reading:
- 🔵 **Blue** - Informational messages
- 🟢 **Green** - Success messages
- 🟡 **Yellow** - Warnings and in-progress states
- 🔴 **Red** - Errors and failures
- 🔷 **Cyan** - Section headers and important details

### Real-Time Updates

The monitor script provides:
- Live job status updates
- Duration tracking
- Automatic completion detection
- Artifact download prompts

### Flexible Configuration

Both scripts support:
- Custom branch selection
- Custom repositories
- Configurable refresh intervals
- Environment variable overrides

## Related Documentation

- [Guix Package Documentation](../../GUIX_PACKAGE.md) - Complete guide to the Guix package
- [GitHub Actions Workflow](../../.github/workflows/guix-build.yml) - The CI workflow definition
- [Janus Gateway Documentation](../../README.md) - Main project documentation
- [GNU Guix Manual](https://guix.gnu.org/manual/) - Official Guix documentation

## Contributing

To improve these scripts:

1. Test changes locally first
2. Ensure scripts remain POSIX-compliant where possible
3. Update this README with any new features
4. Submit a pull request with clear descriptions

## License

These scripts are part of the Janus Gateway project and follow the same license (GPLv3).
