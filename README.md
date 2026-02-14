<div align="center">

```
     ██████╗ ███╗   ██╗████████╗ █████╗ ██████╗
      ██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗
      ██║   ██║██╔██╗ ██║   ██║   ███████║██████╔╝
     ██║   ██║██║╚██╗██║   ██║   ██╔══██║██╔═══╝
 ╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║
  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝
```

*Your audiobooks, always on tap.*

[![CI](https://github.com/brianirish/ontap/actions/workflows/ci.yml/badge.svg)](https://github.com/brianirish/ontap/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/github/license/brianirish/ontap)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-rmcrackan%2Flibation-blue?logo=docker)](https://hub.docker.com/r/rmcrackan/libation)
[![Platform](https://img.shields.io/badge/platform-linux%20%7C%20NAS%20%7C%20Pi-lightgrey)]()

</div>

---

## What is this?

**OnTap is a turnkey Docker setup that automatically checks your Audible library and downloads new audiobooks on a schedule.** It uses the [Libation](https://github.com/rmcrackan/Libation) CLI under the hood, with optional Plex integration to trigger a library scan when new books arrive. Set it up once, forget about it.

## Prerequisites

- **Docker** and **Docker Compose** installed
- **Libation** installed locally (just for the initial account setup — you won't need it after)
- An **Audible account** linked in Libation

## Quick Start

**1. Clone the repo**

```bash
git clone https://github.com/brianirish/ontap.git
cd ontap
```

**2. Copy your Libation config**

Run the helper script to copy your auth credentials:

```bash
bash scripts/copy-config.sh
```

Or manually copy `AccountsSettings.json` (and optionally `Settings.json`) from your Libation config directory to `./config/`:

| OS      | Libation Config Path                        |
|---------|---------------------------------------------|
| macOS   | `~/Library/Application Support/Libation/`   |
| Linux   | `~/.config/Libation/`                       |
| Windows | `%LOCALAPPDATA%\Libation\`                  |

**3. Configure environment**

```bash
cp .env.example .env
```

Edit `.env` and set `BOOKS_PATH` to where you want audiobooks stored (e.g., your Plex audiobook library path).

**4. Start it up**

```bash
docker compose up -d
```

**5. Verify it's working**

```bash
docker logs ontap
```

You should see Libation scanning your library and downloading any new books. After the initial run, it will check again every 6 hours (configurable).

## How It Works

```
┌─────────┐     ┌──────────┐     ┌────────────┐     ┌─────────┐
│  Start   │────▶│   Scan   │────▶│  Download  │────▶│  Sleep  │──╮
└─────────┘     │  Audible │     │ new books  │     │  (6h)   │  │
                └──────────┘     └────────────┘     └─────────┘  │
                     ▲                                            │
                     └────────────────────────────────────────────╯
```

> [!TIP]
> **Token self-healing:** Audible auth tokens expire periodically. Libation's underlying AudibleApi library handles token refresh automatically — no manual intervention needed. The container is fully self-healing.

## Configuration

| Variable          | Default       | Description                                    |
|-------------------|---------------|------------------------------------------------|
| `SLEEP_TIME`      | `6h`          | How often to check for new books               |
| `CONFIG_PATH`     | `./config`    | Path to Libation config (AccountsSettings.json)|
| `BOOKS_PATH`      | `./books`     | Where audiobooks are downloaded                 |
| `PLEX_URL`        | —             | Plex server URL (for Plex integration)         |
| `PLEX_TOKEN`      | —             | Plex API token (for Plex integration)          |
| `PLEX_LIBRARY_ID` | `1`           | Plex library section ID for audiobooks         |

---

## Plex Integration

To automatically trigger a Plex library scan when new audiobooks are downloaded:

**1. Get your Plex token**

Follow [Plex's guide](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) to find your `X-Plex-Token`.

**2. Find your library section ID**

```bash
curl "http://YOUR_PLEX_IP:32400/library/sections?X-Plex-Token=YOUR_TOKEN"
```

Look for your audiobook library's `key` attribute.

**3. Update your `.env`**

```env
PLEX_URL=http://192.168.1.100:32400
PLEX_TOKEN=your-plex-token
PLEX_LIBRARY_ID=3
```

**4. Start with the Plex overlay**

```bash
docker compose -f docker-compose.yml -f docker-compose.plex.yml up -d
```

This adds a lightweight sidecar container that watches your books directory for new files and triggers a Plex library scan when changes are detected.

---

<details>
<summary><strong>Platform Notes</strong></summary>

<br>

This works anywhere Docker runs. A few platform-specific tips:

**Synology DSM**
- Use Container Manager (or docker CLI via SSH)
- Set `BOOKS_PATH` to a shared folder path like `/volume1/media/audiobooks`
- Ensure the container user has write permissions to the destination folder

**UGREEN NAS**
- Works out of the box via SSH or Portainer
- Same shared folder path approach as Synology

**Unraid**
- Works via Docker tab or Compose Manager plugin
- Set `BOOKS_PATH` to your media share (e.g., `/mnt/user/media/audiobooks`)

**TrueNAS SCALE**
- Deploy via Apps or custom Docker Compose
- Use a dataset path for `BOOKS_PATH`

**Raspberry Pi**
- Works on Pi 4+ with Docker installed
- The Libation image supports ARM64

</details>

---

<details>
<summary><strong>Troubleshooting</strong></summary>

<br>

**Container exits immediately**
- Check `docker logs ontap` for errors
- Make sure `./config/AccountsSettings.json` exists and isn't empty
- Verify the file was copied correctly: `cat config/AccountsSettings.json | python3 -m json.tool`

**Authentication errors**
- Open Libation on your desktop, remove and re-add your Audible account
- Re-run `bash scripts/copy-config.sh` to copy the fresh credentials
- Restart the container: `docker compose restart`

**Books not downloading**
- Check that `BOOKS_PATH` exists and is writable
- Look at `docker logs ontap` for specific error messages
- Ensure you have enough disk space

**Plex not updating**
- Verify your Plex token is correct: `curl "http://YOUR_PLEX_IP:32400/identity?X-Plex-Token=YOUR_TOKEN"`
- Check the sidecar logs: `docker logs ontap-plex-notify`
- Make sure `PLEX_LIBRARY_ID` matches your audiobook library

**Permission issues on NAS**
- The container runs as root by default
- If your NAS uses specific user/group IDs, you may need to `chown` the config and books directories

</details>

---

## Credits

Built on [Libation](https://github.com/rmcrackan/Libation) by rmcrackan — the engine that makes this all work.
[Docker image](https://hub.docker.com/r/rmcrackan/libation) maintained by the Libation project.
