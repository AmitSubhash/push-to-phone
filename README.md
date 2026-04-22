# push-to-phone

A tiny shell CLI that sends a tappable notification from your terminal to your phone via [ntfy.sh](https://ntfy.sh). Tap the notification and the URL opens in whatever is set as the default browser on your phone.

Originally built to let Claude Code on my Mac hand links off to Brave on my iPhone without AirDrop. Grew to cover plots, job-done pings, scheduled reminders, and more.

## Quick look

```
$ push-to-phone https://example.com
$ push-to-phone -t "Loss curve" --attach ./plots/loss.png
$ push-to-phone --tag rocket,green_circle -m "deploy finished"
$ push-to-phone --in 30m -m "check on the oven"
$ push-to-phone --at "tomorrow 9am" -m "standup"
$ push-to-phone wrap -t "train resnet50" -- python train.py --epochs 100
$ push-to-phone doctor
```

## Install

```bash
git clone https://github.com/AmitSubhash/push-to-phone.git ~/Projects/push-to-phone
~/Projects/push-to-phone/install.sh      # symlinks bin/push-to-phone into ~/.local/bin

# Set your topic
mkdir -p ~/.config/push-to-phone
cp ~/Projects/push-to-phone/config.example ~/.config/push-to-phone/config
chmod 600 ~/.config/push-to-phone/config
# now edit ~/.config/push-to-phone/config and put your topic in it

push-to-phone doctor                     # sanity-check everything
```

On your phone:
1. Install the [ntfy iOS](https://apps.apple.com/us/app/ntfy/id1625396347) or [Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) app.
2. Subscribe to the same topic name you set in your config.
3. (Optional) On iOS: `Settings → Apps → Default Browser App → Brave` so tapped URLs open in Brave.

## Features

| Flag / subcommand        | Purpose                                                       |
|--------------------------|---------------------------------------------------------------|
| `<url>`                  | Send a tappable notification that opens the URL               |
| `-t, --title`            | Notification title                                            |
| `-m, --message`          | Body text (defaults to URL, or stdin if piped)                |
| `-p, --priority`         | `min`, `low`, `default`, `high`, `urgent` (or `1..5`)         |
| `--tag` / `--tags`       | Comma-separated [ntfy emoji tags](https://docs.ntfy.sh/emojis/) |
| `-a, --attach FILE`      | Upload a local file (plot, log tail, screenshot) as attachment|
| `--at TIME`              | Scheduled delivery: `"tomorrow 9am"`, `"in 30min"`, Unix ts   |
| `--in DURATION`          | Shorthand: `30m`, `1h`, `2h`                                  |
| `-M, --markdown`         | Render body as markdown on the phone                          |
| `--copy VALUE`           | Adds a tappable copy-to-clipboard action (great for OTPs)     |
| `-b, --batch`            | Batch mode: one URL (or `Title||URL`) per line on stdin       |
| `-n, --dry-run`          | Print what would be sent, do not POST                         |
| `-v, --verbose`          | Print the success line                                        |
| `--token TOKEN`          | Bearer auth (for auth-protected ntfy servers)                 |
| `--server URL`           | Override ntfy server                                          |
| `--topic NAME`           | Override topic                                                |
| `wrap -- <cmd>`          | Run command, notify on exit with ✅/❌, duration, stderr tail |
| `doctor` / `test`        | Show current config and send a test ping                      |
| `--help`, `--version`    |                                                               |

### The killer feature: `wrap`

```bash
push-to-phone wrap -t "train resnet50" -- python train.py --epochs 100
```

Runs the command, measures elapsed time, and pushes a notification when it's done:
- **Success:** `✅ train resnet50` / `done in 3h 14m 2s`
- **Failure:** `❌ train resnet50` / `failed (exit 1) in 0m 12s` + last 10 lines of stderr, priority `high`.

Wrap sub-flags:
```
push-to-phone wrap [--tail N] [--success-tag TAG] [--fail-tag TAG] -t "title" -- <cmd>
```

### Examples

```bash
# Push the current branch's HEAD commit URL to the phone
push-to-phone -t "latest commit" "https://github.com/AmitSubhash/repo/commit/$(git rev-parse HEAD)"

# OTP-style: send a code with a copy action
push-to-phone --copy "123456" -t "2FA code" -m "Tap to copy"

# Pipe a log line
echo "backup finished at $(date)" | push-to-phone -t "nightly backup" --tag floppy_disk

# Remind yourself
push-to-phone --at "tomorrow 8am" -t "standup" -m "daily sync in 30 min"

# Wrap a long HPC job (SLURM etc.)
srun --gres=gpu:1 --time=06:00:00 bash -lc '
  push-to-phone wrap -t "MCX baseline" -- python scripts/run_mcx.py --config baseline.yaml
'

# Attach a plot the second training finishes
push-to-phone wrap -- python train.py \
  && push-to-phone --attach ./runs/loss.png -t "loss curve"
```

## Config precedence

Later overrides earlier:

1. Built-in defaults (`NTFY_SERVER=https://ntfy.sh`, `NTFY_PRIORITY=default`)
2. `~/.config/push-to-phone/config` (sourced as bash)
3. Environment variables: `NTFY_TOPIC`, `NTFY_SERVER`, `NTFY_TOKEN`, `NTFY_PRIORITY`
4. Command-line flags

Use a different config path by setting `PUSH_TO_PHONE_CONFIG=/path/to/config`.

## Shell completion

```bash
# bash
source ~/Projects/push-to-phone/completions/push-to-phone.bash

# zsh (add the completions dir to fpath or source directly)
source ~/Projects/push-to-phone/completions/push-to-phone.zsh
```

## Tests

```bash
bash tests/smoke.sh        # 11 dry-run + exit-code smoke tests, no network
```

## Security note

ntfy.sh is a public relay. Anyone who knows your topic name can push to your phone. Treat the topic like a password: make it long and unguessable (`openssl rand -hex 16`). For stricter setups, self-host ntfy and set `NTFY_SERVER` + `NTFY_TOKEN`.

Your config file at `~/.config/push-to-phone/config` holds the topic; `chmod 600` it.

## License

MIT. See [LICENSE](LICENSE).
