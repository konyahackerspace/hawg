# Home Assistant

**This repo is the source of truth for our Home Assistant config.** Automations,
scripts, helpers and template sensors are written as YAML here, reviewed in PRs,
and deployed to the Pi. Nothing is authored in the HA UI. If the Pi dies, a
fresh HAOS install plus this repo gets everything back.

## What lives where

| Thing                                         | Where                                  |
| --------------------------------------------- | -------------------------------------- |
| Core config                                   | `homeassistant/configuration.yaml`     |
| Features (automations, helpers, sensors, …)   | `homeassistant/packages/<feature>.yaml`|
| Integrations & devices (ESPHome, …)           | UI-only in HA — setup steps documented below |
| Entity registry, users, history (`.storage`, DB) | On the Pi only — covered by HA backups |

Group things by feature: everything for motion presence goes in
`packages/presence.yaml`, not split across `automations.yaml` and friends.
Define helpers (`input_boolean`, `counter`, …) in YAML too, never in the UI.

## Deploying

```sh
./scripts/deploy-ha.sh --check   # validate on the Pi, change nothing
./scripts/deploy-ha.sh           # validate, apply, restart HA
```

The script copies `configuration.yaml` and `packages/` to `/config` over SSH and
runs `ha core check`. If the check fails, the previous config is restored. Only
these managed paths are touched. Anything else under `/config` is left alone,
and `packages/` on the Pi is replaced wholesale, so packages deleted here get
deleted there.

Any edit made on the Pi or in the UI to managed files gets overwritten by the
next deploy. That's intended.

## One-time Pi setup

1. Install the **Terminal & SSH** add-on (Settings → Add-ons → Add-on store).
2. In its Configuration tab, add your SSH public key under `authorized_keys`,
   and under **Network** set the `22/tcp` port to `22` (it's off by default; the
   log says "SSH port is disabled" otherwise). Save, then start the add-on.
3. Check it works: `ssh root@192.168.0.100 ha core info`.

Use the IP, not `homeassistant.local`: several HAs in the space answer to that
name. The Pi's address is fixed at `.100` (see [network.md](network.md)); set
`HA_SSH=user@host` to deploy somewhere else.

HA secrets (`!secret ...` in `homeassistant/`) live in
`secrets/homeassistant.enc.yaml`. `./scripts/secrets.sh decrypt` writes them to
`homeassistant/secrets.yaml`, and the deploy copies that file to the Pi.

## Health heartbeat

`packages/health.yaml` writes to Firebase RTDB every minute, so an outage of
HA (or its network) is visible from outside:

- `/health/last`: Firebase server time (ms) of the latest heartbeat. If it's
  more than a few minutes old, HA is down or offline. The website should read
  only this.
- `/health/log/<YYYY-MM-DD>/<HH:MM>`: Firebase server time (ms) per minute
  (HA local time in the key). Days older than 30 are pruned at 00:05. Gaps in
  the log are the outages.

## Integrations (UI-only steps)

Some things can only be set up through the HA UI. Record each one here so a
rebuild is repeatable.

- **ESPHome**: one entry per node (auto-discovered; accept and paste the node's
  API key). `presence.yaml` expects `binary_sensor.pir_sensor_motion` (node
  `pir-sensor`) and `binary_sensor.esp32_cam_1_pir_motion` (ESP32-CAM-1).
- **Add-ons**: Terminal & SSH (deploys), ESPHome Device Builder.

## Migration from the hand-made setup (one-time, 2026-10)

Before the first real deploy on the current Pi:

1. Delete the UI helper **Hackerspace General Presence** (Settings → Devices &
   services → Helpers). It's now defined in `packages/presence.yaml`; if both
   exist, the YAML one comes up as `..._presence_2`.
2. Deploy. The old `automations.yaml`, `scripts.yaml`, `scenes.yaml` and
   `python_scripts/` are no longer loaded and can be deleted from `/config`.
   (`python_scripts/firebase_auth.py` never worked: HA's python_script sandbox
   blocks `import`, and the Firebase write authenticates with the RTDB secret in
   the URL instead.)
