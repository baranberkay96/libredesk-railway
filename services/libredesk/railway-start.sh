#!/bin/sh
# Start LibreDesk on Railway.
#
# 1. Check the variables. A bad value never stops the deploy (STANDARD 8.29):
#    a bad PORT falls back to 9000, an encryption key that is not 32
#    characters becomes a stable 32-character key derived from it, and a weak
#    system user password locks the System account with a random password.
# 2. Wait for Postgres, install the schema on an empty database (creating the
#    "System" admin with LIBREDESK_SYSTEM_USER_PASSWORD), run upgrades, and
#    replace the default http://localhost:9000 root URL with the Railway URL.
#    All of this happens before the HTTP port opens (STANDARD 8.37).
# 3. Apply a changed LIBREDESK_SYSTEM_USER_PASSWORD to an existing install.
# 4. exec libredesk on [::]:$PORT.
set -eu

DEFAULT_PORT=9000
STATE_DIR=/libredesk/uploads/.railway
FINGERPRINT_FILE=$STATE_DIR/system-password.sha256

log() { printf '%s railway-start: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

port=${PORT:-$DEFAULT_PORT}
case $port in ''|*[!0-9]*) log "PORT='$port' is not a number; using $DEFAULT_PORT"; port=$DEFAULT_PORT ;; esac
if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then log "PORT=$port is out of range; using $DEFAULT_PORT"; port=$DEFAULT_PORT; fi
export LIBREDESK_APP__SERVER__ADDRESS="[::]:$port"

key=${LIBREDESK_APP__ENCRYPTION_KEY:-}
if [ "${#key}" -ne 32 ]; then
  log "WARNING: LIBREDESK_APP__ENCRYPTION_KEY must be exactly 32 characters (has ${#key}); using a key derived from it." \
      "Set a 32-character key before you store inbox credentials, and never change it afterwards."
  LIBREDESK_APP__ENCRYPTION_KEY=$(printf '%s' "${key:-libredesk-railway}" | sha256sum | cut -c1-32)
  export LIBREDESK_APP__ENCRYPTION_KEY
fi

# LibreDesk's own rule: 10-72 characters with upper and lower case, a digit
# and a special character.
strong_password() {
  p=$1
  [ "${#p}" -ge 10 ] && [ "${#p}" -le 72 ] || return 1
  printf '%s' "$p" | grep -q '[A-Z]' || return 1
  printf '%s' "$p" | grep -q '[a-z]' || return 1
  printf '%s' "$p" | grep -q '[0-9]' || return 1
  printf '%s' "$p" | grep -q '[^A-Za-z0-9]' || return 1
}
password=${LIBREDESK_SYSTEM_USER_PASSWORD:-}
if strong_password "$password"; then
  password_ok=1
else
  password_ok=0
  log "WARNING: LIBREDESK_SYSTEM_USER_PASSWORD must be 10-72 characters with upper and lower case letters, a digit and a special character." \
      "An existing password is kept; a new install gets a random System password nobody knows." \
      "Set a valid value on the service and redeploy to log in."
fi
unset LIBREDESK_SYSTEM_USER_PASSWORD

export PGHOST="${LIBREDESK_DB__HOST:-}" PGPORT="${LIBREDESK_DB__PORT:-5432}" PGUSER="${LIBREDESK_DB__USER:-}" \
       PGPASSWORD="${LIBREDESK_DB__PASSWORD:-}" PGDATABASE="${LIBREDESK_DB__DATABASE:-}" PGCONNECT_TIMEOUT=5
attempt=0
until timeout 10 pg_isready -q; do
  attempt=$((attempt + 1))
  if [ "$attempt" -ge 120 ]; then
    log "ERROR: Postgres at $PGHOST:$PGPORT is not reachable after 10 minutes"
    exit 1
  fi
  [ "$attempt" -eq 1 ] && log "Waiting for Postgres at $PGHOST:$PGPORT"
  sleep 5
done

mkdir -p "$STATE_DIR"
chmod 0700 "$STATE_DIR"
fingerprint() { printf '%s:%s' "$LIBREDESK_APP__ENCRYPTION_KEY" "$1" | sha256sum | cut -d' ' -f1; }

installed=$(psql -tAc "SELECT to_regclass('public.settings') IS NOT NULL" 2>/dev/null || echo f)
if [ "$installed" != "t" ]; then
  log "Installing the database schema and the System admin account"
  if [ "$password_ok" = 1 ]; then
    LIBREDESK_SYSTEM_USER_PASSWORD=$password ./libredesk --install --idempotent-install --yes
    fingerprint "$password" > "$FINGERPRINT_FILE"
  else
    ./libredesk --install --idempotent-install --yes  # random System password
    rm -f "$FINGERPRINT_FILE"
  fi
fi

./libredesk --upgrade --yes

if [ "$password_ok" = 1 ] && [ "$(cat "$FINGERPRINT_FILE" 2>/dev/null || true)" != "$(fingerprint "$password")" ]; then
  # --set-system-user-password reads the new password from stdin and ends the
  # System user's sessions.
  if printf '%s\n' "$password" | ./libredesk --set-system-user-password >/dev/null 2>&1; then
    fingerprint "$password" > "$FINGERPRINT_FILE"
    log "System password changed to LIBREDESK_SYSTEM_USER_PASSWORD"
  else
    log "WARNING: could not apply LIBREDESK_SYSTEM_USER_PASSWORD; the old password stays"
  fi
fi
unset password

# Replace upstream's default root URL (used in links, the chat widget and
# OAuth callbacks) once; a value set later in Admin > General is kept.
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  url="https://$RAILWAY_PUBLIC_DOMAIN"
  psql -q -v ON_ERROR_STOP=1 -v url="$url" <<'SQL' || log "WARNING: could not set the root URL; set it under Admin > General"
UPDATE settings SET value = to_jsonb(:'url'::text), updated_at = NOW()
 WHERE key = 'app.root_url' AND value = '"http://localhost:9000"'::jsonb;
UPDATE settings SET value = to_jsonb(:'url'::text || '/favicon.ico'), updated_at = NOW()
 WHERE key = 'app.favicon_url' AND value = '"http://localhost:9000/favicon.ico"'::jsonb;
SQL
fi
unset PGPASSWORD

log "Starting LibreDesk on [::]:$port"
exec ./libredesk
