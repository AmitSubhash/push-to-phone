# push-to-phone

A tiny shell CLI that sends a tappable notification from your Mac (or any Linux box) to your phone via [ntfy.sh](https://ntfy.sh). Tap the notification and the URL opens in whatever you've set as the default browser on your phone.

I built it so Claude Code running on my Mac can hand links off to Brave on my iPhone without me having to AirDrop them.

## What it looks like

```
$ push-to-phone -t "WG Rank 1" https://www.wg-gesucht.de/wg-zimmer-in-Regensburg-Galgenberg.13342296.html
Sent to https://ntfy.sh/your-unguessable-topic
```

On the phone, a notification titled "WG Rank 1" pops up. Tap it → opens the URL in the default browser. An "Open in Brave" action button is also attached.

## Install

```bash
git clone https://github.com/AmitSubhash/push-to-phone.git ~/Projects/push-to-phone
~/Projects/push-to-phone/install.sh           # symlinks bin/push-to-phone into ~/.local/bin
```

Then on your phone:

1. Install the [ntfy iOS](https://apps.apple.com/us/app/ntfy/id1625396347) or [Android](https://play.google.com/store/apps/details?id=io.heckel.ntfy) app.
2. Subscribe to a topic name only you know. Something like `your-unguessable-topic`, long and unguessable. ntfy.sh is a public relay, so the topic name is your only secret.
3. Export `NTFY_TOPIC=your-topic-name` in your shell rc, or pass it per-call.

On iOS, open `Settings → Apps → Default Browser App → Brave` if you want links to open there by default.

## Usage

```bash
push-to-phone <url>                           # tappable notification opening the URL
push-to-phone -t "Title" <url>                # custom title
push-to-phone -t "Title" -m "Body" <url>      # custom body
echo "some message" | push-to-phone           # plain text from stdin
push-to-phone -b < urls.txt                   # batch mode, one URL (or "Title||URL") per line
push-to-phone -p urgent <url>                 # set priority (min|low|default|high|urgent)
```

## Environment variables

| Variable        | Default                       | Purpose                                |
|-----------------|-------------------------------|----------------------------------------|
| `NTFY_TOPIC`    | **required, no default**      | Your ntfy.sh topic name                |
| `NTFY_SERVER`   | `https://ntfy.sh`             | Swap to your own self-hosted ntfy      |
| `NTFY_PRIORITY` | `default`                     | Notification priority                  |

## Security note

ntfy.sh is a public relay. Anyone who knows your topic name can push notifications to your phone. Treat the topic like a shared secret: make it long and unguessable. For stricter setups, self-host ntfy and point `NTFY_SERVER` at it.

## License

MIT. See [LICENSE](LICENSE).
