# Secrets management

This repo is **public**, but our ESPHome nodes need real secrets: the WiFi
password, the Home Assistant API encryption key, and the OTA update password.
Anyone holding the OTA password on our WiFi could flash arbitrary firmware onto
our devices — so plaintext secrets must never be committed.

## How it works

We use [SOPS](https://github.com/getsops/sops) with
[age](https://github.com/FiloSottile/age) encryption:

- `secrets/secrets.enc.yaml` is the **encrypted** secrets file. It lives in git,
  is versioned like any other file, and is safe to be public.
- `esphome/secrets.yaml` is the **decrypted** copy that ESPHome reads at compile
  time. It exists only on your machine and is gitignored.
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

   You now have `esphome/secrets.yaml` locally and can compile/flash nodes.

## Day-to-day

| You want to…                       | Run                                    |
| ---------------------------------- | -------------------------------------- |
| Get plaintext secrets locally      | `./scripts/secrets.sh decrypt`         |
| Change a secret                    | `./scripts/secrets.sh edit`, commit    |
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

- Never commit `esphome/secrets.yaml` (gitignored, but stay alert in PRs).
- Never paste secrets into issues, chats, or commit messages.
- Don't copy secrets out of the managed files into other configs.
