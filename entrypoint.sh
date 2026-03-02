#!/bin/sh
set -e

CONFIG_SRC="/data/config.toml"
CONFIG_RUNTIME="/tmp/runtime-config.toml"

# Copy base config to runtime location (ephemeral — not on bind mount)
if [ -f "$CONFIG_SRC" ]; then
    cp "$CONFIG_SRC" "$CONFIG_RUNTIME"
else
    cat > "$CONFIG_RUNTIME" <<EOF
home_dir = "/data"
data_dir = "/data/db"
log_level = "info"
api_listen = "0.0.0.0:4200"

[memory]
decay_rate = 0.05
EOF
fi

# Inject api_key from environment variable (never stored on disk)
if [ -n "$OPENFANG_API_KEY" ]; then
    # Validate hex-only (defense-in-depth against sed injection)
    case "$OPENFANG_API_KEY" in
        *[!0-9a-fA-F]*) echo "ERROR: OPENFANG_API_KEY must be hex-only" >&2; exit 1 ;;
    esac
    if grep -q '^api_key' "$CONFIG_RUNTIME"; then
        sed -i "s/^api_key.*/api_key = \"$OPENFANG_API_KEY\"/" "$CONFIG_RUNTIME"
    else
        sed -i "/^api_listen/a api_key = \"$OPENFANG_API_KEY\"" "$CONFIG_RUNTIME"
    fi
else
    echo "WARNING: OPENFANG_API_KEY not set. API will reject non-loopback connections." >&2
fi

exec openfang --config "$CONFIG_RUNTIME" "$@"
