# Network

The hackerspace LAN is `192.168.0.0/24`, with the ISP gateway at `192.168.0.1`.

| Range          | Who                                   |
| -------------- | ------------------------------------- |
| `.10–.99`      | Router DHCP pool (phones, laptops, …) |
| `.100–.199`    | **hawg**, static, scheme below        |
| `.200–.254`    | Free, reserved for later              |

## hawg addressing: `192.168.0.1TN`

**T** is the device type and **N** is the node's number, so the name gives
you the IP: `cam-5` → `.115`, `pir-1` → `.121`. Numbering starts at 1; `x0` is
left unused except `.100`.

| T   | Type           | Range       |
| --- | -------------- | ----------- |
| 0   | Infrastructure | `.100–.109` |
| 1   | Camera         | `.111–.119` |
| 2   | PIR            | `.121–.129` |
| 3–9 | _TBD_          | `.130–.199` |

A node goes under its main job: an ESP32-CAM with a PIR on it is a camera.
Node names follow `<type>-<n>` so hostname, YAML file and IP all agree.

## Assignments

| IP     | Device | Hardware address    | Notes |
| ------ | ------ | ------------------- | ----- |
| `.100` | HA Pi (Raspberry Pi 4) | `D8:3A:DD:28:C0:59` (eth) | Static IP set in HAOS (below); WiFi off |
| `.111` | cam-1  | `EC:E3:34:20:FA:F8` | Today: `esphome-web-20faf8` "ESP32-CAM-1"; has a PIR |
| `.112` | cam-2  | `B0:CB:D8:C6:BD:A0` | Today: `esphome-web-c6bda0` "ESP32-CAM-2" |
| `.115` | cam-5  | `D4:E9:F4:A1:5A:6C` | Today: `esphome-web-a15a6c` "ESP32-CAM-5" |
| `.121` | pir-1  | `48:9D:31:E3:49:B8` | Today: `pir-sensor`; drives the website flag |

Nodes take their address from `manual_ip` in their ESPHome YAML. Nothing is
reserved in the router, so this file and the node YAMLs are the whole plan.

## HA Pi static IP

Set on the Pi itself (Terminal & SSH add-on, or the HAOS console). Ethernet is
`end0`; WiFi (`wlan0`) is disabled so the Pi has exactly one address.

```sh
ha network update end0 --ipv4-method static --ipv4-address 192.168.0.100/24 --ipv4-gateway 192.168.0.1 --ipv4-nameserver 178.233.140.147 --ipv4-nameserver 46.196.235.228
ha network update wlan0 --disabled
```

Keep each command on one line; the add-on's web terminal mangles `\`
continuations. Run them from the HAOS console or the web terminal, not over SSH
to the old address: the session drops when the address changes.

**DNS must be the ISP's servers, not the router.** The gateway at `.1` does not
answer DNS, and pointing the Pi at it silently breaks every cloud call
(including the Firebase presence write).

## Router settings

Gateway → Kurulum → DHCP (Technicolor/Arris-style ISP gateway):

- Başlangıç Yerel IP Adresi: `192.168.0.10`
- CPE Sayısı: `90` (pool ends at `.99`)

**If the router is reset or replaced**, the pool goes back to its default
(`.10` + 245 = up to `.254`), which overlaps hawg. Set the pool back as above
first thing.
