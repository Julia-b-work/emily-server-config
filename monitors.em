;; monitors.em — generates monitors.json for Uptime Kuma (consumed by kuma-sync.sh).
;; Only services with :monitor true are watched — URLs are the pretty *.home ones,
;; so Kuma tests the whole path: DNS -> Caddy -> service.
(import "services.em")

(def to-monitor (fn (s)
  {:name s.name
   :url s.url
   :type "http"
   :interval 60
   :retryInterval 60
   :maxretries 0
   :maxredirects 10
   :timeout 48
   :method "GET"
   :accepted_statuscodes ["200-299"]}))

(fold services [] (fn (acc s)
  (if s.monitor (append acc (to-monitor s)) acc)))
