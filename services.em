;; services.em — THE canonical registry of server services.
;; One list drives: Caddy routes (caddy.em), homepage tiles (homepage-services.em),
;; and Uptime Kuma monitors (monitors.em).
;;
;; Fields:
;;   :key        string id (used in JSON outputs)
;;   :name       display name (hyphens instead of spaces — Emily keywords)
;;   :host       docker hostname or IP for proxying
;;   :port       internal port
;;   :url        pretty URL (https for cockpit)
;;   :icon       homepage icon
;;   :desc       homepage description
;;   :group      homepage group (Media / Requests / System / Tools)
;;   :routing    "proxy" | "ha" | "pihole" | "cockpit" | "dashboard" (Caddy handler type)
;;   :monitor    true if Uptime Kuma should watch it
(import "lib.em")

(def jellyfin-svc : Service {:key "jellyfin" :name "Jellyfin" :host "jellyfin" :port 8096
  :url "http://jellyfin.home" :icon "jellyfin.png" :desc "Movies, TV, anime & music"
  :group "Media" :routing "proxy" :monitor true})

(def immich-svc : Service {:key "immich" :name "Immich" :host "immich_server" :port 2283
  :url "http://immich.home" :icon "immich.png" :desc "Photos"
  :group "Media" :routing "proxy" :monitor true})

(def ha-svc : Service {:key "ha" :name "Home-Assistant" :host "192.168.1.11" :port 80
  :url "http://ha.home" :icon "home-assistant.png" :desc "Smart home"
  :group "Media" :routing "ha" :monitor true})

(def seerr-svc : Service {:key "seerr" :name "Seerr" :host "seerr" :port 5055
  :url "http://seerr.home" :icon "jellyseerr.png" :desc "Request movies & shows"
  :group "Requests" :routing "proxy" :monitor true})

(def radarr-svc : Service {:key "radarr" :name "Radarr" :host "radarr" :port 7878
  :url "http://radarr.home" :icon "radarr.png" :desc "Movies"
  :group "Requests" :routing "proxy" :monitor true})

(def sonarr-svc : Service {:key "sonarr" :name "Sonarr" :host "sonarr" :port 8989
  :url "http://sonarr.home" :icon "sonarr.png" :desc "TV shows"
  :group "Requests" :routing "proxy" :monitor true})

(def lidarr-svc : Service {:key "lidarr" :name "Lidarr" :host "lidarr" :port 8686
  :url "http://lidarr.home" :icon "lidarr.png" :desc "Music"
  :group "Requests" :routing "proxy" :monitor true})

(def bazarr-svc : Service {:key "bazarr" :name "Bazarr" :host "bazarr" :port 6767
  :url "http://bazarr.home" :icon "bazarr.png" :desc "Subtitles (pt-BR)"
  :group "Requests" :routing "proxy" :monitor true})

(def qbit-svc : Service {:key "qbit" :name "qBittorrent" :host "qbittorrent" :port 8080
  :url "http://qbit.home" :icon "qbittorrent.png" :desc "Downloads"
  :group "Requests" :routing "proxy" :monitor true})

(def prowlarr-svc : Service {:key "prowlarr" :name "Prowlarr" :host "prowlarr" :port 9696
  :url "http://prowlarr.home" :icon "prowlarr.png" :desc "Indexers"
  :group "Requests" :routing "proxy" :monitor true})

(def pihole-svc : Service {:key "pihole" :name "Pi-hole" :host "192.168.1.10" :port 8088
  :url "http://pihole.home/admin" :icon "pi-hole.png" :desc "Ad blocking"
  :group "System" :routing "pihole" :monitor true})

(def cockpit-svc : Service {:key "cockpit" :name "Cockpit" :host "192.168.1.10" :port 9090
  :url "https://cockpit.home" :icon "cockpit.png" :desc "Server admin"
  :group "System" :routing "cockpit" :monitor false})

(def homepage-svc : Service {:key "home" :name "Homepage" :host "homepage" :port 3000
  :url "http://server.home" :icon "homepage.png" :desc "Dashboard"
  :group "none" :routing "proxy" :monitor true})

(def vaultwarden-svc : Service {:key "vault" :name "Vaultwarden" :host "vaultwarden" :port 80
  :url "http://vault.home" :icon "vaultwarden.png" :desc "Passwords"
  :group "Tools" :routing "proxy" :monitor true})

(def kuma-svc : Service {:key "kuma" :name "Uptime-Kuma" :host "uptime-kuma" :port 3001
  :url "http://kuma.home" :icon "uptime-kuma.png" :desc "Status page"
  :group "Tools" :routing "proxy" :monitor true})

(def dozzle-svc : Service {:key "dozzle" :name "Dozzle" :host "dozzle" :port 8080
  :url "http://dozzle.home" :icon "dozzle.png" :desc "Container logs"
  :group "Tools" :routing "proxy" :monitor true})

;; flat list — order = route order in Caddy (specific hosts before catch-all)
(def services : (List Service) [jellyfin-svc immich-svc ha-svc seerr-svc radarr-svc sonarr-svc
               lidarr-svc bazarr-svc qbit-svc prowlarr-svc pihole-svc cockpit-svc
               vaultwarden-svc kuma-svc dozzle-svc homepage-svc])

;; homepage groups: name + which service keys belong to it (in order)
(def group-media : (List Service) [jellyfin-svc immich-svc ha-svc])
(def group-requests : (List Service) [seerr-svc radarr-svc sonarr-svc lidarr-svc bazarr-svc qbit-svc prowlarr-svc])
(def group-system : (List Service) [pihole-svc cockpit-svc])
(def group-tools : (List Service) [vaultwarden-svc kuma-svc dozzle-svc])
