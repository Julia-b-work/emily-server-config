;; arr-stack.em — generates /data/docker/arr-stack/compose.yml
;; One source of truth for the media-automation stack: qBittorrent, *arr, Seerr, Bazarr.
(import "lib.em")

(def qbittorrent (merge (lscr "qbittorrent" "lscr.io/linuxserver/qbittorrent:latest")
  {:environment (merge puid-pgid {:TZ tz :WEBUI_PORT 8080})
   :volumes ["./qbittorrent:/config" "/data:/data" "/data/downloads:/downloads"]
   :ports ["8080:8080" "6881:6881" "6881:6881/udp"]}))

(def prowlarr (merge (lscr "prowlarr" "lscr.io/linuxserver/prowlarr:latest")
  {:volumes ["./prowlarr:/config"] :ports ["9696:9696"]}))

(def radarr (merge (lscr "radarr" "lscr.io/linuxserver/radarr:latest")
  {:volumes ["./radarr:/config" "/data:/data"] :ports ["7878:7878"]}))

(def sonarr (merge (lscr "sonarr" "lscr.io/linuxserver/sonarr:latest")
  {:volumes ["./sonarr:/config" "/data:/data"] :ports ["8989:8989"]}))

(def seerr {:container_name "seerr" :image "seerr/seerr:latest"
  :environment {:TZ tz} :volumes ["./seerr:/app/config"] :ports ["5055:5055"]
  :restart "unless-stopped"})

(def flaresolverr {:container_name "flaresolverr" :image "ghcr.io/flaresolverr/flaresolverr:latest"
  :environment {:TZ tz :LOG_LEVEL "info"} :ports ["8191:8191"] :restart "unless-stopped"})

(def bazarr (merge (lscr "bazarr" "lscr.io/linuxserver/bazarr:latest")
  {:volumes ["./bazarr:/config" "/data:/data"] :ports ["6767:6767"]}))

(def lidarr (merge (lscr "lidarr" "lscr.io/linuxserver/lidarr:latest")
  {:volumes ["./lidarr:/config" "/data:/data" "/data/downloads:/downloads"] :ports ["8686:8686"]}))

{:name "arr"
 :services {:qbittorrent qbittorrent
            :prowlarr prowlarr
            :radarr radarr
            :sonarr sonarr
            :seerr seerr
            :flaresolverr flaresolverr
            :bazarr bazarr
            :lidarr lidarr}}
