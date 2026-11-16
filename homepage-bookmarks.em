;; homepage-bookmarks.em — generates /data/docker/homepage/config/bookmarks.yaml
;; Homepage expects lists all the way down: [{Group: [{Sub: [{abbr href}]}]}]
(import "lib.em")

[{:Julia
  [{:Streaming [{:abbr "JF" :href "http://jellyfin.home"}
                {:abbr "IM" :href "http://immich.home"}
                {:abbr "HA" :href "http://ha.home"}]}
   {:Requests [{:abbr "SR" :href "http://seerr.home"}]}]}]
