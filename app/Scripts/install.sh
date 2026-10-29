#!/usr/bin/env bash
# Builds Citrus.app, installs it to ~/Applications, and adds a `citrus` command
# to your PATH so you can launch the app from any terminal.
#
# Override the install locations with:
#   CITRUS_APP_DIR  (default: ~/Applications)
#   CITRUS_BIN_DIR  (default: ~/.local/bin)
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Citrus"
APP_DIR="${CITRUS_APP_DIR:-$HOME/Applications}"
BIN_DIR="${CITRUS_BIN_DIR:-$HOME/.local/bin}"

./Scripts/build-app.sh

echo "Installing ${APP_NAME}.app to ${APP_DIR}..."
mkdir -p "$APP_DIR"
rm -rf "${APP_DIR}/${APP_NAME}.app"
cp -R ".build/${APP_NAME}.app" "${APP_DIR}/"

echo "Installing citrus command to ${BIN_DIR}..."
mkdir -p "$BIN_DIR"
cat > "${BIN_DIR}/citrus" <<SH
#!/usr/bin/env bash
# Launches Citrus (installed by citrus/app/Scripts/install.sh).
exec open "${APP_DIR}/${APP_NAME}.app"
SH
chmod +x "${BIN_DIR}/citrus"

case ":$PATH:" in
  *":${BIN_DIR}:"*) echo "Done. Run: citrus" ;;
  *) echo "Done. Add ${BIN_DIR} to your PATH, then run: citrus" ;;
esac
