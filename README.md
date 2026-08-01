# hawg — Home Assistant Work Group

Everything behind the smart parts of [Konya Hackerspace](https://github.com/konyahackerspace):
ESPHome sensor nodes, Home Assistant automations, wiring docs, and the tooling
that keeps it maintainable by a group.

## Layout

| Path        | What lives there                                          |
| ----------- | --------------------------------------------------------- |
| `esphome/`  | One YAML per physical node + `common/` shared packages    |
| `secrets/`  | Encrypted secrets ([how it works](docs/secrets-management.md)) |
| `docs/`     | Guides: secrets, wiring, flashing, onboarding             |
| `scripts/`  | Helper scripts (`secrets.sh`)                             |

## Quick start (hawg members)

```sh
git clone https://github.com/konyahackerspace/hawg && cd hawg
brew install esphome sops age            # or: pip install esphome
./scripts/secrets.sh decrypt             # needs your key in .sops.yaml — see docs
esphome run esphome/<node>.yaml          # compile + flash a node
```

Not a keyholder yet? Follow [docs/secrets-management.md](docs/secrets-management.md)
to generate a key and open a PR.

## Status

🚧 Early days — repo scaffolding and first nodes in progress.
