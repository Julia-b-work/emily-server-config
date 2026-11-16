;; jellyfin.em — generates /data/docker/jellyfin/compose.yml
;; Media server. Config + transcode cache live on the SSD (/srv) so playback
;; and UI are snappy; the media itself stays on the HDD (read-only mount).
;; VAAPI via the Intel iGPU (/dev/dri + render/video groups).
(import "lib.em")

(def jellyfin {:container_name "jellyfin"
  :image "jellyfin/jellyfin:latest"
  :environment (merge puid-pgid {:TZ tz})
  :ports ["8096:8096"]
  :volumes ["/srv/jellyfin-config:/config"
            "/srv/jellyfin-cache:/cache"
            "/data/media:/media:ro"]
  :devices ["/dev/dri:/dev/dri"]
  :group_add ["992" "44"]
  :restart "unless-stopped"})

{:name "jellyfin" :services {:jellyfin jellyfin}}
