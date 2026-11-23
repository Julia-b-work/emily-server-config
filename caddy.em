;; caddy.em — generates the FULL Caddy JSON config from the service registry.
;; Every *.home route + the catch-all redirect is folded from services.em.
(import "services.em")

;; plain reverse-proxy route
(def proxy-route (fn (s)
  {:match [{:host [(concat s.key ".home")]}]
   :handle [{:handler "reverse_proxy"
             :upstreams [{:dial (concat s.host ":" (show s.port))}]}]}))

;; Home Assistant: strip X-Forwarded-* and force Host at the PROXY stage
;; (deleting before reverse_proxy doesn't work — it re-adds them)
(def ha-route (fn (s)
  {:match [{:host [(concat s.key ".home")]}]
   :handle [{:handler "reverse_proxy"
             :upstreams [{:dial (concat s.host ":" (show s.port))}]
             :headers {:request {:Set {:Host [s.host]}
                                 :Delete ["X-Forwarded-For" "X-Forwarded-Proto" "X-Forwarded-Host"]}}}]}))

;; Cockpit: self-signed HTTPS upstream
(def cockpit-route (fn (s)
  {:match [{:host [(concat s.key ".home")]}]
   :handle [{:handler "reverse_proxy"
             :upstreams [{:dial (concat s.host ":" (show s.port))}]
             :transport {:protocol "http" :tls {:insecure_skip_verify true}}}]}))

;; route dispatcher by :routing tag
(def make-route (fn (s)
  (if (= s.routing "ha")
    (ha-route s)
    (if (= s.routing "cockpit")
      (cockpit-route s)
      (proxy-route s)))))

(def catch-all
  {:handle [{:handler "static_response"
             :status_code 302
             :headers {:Location ["http://192.168.1.10:3000"]}}]})

(def routes (append (fold services [] (fn (acc s) (append acc (make-route s))))
                    catch-all))

{:apps {:http {:servers {:srv0
  {:listen [":80"]
   :automatic_https {:disable true}
   :routes routes}}}}}
