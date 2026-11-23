# EMILY-LOG — server × Emily language

> Everything I do with **Emily** (https://github.com/Julia-b-work/emily-language) on this server.
> Started: 2026-10-16 · Kept by: the AI admin · Format: newest entries at the bottom.

## Purpose

Use Emily (statically typed Lisp → JSON/YAML/TOML) as the single source of truth for the
server's YAML configuration, replacing hand-edited docker-compose / homepage YAML files.

## Session log

### 2026-10-16 — first live configs generated & applied

6. **Authored** the full set (all import `lib.em`):
   - `arr-stack.em` → arr-stack compose (8 services) ✅ applied
   - `homepage-compose.em` → homepage + glances compose ✅ applied
   - `homepage-settings.em`, `homepage-services.em`, `homepage-bookmarks.em` ✅ applied
   - `regenerate.sh [--apply]` — generates, validates compose syntax, diffs, applies.
7. **Bugs I made & fixed (good Emily lessons):**
   - homepage-bookmarks first draft produced `Streaming:` as a plain map instead of the
     `- Streaming:` list-form homepage expects — records are maps, lists are `[...]`.
     Fixed to `[{:Julia [{:Streaming [...]} {:Requests [...]}]}]`.
   - A `[...]` element written as a bare `:Requests` keyword instead of a record
     `{:Requests [...]}` — keywords are record keys, not expressions.
   - First homepage-services draft contained a nonsense `fold`/`range?` experiment
     (functions I invented) — deleted; Emily has no `range` builtin or list indexing.
8. **First live fix through the pipeline:** glances was crash-looping
   (`--process-minimal` is not a valid glances flag). Fixed the flag in
   `homepage-compose.em` → `regenerate.sh --apply` → container healthy. Source of truth
   works as intended.
9. Applying generated compose files did **not** recreate any running container
   (compose resolved the same spec: env maps == env lists, quotes are cosmetic).
10. Local git repo initialized in `/data/emily-config` (commit 7ca6966) — never pushed:
    contains no secrets by policy (see below), but keep it local anyway.
11. Quirk noted: YAML quoting (`"arr"`, `"8080:8080"`) is harmless; comments in YAML are
    lost (Emily can't emit them) — fine, comments live in the .em files.
12. **Not generated from Emily yet** (phase 2): widgets.yaml (needs the Jellyfin API key —
    secrets injection TBD), jellyfin/immich/pihole/caddy composes, Caddyfile.

## Decisions

- `/data/emily-config/` is a **local git repo** (NOT pushed anywhere — the generated
  configs contain credentials; Emily sources themselves contain none — see "Secrets").
- Regeneration flow: `regenerate.sh` → `emily --format yaml` → `generated/` → validate
  (`docker compose config -q`) → diff → apply only with `--apply` flag.
- Not yet generated from Emily (phase 2): jellyfin/immich/pihole/caddy composes,
  Caddyfile (Emily can't emit text; Caddy JSON config is the path when we get there),
  systemd units.

## Secrets policy

- Emily sources in `/data/emily-config/*.em` contain **no passwords** (they're about
  structure: images, volumes, ports, labels).
- Anything needing a secret (widgets.yaml has the Jellyfin API key) is injected by
  `regenerate.sh`, never committed into the `.em` files. If this changes, the log must
  say so.

## Open questions / ideas for Julia

- v2 roadmap mentions static types, macros, ADTs — when they land, the config could get
  compile-time schema checks (e.g. "every service must have :ports").
- Possible: a `check.em` that validates config invariants (all ports unique, etc.) —
  Emily can't `assert` yet, but `(if ...)` + intentional errors could approximate it.

### 2026-10-16 (evening) — Emily v2: one registry rules them all

14. **services.em** — canonical service registry (16 services with key/name/host/port/url/
    icon/desc/group/routing/monitor). Individual `def`s (jellyfin-svc etc.) + a flat
    `services` list + group lists.
15. **caddy.em** — folds the registry into the COMPLETE Caddy JSON config (routes per
    service, HA header hack, cockpit TLS skip, catch-all 302 to server.home). Caddy container
    now runs `caddy run --config /etc/caddy/Caddyfile.json` (Caddyfile retired).
    Bugs found & fixed by testing:
    - headers handler: ops must nest under `:request` (top-level `set`/`delete` rejected)
    - deleting X-Forwarded-* BEFORE reverse_proxy is useless (proxy re-adds them) — must be
      `reverse_proxy.headers.request.Delete` (capitalized JSON fields!)
    - server.home wasn't in the registry → catch-all redirect loop (added homepage-svc)
16. **tools.em** — new stack: Vaultwarden + Uptime Kuma + Dozzle. Secret ADMIN_TOKEN comes
    from the stack `.env` (compose interpolation), NOT from Emily sources (secrets policy).
    Emily limitation discovered: `docker compose -f <generated> config` resolves .env from
    the compose file's dir — validate from the target dir or ignore the warning.
17. **monitors.em** + **kuma-sync.sh** — Emily generates monitors.json; script drives Kuma's
    Socket.IO API from inside the container. Kuma API facts learned the hard way:
    - no REST — Socket.IO only; initial admin via `emit("setup", user, pass)`
    - `getMonitorList` callback carries no data; the list arrives on the `monitorList`
      EVENT (object map keyed by id, not array!)
    - monitor `notificationIDList` is an OBJECT map {id:true}, not an array
      (array → `Object.keys` → "0" → FK violation on monitor_notification)
    - notification beans wrap config as a stringified JSON `config` field
    - ntfy server URL field is `ntfyserverurl` (all lowercase!)
    - `editMonitor` takes the FULL monitor object
    - never emit an event that expects a callback without one — it crashes the kuma process
18. **kuma-ntfy.sh** — ntfy notification (topic from /etc/ntfy-topic) attached to all
    monitors; verified end-to-end (test push received on ntfy.sh).
19. Homepage tiles + layout now come from the registry too (Tools group added: Vaultwarden,
    Uptime-Kuma, Dozzle) + uptime-kuma widget in widgets.yaml.
20. regenerate.sh now handles 7 targets incl. caddy.json (caddy validate via throwaway
    container) and reloads Caddy + homepage on apply.

### 2026-10-17 — widgets + invariants

21. **widgets.em** — the last hand-edited YAML is now generated. The Jellyfin API key is
    injected by regenerate.sh from jellyfin.db at regen time (secrets stay out of sources).
22. **Invariant checker** — regenerate.sh now fails on duplicate published ports across all
    generated compose files (python + yaml scan). First line of defense until Emily gets
    real types.
23. Remaining Emily opportunities (roadmap): jellyfin/immich/pihole composes, registry →
    docs generation, GitHub showcase repo + issues from EMILY-FEEDBACK.md.

### 2026-11-16 — v0.2.0 upgrade (type annotation syntax)

24. **Upgraded Emily 0.1.4 → 0.2.0** (type annotation syntax, src/types.rs). cargo test
    green (parser/eval/types suites), acceptance tests 7/7. Binary rebuilt + installed
    (/usr/local/bin/emily; old saved as /usr/local/bin/emily.0.1.4.bak).
25. **Regenerated all 8 targets with 0.2.0: ZERO drift** — byte-identical compose/YAML/
    Caddyfile.json. The new parser/eval is fully backward-compatible with the live configs.
26. examples/typed.em compiles (first typed config example on the server).

### 2026-11-16 (evening) — full config-as-code completion

27. **Type annotations on the live registry** — services.em now uses 0.2.0 syntax:
    `(def jellyfin-svc : Service {...})` for all 16 services + `(List Service)` on the
    group lists. Evaluator ignores them (as documented) — regenerate = zero drift.
28. **jellyfin.em + pihole.em** — the last two hand-managed composes we own are now
    generated (10 targets total). Immich stays hand-managed BY DECISION: upstream
    churns image digests per release + heavy ${ENV} interpolation; converting adds
    sync work without benefit.
29. **Secrets policy upheld**: pihole WEBPASSWORD emitted as ${PIHOLE_WEBPASSWORD},
    real value in /data/docker/pihole/.env (600) — same pattern as tools ADMIN_TOKEN.
30. **regenerate.sh fixes**: apply loop now covers jellyfin + pihole stacks; invariant
    port-collision check now scans ALL generated yaml (was only homepage-compose due to
    a glob bug), parses ip:host:container + /tcp|udp properly, and skips non-dict YAML.
    Two false positives (same port tcp+udp) fixed in the parser.
