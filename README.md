# emily-server-config

The complete configuration of my home server, written in [Emily](https://github.com/Julia-b-work/emily-language)
— a statically-typed Lisp I'm building. One registry drives everything.

## The idea

All of these are generated from a single source of truth — [`services.em`](services.em),
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

Since Emily 0.2.0 the registry is type-annotated (`: Service`, `: (List Service)`) —
annotations parse today; the type checker arrives next.

## Regenerating

```bash
emily --format json services.em          # see the registry as JSON
emily --format json monitors.em          # see the generated monitors
./regenerate.sh                          # generate + validate + diff
./regenerate.sh --apply                  # apply to live configs + reload services
```

Output formats: `json` (default), `yaml`, `toml` (`--format`).

## Secrets policy

No passwords live in the `.em` sources. Secrets are injected at runtime from each
stack's git-ignored `.env` (e.g. `WEBPASSWORD "${PIHOLE_WEBPASSWORD}"`) or injected at
regen time (the Jellyfin API key in `widgets.em` is a placeholder filled from the
Jellyfin DB). The Kuma helper scripts expect `KUMA_PASSWORD` in the environment.

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
- The blog post about this setup: <link>
