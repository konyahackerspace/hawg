# Secrets management

This repo is **public**, but our ESPHome nodes need real secrets: the WiFi
password, the Home Assistant API encryption key, and the OTA update password.
Anyone holding the OTA password on our WiFi could flash arbitrary firmware onto
our devices — so plaintext secrets must never be committed.

## How it works

We use [SOPS](https://github.com/getsops/sops) with
[age](https://github.com/FiloSottile/age) encryption:

- `secrets/*.enc.yaml` are the **encrypted** secrets files. They live in git,
  are versioned like any other file, and are safe to be public.
- Each has a **decrypted** copy that exists only on your machine and is gitignored:

  | Encrypted                        | Decrypted                    | Used by                |
  | -------------------------------- | ---------------------------- | ---------------------- |
  | `secrets/secrets.enc.yaml`       | `esphome/secrets.yaml`       | ESPHome, at compile time |
  | `secrets/homeassistant.enc.yaml` | `homeassistant/secrets.yaml` | HA, copied by `deploy-ha.sh` |
- `.sops.yaml` lists the age **public keys** of every hawg member allowed to
  decrypt. SOPS encrypts the file so that any one of those keys can open it.

Each member has an age keypair: the public key goes in the repo, the private
key never leaves their machine.

## One-time setup (new hawg member)

1. Install the tools:

   ```sh
   brew install sops age        # macOS
   # apt install age && <get sops from github releases>   # Debian/Ubuntu
   ```

2. Generate your keypair (SOPS looks in this path by default):

   ```sh
   mkdir -p ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

   It prints your **public** key (`age1...`). The file also contains your
   **private** key — never share it, never commit it, back it up somewhere safe.

3. Open a PR adding your public key to `.sops.yaml` under `key_groups.age`,
   with a comment naming you.

4. An **existing keyholder** merges your PR and runs:

   ```sh
   ./scripts/secrets.sh rekey
   ```

   then commits the re-encrypted file. (You can't do this yourself — you can't
   decrypt yet. That's the point.)

5. Pull, then decrypt:

   ```sh
   ./scripts/secrets.sh decrypt
   ```

   You now have the decrypted copies locally and can compile/flash nodes and
   deploy HA.

## Day-to-day

| You want to…                       | Run                                    |
| ---------------------------------- | -------------------------------------- |
| Get plaintext secrets locally      | `./scripts/secrets.sh decrypt`         |
| Change a secret                    | `./scripts/secrets.sh edit [esphome\|homeassistant]`, commit |
| Re-encrypt after key list changed  | `./scripts/secrets.sh rekey`, commit   |

`edit` opens the encrypted file in `$EDITOR` via SOPS and re-encrypts on save —
plaintext never touches disk. After editing, run `decrypt` again to refresh
your local copy, and re-flash any nodes affected by the change.

## When a member leaves

Removing their key from `.sops.yaml` + `rekey` stops **future** secrets from
being readable by them — but they may still have old plaintext. So also
**rotate the actual secrets**: change the WiFi password if warranted, and
generate fresh API/OTA keys (`openssl rand -base64 32` / `openssl rand -hex 16`),
then re-flash the nodes.

## Rules

- Never commit `esphome/secrets.yaml` or `homeassistant/secrets.yaml`
  (gitignored, but stay alert in PRs).
- Never paste secrets into issues, chats, or commit messages.
- Don't copy secrets out of the managed files into other configs.
- Every node's OTA password must come from `!secret ota_password` (via
  `common/base.yaml`), never written inline. A node whose OTA password lives
  only on someone's laptop can't be updated over WiFi, which means physically
  reaching it with a USB cable (this happened with `pir-1`).
