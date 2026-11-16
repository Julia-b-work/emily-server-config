;; homepage-compose.em — generates /data/docker/homepage/docker-compose.yml
;; homepage dashboard + glances resource monitor.
(import "lib.em")

{:services
 {:homepage
  {:image "ghcr.io/gethomepage/homepage:latest"
   :container_name "homepage"
   :environment (merge puid-pgid
      {:TZ tz
       :HOMEPAGE_ALLOWED_HOSTS "home.home,home,julia-server.local,192.168.15.90"})
   :volumes ["./config:/app/config"]
   :ports ["3000:3000"]
   :networks ["default" "arr_default" "jellyfin_default" "immich_default" "pihole_default"]
   :restart "unless-stopped"}
  :glances
  {:image "nicolargo/glances:latest-full"
   :container_name "glances"
   :pid "host"
   :environment {:GLANCES_OPT "-w --disable-plugin all --enable-plugin cpu,mem,load,disk,network,fs"}
   :volumes ["/var/run/docker.sock:/var/run/docker.sock:ro"]
   :restart "unless-stopped"}}
 :networks {:arr_default {:external true}
            :jellyfin_default {:external true}
            :immich_default {:external true}
            :pihole_default {:external true}}}
