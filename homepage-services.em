;; homepage-services.em — generates /data/docker/homepage/config/services.yaml
;; Tiles now come from the canonical registry (services.em); only the grouping lives here.
(import "services.em")

(def tile (fn (s) {:href s.url :icon s.icon :description s.desc}))

[{:Media
  {:Jellyfin (tile jellyfin-svc)
   :Immich (tile immich-svc)
   :Home-Assistant (tile ha-svc)}}
 {:Requests
  {:Seerr (tile seerr-svc)
   :Radarr (tile radarr-svc)
   :Sonarr (tile sonarr-svc)
   :Lidarr (tile lidarr-svc)
   :Bazarr (tile bazarr-svc)
   :qBittorrent (tile qbit-svc)
   :Prowlarr (tile prowlarr-svc)}}
 {:System
  {:Pi-hole (tile pihole-svc)
   :Cockpit (tile cockpit-svc)}}
 {:Tools
  {:Vaultwarden (tile vaultwarden-svc)
   :Uptime-Kuma (tile kuma-svc)
   :Dozzle (tile dozzle-svc)}}]
