#!/usr/bin/env bash
# Deploy construct-ice relay to a remote server
# Usage: ./deploy.sh <user@host>
set -euo pipefail

REMOTE="${1:?Usage: $0 user@host}"
BINARY="./target/x86_64-unknown-linux-gnu/release/construct_ice"
REMOTE_BIN="/usr/local/bin/construct-ice"
SERVICE_SRC="$(dirname "$0")/construct-ice.service"

echo "==> Building release binary..."
cargo build --release --target x86_64-unknown-linux-gnu

echo "==> Uploading binary to $REMOTE..."
scp "$BINARY" "$REMOTE:/tmp/construct-ice.new"

echo "==> Installing..."
ssh "$REMOTE" bash -s <<'ENDSSH'
set -euo pipefail
install -m 755 /tmp/construct-ice.new /usr/local/bin/construct-ice
rm /tmp/construct-ice.new

# Create service user if it doesn't exist
id construct &>/dev/null || useradd --system --no-create-home --shell /usr/sbin/nologin construct

# Runtime directory
mkdir -p /var/lib/construct-ice
chown construct:construct /var/lib/construct-ice

# Config dir with placeholder env file
mkdir -p /etc/construct-ice
if [ ! -f /etc/construct-ice/env ]; then
cat > /etc/construct-ice/env <<'EOF'
# Construct ICE relay environment
RUST_LOG=info
EOF
fi
ENDSSH

echo "==> Uploading systemd unit..."
scp "$SERVICE_SRC" "$REMOTE:/tmp/construct-ice.service"
ssh "$REMOTE" bash -s <<'ENDSSH'
install -m 644 /tmp/construct-ice.service /etc/systemd/system/construct-ice.service
rm /tmp/construct-ice.service
systemctl daemon-reload
systemctl enable construct-ice
systemctl restart construct-ice
sleep 2
systemctl status construct-ice --no-pager
ENDSSH

echo "==> Done. Relay is running on $REMOTE"
