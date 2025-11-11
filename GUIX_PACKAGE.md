# Janus Gateway Guix Package

This directory contains a Guix package definition for Janus Gateway.

## What is GNU Guix?

[GNU Guix](https://guix.gnu.org/) is a transactional package manager and an advanced distribution of the GNU system. It provides reproducible, declarative, and functional package management.

## Package Files

- `janus.scm` - The Guix package definition for Janus Gateway
- `.github/workflows/guix-build.yml` - GitHub Actions workflow for automated building with Guix

## Building Locally with Guix

If you have Guix installed on your system, you can build Janus Gateway using:

```bash
# Add the current directory to GUIX_PACKAGE_PATH
export GUIX_PACKAGE_PATH="$(pwd):$GUIX_PACKAGE_PATH"

# Build the package
guix build -f janus.scm
```

## Installing with Guix

To install Janus Gateway into your Guix profile:

```bash
export GUIX_PACKAGE_PATH="$(pwd):$GUIX_PACKAGE_PATH"
guix package -f janus.scm
```

## Development Environment

To create a development environment with all dependencies:

```bash
guix shell -f janus.scm
```

Or for development with additional tools:

```bash
guix shell -f janus.scm --with-debug-info -- bash
```

## GitHub Actions CI

The GitHub Actions workflow (`.github/workflows/guix-build.yml`) automatically builds the package on:
- Pushes to the master branch
- Pushes to branches starting with `claude/`
- Pull requests to master
- Manual workflow dispatch

The workflow:
1. Installs Guix with the main Guix channel and Nonguix channel
2. Configures substitute servers for faster builds
3. Builds Janus using the package definition
4. Caches build artifacts for faster subsequent runs
5. Shows build logs on failure

## Package Dependencies

The Guix package includes the following dependencies:

### Build Dependencies
- autoconf
- automake
- libtool
- pkg-config

### Runtime Dependencies
- glib
- jansson
- libconfig
- libnice
- libsrtp
- libmicrohttpd
- openssl
- opus
- libogg
- curl
- zlib
- usrsctp (for DataChannels)
- libwebsockets (for WebSocket support)
- sofia-sip (for SIP plugin)

## Customizing the Build

You can modify `janus.scm` to:
- Change build flags
- Add or remove optional dependencies
- Customize installation paths
- Add additional build phases

## Troubleshooting

### Build fails with missing dependencies

Make sure your Guix channels are up to date:

```bash
guix pull
```

### Package not found

Ensure `GUIX_PACKAGE_PATH` includes the Janus Gateway directory:

```bash
export GUIX_PACKAGE_PATH="/path/to/janus-gateway:$GUIX_PACKAGE_PATH"
```

### View build logs

If the build fails, view the logs:

```bash
guix build -f janus.scm --log-file
```

## Contributing

To contribute improvements to the Guix package:

1. Test your changes locally with `guix build -f janus.scm`
2. Ensure the package builds successfully in the CI pipeline
3. Submit a pull request with your changes

## Resources

- [Guix Manual](https://guix.gnu.org/manual/)
- [Guix Package Guidelines](https://guix.gnu.org/manual/en/html_node/Packaging-Guidelines.html)
- [Janus Gateway Documentation](https://janus.conf.meetecho.com/docs/)
