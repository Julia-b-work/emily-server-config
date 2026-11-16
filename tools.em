;; tools.em — generates /data/docker/tools/docker-compose.yml
;; Vaultwarden (passwords) + Uptime Kuma (monitoring) + Dozzle (log viewer).
;; Secret ADMIN_TOKEN lives in the stack .env (never in Emily sources).
;; Host ports published so the tools are reachable away from home via Tailscale
;; (julia-server:<port> / 100.116.105.71:<port>). All three require login.
(import "lib.em")

{:name "tools"
 :services
 {:vaultwarden
  {:image "vaultwarden/server:latest"
   :container_name "vaultwarden"
   :environment {:TZ tz
                 :ADMIN_TOKEN "${VAULTWARDEN_ADMIN_TOKEN}"
                 :SIGNUPS_ALLOWED "true"}
   :volumes ["./vaultwarden:/data"]
   :ports ["8081:80"]
   :restart "unless-stopped"}
  :uptime-kuma
  {:image "louislam/uptime-kuma:1"
   :container_name "uptime-kuma"
   :dns ["192.168.15.90"]
   :volumes ["./uptime-kuma:/app/data"]
   :ports ["3001:3001"]
   :restart "unless-stopped"}
  :dozzle
  {:image "amir20/dozzle:latest"
   :container_name "dozzle"
   :volumes ["/var/run/docker.sock:/var/run/docker.sock:ro"
             "./dozzle-data/users.yaml:/data/users.yaml:ro"]
   :ports ["9999:8080"]
   :restart "unless-stopped"}}}
