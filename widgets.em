;; widgets.em — generates /data/docker/homepage/config/widgets.yaml
;; Data comes from the service registry; NO secrets live here — regenerate.sh
;; injects placeholders from the live services at regen time (secrets policy):
;;   JFKEY_PLACEHOLDER     <- Jellyfin DB (ApiKeys table)
;;   SONARRKEY_PLACEHOLDER <- /data/docker/arr-stack/sonarr/config.xml
;;   RADARRKEY_PLACEHOLDER <- /data/docker/arr-stack/radarr/config.xml
;;   PIHOLEKEY_PLACEHOLDER <- /data/docker/pihole/.env (PIHOLE_WEBPASSWORD)
;;   QBPASS_PLACEHOLDER    <- /data/emily-config/.secrets (git-ignored)
;;   KUMAPASS_PLACEHOLDER  <- /data/emily-config/.secrets (git-ignored)
(import "services.em")

[{:qbittorrent
  {:url "http://qbittorrent:8080"
   :username "admin"
   :password "QBPASS_PLACEHOLDER"
   :enableLeechProgress true}}
 {:jellyfin
  {:url "http://jellyfin:8096"
   :key "JFKEY_PLACEHOLDER"
   :enableBlocks true
   :enableNowPlaying true
   :showEpisodeNumber true}}
 {:sonarr {:url "http://sonarr:8989" :key "SONARRKEY_PLACEHOLDER" :enableQueue true}}
 {:radarr {:url "http://radarr:7878" :key "RADARRKEY_PLACEHOLDER" :enableQueue true}}
 {:pihole {:url "http://pihole:80" :version 6 :key "PIHOLEKEY_PLACEHOLDER"}}
 {:glances {:url "http://glances:61208" :cpu true :mem true :cputemp true :uptime true :disk "/data"}}
 {:uptimekuma {:slug "kuma" :url "http://uptime-kuma:3001" :username "admin" :password "KUMAPASS_PLACEHOLDER"}}]
