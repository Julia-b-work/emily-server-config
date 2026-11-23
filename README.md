# emily-server-config

The complete configuration of my home server, written in [Emily](https://github.com/Julia-b-work/emily-language), a statically-typed Lisp I'm building.

## The idea

All of these are generated from a single source of truth: [`services.em`](services.em),
a list of 16 service records:

```
services.em ──┬──▶ caddy.em          → Caddyfile.json   (reverse proxy, every *.home route)
              ├──▶ homepage-*.em     → homepage dashboard (settings, services, bookmarks, widgets)
              ├──▶ monitors.em       → Uptime Kuma monitors (15, one per watched service)
              ├──▶ arr-stack.em      → docker-compose.yml (qBittorrent, Prowlarr, Radarr,
              │                         Sonarr, Lidarr, Bazarr, Seerr, FlareSolverr)
              ├──▶ tools.em          → docker-compose.yml (Vaultwarden, Uptime Kuma, Dozzle)
              ├──▶ jellyfin.em       → docker-compose.yml (Jellyfin, VAAPI, SSD config/cache)
              └──▶ pihole.em         → docker-compose.yml (Pi-hole DNS + ad-blocking)
```

Adding a service to the server is a **one-line change**: a new record in `services.em`,
then `./regenerate.sh --apply`. The proxy route, the dashboard tile, the monitor, and
(where applicable) the compose file all regenerate from that one line.

## Who actually runs this

An AI agent. Since October 2026 I've kept a persistent AI admin on the server, and it
operates this entire config through Emily: it writes the `.em` sources, runs
`./regenerate.sh --apply`, debugs the pipeline when something breaks (several of the
crashes it caused and fixed are in [`EMILY-LOG.md`](EMILY-LOG.md)), and keeps that log
as its own running diary (the log is the agent's words, not mine).

This is deliberate. The point of Emily is config that's *generated and checked*, and
an agent is the most demanding consumer of that: its production use is where the
language's feedback came from, string record keys, list indexing, deep merge, env
access, all filed as issues on the
[language repo](https://github.com/Julia-b-work/emily-language/issues). I own the
server, the language, and the secrets policy; the agent owns the day-to-day config
work, under the rule that nothing secret ever enters the sources (see below).

## Example

```clojure
;; one service record in services.em
(def jellyfin-svc : Service {:key "jellyfin" :name "Jellyfin" :host "jellyfin" :port 8096
  :url "http://jellyfin.home" :icon "jellyfin.png" :desc "Movies, TV, anime & music"
  :group "Media" :routing "proxy" :monitor true})
```

and the monitor pipeline that folds the registry into Uptime Kuma:

```clojure
;; monitors.em — 19 lines, generates all 15 monitors
(import "services.em")

(def to-monitor (fn (s)
  {:name s.name :url s.url :type "http" :interval 60 :retryInterval 60
   :maxretries 0 :maxredirects 10 :timeout 48 :method "GET"
   :accepted_statuscodes ["200-299"]}))

(fold services [] (fn (acc s)
  (if s.monitor (append acc (to-monitor s)) acc)))
```

Since Emily 0.2.0 the registry is type-annotated (`: Service`, `: (List Service)`);
annotations parse today, the type checker arrives next.

## Regenerating

```bash
emily --format json services.em          # see the registry as JSON
emily --format json monitors.em          # see the generated monitors
./regenerate.sh                          # generate + validate + diff
./regenerate.sh --apply                  # apply to live configs + reload services
```

Output formats: `json` (default), `yaml`, `toml` (`--format`).

## Secrets policy

No passwords live in the `.em` sources. Everything sensitive is injected at regen
time or runtime, never committed:

- **Regen time:** `regenerate.sh` fills six placeholders from live, git-ignored
  sources: the Jellyfin API key (`jellyfin.db`), the Sonarr and Radarr keys
  (`config.xml`), the Pi-hole web password (`.env`), and the qBittorrent and Kuma
  passwords (`/data/emily-config/.secrets`).
- **Runtime:** compose interpolation supplies `${VAULTWARDEN_ADMIN_TOKEN}` and
  `${PIHOLE_WEBPASSWORD}` from each stack's git-ignored `.env`, and the Kuma
  scripts expect `KUMA_PASSWORD` in the environment.

`.gitignore` covers `.secrets`, `.env` files, keys, certificates, and credential
dumps (`config.xml`, `*.db`).

**Addresses:** LAN IPs and internal domains shown in these files are placeholders
(`192.168.1.x`, `server.home`, `server.local`) — the real values live only on the
server.

## Layout

| File | Generates |
|---|---|
| `services.em` | the registry (imported by everything below) |
| `lib.em` | shared helpers (`tz`, `PUID/PGID`, `lscr` skeleton, `pmap`) |
| `caddy.em` | `/data/docker/caddy/Caddyfile.json` |
| `monitors.em` | Uptime Kuma monitors (via `kuma-sync.sh`) |
| `homepage-*.em`, `widgets.em` | homepage dashboard configs |
| `arr-stack.em`, `tools.em`, `jellyfin.em`, `pihole.em` | docker compose files |
| `regenerate.sh` | the build/validate/apply pipeline (+ port-collision invariant check) |
| `EMILY-LOG.md` | the running history of this config since day one |

## More

- The language: https://github.com/Julia-b-work/emily-language
