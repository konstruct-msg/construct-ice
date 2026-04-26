# Construct ICE Relay Deployment

## Quick deploy

```bash
# Cross-compile for Linux (install target first if needed)
rustup target add x86_64-unknown-linux-gnu

# Deploy to relay server
cd deploy
chmod +x deploy.sh
./deploy.sh root@45.135.233.5   # SPB relay
```

The script:
1. Builds a release binary for `x86_64-unknown-linux-gnu`
2. Uploads it to `/usr/local/bin/construct-ice`
3. Creates a `construct` system user
4. Installs and enables the systemd unit with `Restart=always`

## Manual steps (if deploy.sh can't run)

```bash
# On the relay server:
scp construct_ice root@host:/usr/local/bin/construct-ice
scp construct-ice.service root@host:/etc/systemd/system/
ssh root@host systemctl daemon-reload
ssh root@host systemctl enable --now construct-ice
```

## Check status

```bash
ssh root@45.135.233.5 systemctl status construct-ice
ssh root@45.135.233.5 journalctl -u construct-ice -n 50 --no-pager
```

## Relay configuration

Edit `/etc/construct-ice/env` on the server to pass environment variables:

```
RUST_LOG=info
# Add relay-specific config vars here
```

## Multiple relays

Run the same deploy for each relay host:
```bash
./deploy.sh root@45.135.233.5   # SPB
./deploy.sh root@<jp-relay-ip>  # Japan (future)
```
