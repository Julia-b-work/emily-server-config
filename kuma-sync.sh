#!/bin/bash
# kuma-sync.sh — sync Uptime Kuma monitors from the Emily service registry.
# Usage: kuma-sync.sh   (idempotent: creates missing monitors, leaves existing alone)
set -euo pipefail
SRC=/data/emily-config
KUMA_USER=admin
KUMA_PASS="${KUMA_PASSWORD:?set KUMA_PASSWORD env var}"

emily "$SRC/monitors.em" > "$SRC/generated/monitors.json"

cat > /tmp/kuma-sync.js <<'JS'
const io = require("socket.io-client");
const fs = require("fs");
const monitors = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const user = process.env.KUMA_USER, pass = process.env.KUMA_PASS;
const socket = io("http://localhost:3001", { transports: ["websocket"] });
const done = (msg) => { console.log(msg); process.exit(0); };

socket.on("connect", () => {
  socket.emit("needSetup", async (need) => {
    try {
      if (need) {
        await new Promise((res, rej) => socket.emit("setup", user, pass, (r) => r.ok ? res() : rej(new Error(r.msg || "setup failed"))));
        console.log("kuma: initial setup done");
      }
      await new Promise((res, rej) => socket.emit("login", { username: user, password: pass, token: "" }, (r) => r.ok ? res() : rej(new Error(r.msg || "login failed"))));
      console.log("kuma: logged in");
      const existing = await new Promise((res, rej) => {
        const t = setTimeout(() => rej(new Error("monitorList timeout")), 5000);
        socket.once("monitorList", (list) => { clearTimeout(t); res(Object.values(list) || []); });
        socket.emit("getMonitorList");
      });
      const names = new Set(existing.map(m => m.name));
      let added = 0;
      for (const m of monitors) {
        if (names.has(m.name)) continue;
        m.accepted_statuscodes = m.accepted_statuscodes || ["200-299"];
        m.notificationIDList = {};
        m.kafkaProducerBrokers = "";
        m.kafkaProducerSaslOptions = "";
        await new Promise((res, rej) => socket.emit("add", m, (r) => r.ok ? res() : rej(new Error(r.msg || "add failed"))));
        console.log("added monitor:", m.name);
        added++;
      }
      done(`kuma: ${added} added, ${monitors.length - added} already present`);
    } catch (e) { done("ERROR: " + e.message); }
  });
});
socket.on("connect_error", (e) => done("ERROR: connect failed: " + e.message));
JS

docker cp /tmp/kuma-sync.js uptime-kuma:/app/kuma-sync.js
docker cp "$SRC/generated/monitors.json" uptime-kuma:/tmp/monitors.json
docker exec -e KUMA_USER="$KUMA_USER" -e KUMA_PASS="$KUMA_PASS" uptime-kuma \
  node /app/kuma-sync.js /tmp/monitors.json
