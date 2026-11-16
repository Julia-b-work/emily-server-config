#!/bin/bash
# kuma-ntfy.sh — add/update the ntfy notification in Uptime Kuma and attach it to all monitors.
# Usage: kuma-ntfy.sh   (idempotent)
set -euo pipefail
KUMA_USER=admin
KUMA_PASS="${KUMA_PASSWORD:?set KUMA_PASSWORD env var}"
TOPIC=$(cat /etc/ntfy-topic 2>/dev/null || true)
[ -n "$TOPIC" ] || { echo "no /etc/ntfy-topic — nothing to do"; exit 0; }

cat > /tmp/kuma-ntfy.js <<'JS'
const io = require("socket.io-client");
const user = process.env.KUMA_USER, pass = process.env.KUMA_PASS, topic = process.env.NTFY_TOPIC;
const socket = io("http://localhost:3001", { transports: ["websocket"] });
const done = (m) => { console.log(m); process.exit(0); };
socket.on("connect", () => {
  socket.emit("login", { username: user, password: pass, token: "" }, async (r) => {
    try {
      if (!r.ok) throw new Error(r.msg || "login failed");
      // fetch existing notifications
      const notifs = await new Promise((res, rej) => {
        const t = setTimeout(() => rej(new Error("timeout")), 5000);
        socket.once("notificationList", (list) => { clearTimeout(t); res(Object.values(list)); });
        socket.emit("getNotificationList");
      });
      let nid = null;
      for (const n of notifs) { if (n.name === "ntfy") nid = n.id; }
      const payload = { name: "ntfy", type: "ntfy", isDefault: true,
        ntfyAuthenticationMethod: "disabled", ntfyusername: "", ntfypassword: "",
        ntfyaccesstoken: "", ntfytopic: topic, ntfyserverurl: "https://ntfy.sh/",
        ntfyPriority: 4 };
      let id = await new Promise((res, rej) => socket.emit("addNotification", payload, nid, (r2) => r2.ok ? res(r2.id) : rej(new Error(r2.msg || "save failed"))));
      console.log("ntfy notification id:", id);
      // attach to all monitors
      const mons = await new Promise((res, rej) => {
        const t = setTimeout(() => rej(new Error("timeout")), 5000);
        socket.once("monitorList", (list) => { clearTimeout(t); res(Object.values(list)); });
        socket.emit("getMonitorList");
      });
      for (const m of mons) {
        const map = Object.assign({}, m.notificationIDList || {});
        if (!map[id]) map[id] = true;
        const patch = Object.assign({}, m, { notificationIDList: map });
        await new Promise((res, rej) => socket.emit("editMonitor", patch, (r2) => r2.ok ? res() : rej(new Error(r2.msg || "edit failed"))));
      }
      done(`kuma: ntfy attached to ${mons.length} monitors`);
    } catch (e) { done("ERROR: " + e.message); }
  });
});
socket.on("connect_error", (e) => done("ERROR: " + e.message));
JS

docker cp /tmp/kuma-ntfy.js uptime-kuma:/app/kuma-ntfy.js
docker exec -e KUMA_USER="$KUMA_USER" -e KUMA_PASS="$KUMA_PASS" -e NTFY_TOPIC="$TOPIC" \
  uptime-kuma node /app/kuma-ntfy.js
