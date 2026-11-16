;; pihole.em — generates /data/docker/pihole/compose.yml
;; DNS + ad-blocking for the whole LAN. Web password lives in the stack
;; .env (PIHOLE_WEBPASSWORD) — never in Emily sources.
(import "lib.em")

(def pihole {:container_name "pihole"
  :image "pihole/pihole:latest"
  :restart "unless-stopped"
  ;; DNS bound to the LAN IP so it doesn't clash with libvirt's internal
  ;; DNS on 192.168.122.1; web UI published on 8088.
  :ports ["192.168.15.90:53:53/tcp"
          "192.168.15.90:53:53/udp"
          "8088:80/tcp"]
  :environment {:TZ tz
                :WEBPASSWORD "${PIHOLE_WEBPASSWORD}"
                :PIHOLE_DNS_ "9.9.9.9;1.1.1.1"
                :FTLCONF_dns_listeningMode "ALL"
                :FTLCONF_misc_etc_dnsmasq_d "true"}
  :volumes ["./etc-pihole:/etc/pihole"
            "./etc-dnsmasq.d:/etc/dnsmasq.d"]
  :cap_add ["NET_ADMIN"]})

{:name "pihole" :services {:pihole pihole}}
