#!/bin/bash
# regenerate.sh [--apply] — regenerate server config files from Emily sources.
# Without --apply: generate + validate + show diffs only.
set -euo pipefail
SRC=/data/emily-config
GEN=$SRC/generated
mkdir -p "$GEN"

# src.em : target path : type (compose|yaml|caddyjson)
TARGETS=(
  "$SRC/arr-stack.em:/data/docker/arr-stack/compose.yml:compose"
  "$SRC/tools.em:/data/docker/tools/docker-compose.yml:compose"
  "$SRC/jellyfin.em:/data/docker/jellyfin/compose.yml:compose"
  "$SRC/pihole.em:/data/docker/pihole/compose.yml:compose"
  "$SRC/homepage-compose.em:/data/docker/homepage/docker-compose.yml:compose"
  "$SRC/homepage-settings.em:/data/docker/homepage/config/settings.yaml:yaml"
  "$SRC/homepage-services.em:/data/docker/homepage/config/services.yaml:yaml"
  "$SRC/homepage-bookmarks.em:/data/docker/homepage/config/bookmarks.yaml:yaml"
  "$SRC/widgets.em:/data/docker/homepage/config/widgets.yaml:yaml"
  "$SRC/caddy.em:/data/docker/caddy/Caddyfile.json:caddyjson"
)

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1
CHANGED_ANY=0
JFKEY=$(sqlite3 /srv/jellyfin-config/data/jellyfin.db "SELECT AccessToken FROM ApiKeys LIMIT 1" 2>/dev/null || true)
SONARR_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' /data/docker/arr-stack/sonarr/config.xml 2>/dev/null || true)
RADARR_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' /data/docker/arr-stack/radarr/config.xml 2>/dev/null || true)
[ -f /data/docker/pihole/.env ] && . /data/docker/pihole/.env
[ -f "$SRC/.secrets" ] && . "$SRC/.secrets"

for entry in "${TARGETS[@]}"; do
  src="${entry%%:*}"; rest="${entry#*:}"; dest="${rest%%:*}"; kind="${rest##*:}"
  name=$(basename "$src" .em)
  gen="$GEN/$name.yaml"
  [ "$kind" = "caddyjson" ] && gen="$GEN/$name.json"

  echo "== $name.em -> $dest"
  fmt="yaml"; [ "$kind" = "caddyjson" ] && fmt="json"
  if ! emily --format "$fmt" "$src" > "$gen" 2>/tmp/emily-err; then
    echo "   EMILY ERROR:"; cat /tmp/emily-err; exit 1
  fi

  if [ "$name" = "widgets" ]; then
    sed -i "s/JFKEY_PLACEHOLDER/$JFKEY/; s/SONARRKEY_PLACEHOLDER/$SONARR_KEY/; s/RADARRKEY_PLACEHOLDER/$RADARR_KEY/; s/PIHOLEKEY_PLACEHOLDER/${PIHOLE_WEBPASSWORD:-}/; s/QBPASS_PLACEHOLDER/${QBPASS:-}/; s/KUMAPASS_PLACEHOLDER/${KUMAPASS:-}/" "$gen"
  fi

  if [ "$kind" = "compose" ]; then
    if ! (cd "$(dirname "$dest")" && docker compose -f "$gen" config -q 2>/tmp/compose-err); then
      echo "   COMPOSE VALIDATION FAILED:"; cat /tmp/compose-err; exit 1
    fi
    echo "   compose validation: OK"
  fi
  if [ "$kind" = "caddyjson" ]; then
    if ! docker run --rm -v "$(readlink -f "$gen"):/tmp/cfg.json:ro" caddy:latest caddy validate --config /tmp/cfg.json >/dev/null 2>&1; then
      echo "   CADDY VALIDATION FAILED"; exit 1
    fi
    echo "   caddy validation: OK"
  fi

  if [ -f "$dest" ] && diff -q "$gen" "$dest" >/dev/null 2>&1; then
    echo "   no changes"
  else
    CHANGED_ANY=1
    echo "   CHANGED (diff):"
    diff -u "$dest" "$gen" 2>/dev/null | head -20 || true
    if [ "$APPLY" = "1" ]; then
      cp "$gen" "$dest"
      echo "   APPLIED"
    fi
  fi
done

# invariant check: no duplicate published ports across generated compose files
python3 - "$GEN" <<'PYEOF'
import sys, glob
import yaml as _yaml
dup = {}
for f in glob.glob(sys.argv[1] + "/*.yaml"):
    try:
        d = _yaml.safe_load(open(f))
    except Exception:
        continue
    if not isinstance(d, dict):
        continue
    for name, svc in (d.get("services") or {}).items():
        for p in svc.get("ports") or []:
            s = str(p)
            proto = s.rsplit("/", 1)[-1] if "/" in s else "tcp"
            s = s.split("/")[0]
            parts = s.split(":")
            if len(parts) == 3:        # ip:host:container
                ip, hport = parts[0], parts[1]
            elif len(parts) == 2:      # host:container
                ip, hport = "", parts[0]
            else:
                continue
            if not hport.isdigit():
                continue
            dup.setdefault((ip, hport, proto), []).append(f"{f.split('/')[-1]}:{name}")
bad = {k: v for k, v in dup.items() if len(v) > 1}
if bad:
    print("PORT COLLISION:", bad); sys.exit(1)
print("invariants OK (no duplicate ports)")
PYEOF

if [ "$APPLY" = "1" ]; then
  (cd /data/docker/arr-stack && docker compose up -d 2>&1 | tail -1)
  (cd /data/docker/tools && docker compose up -d 2>&1 | tail -1)
  (cd /data/docker/jellyfin && docker compose up -d 2>&1 | tail -1)
  (cd /data/docker/pihole && docker compose up -d 2>&1 | tail -1)
  (cd /data/docker/homepage && docker compose up -d 2>&1 | tail -1)
  if [ "$CHANGED_ANY" = "1" ]; then
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile.json >/dev/null 2>&1 && echo "caddy reloaded"
    docker restart homepage >/dev/null 2>&1 && echo "homepage restarted"
  fi
  /usr/local/sbin/notify.sh "🧬 Server configs regenerated from Emily sources."
  echo "applied."
fi
