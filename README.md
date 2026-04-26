# 🐟 Fish Proxy — Installer

> This is the **installer repo** for Fish Proxy. It does not contain the site assets.
> The main Fish Proxy repo (assets, source code) lives at:
> **[github.com/hahahah67-pixel/Ultraviolet-App](https://github.com/hahahah67-pixel/Ultraviolet-App)**

This installer pulls from that repo automatically — you never need to touch it manually.

---

## One-Command Install

Run this on any Ubuntu/Debian Linux server (AWS EC2, DigitalOcean, etc.):

```bash
curl -fsSL https://raw.githubusercontent.com/hahahah67-pixel/fish-proxy-install/main/install.sh | bash
```

That's it. The installer will:

- Check your system and install anything missing (Node.js 22, pnpm, PM2, git)
- Clone the Fish Proxy assets from `hahahah67-pixel/Ultraviolet-App` automatically
- Install all dependencies
- Ask you what port to run on (default: 8080)
- Start the server and keep it running 24/7 with PM2
- Print your public URL when done

---

## How it connects to the main repo

```
fish-proxy-install        →   runs install.sh
install.sh                →   clones hahahah67-pixel/Ultraviolet-App
Ultraviolet-App           →   the actual Fish Proxy site (src/, public/, etc.)
```

If the main repo gets updated, existing installs can pull the latest with:

```bash
cd ~/fish-proxy && git pull && pnpm install && pm2 restart fish-proxy
```

---

## Requirements

- Ubuntu 20.04+ or Debian 11+
- A server or VM with internet access
- Port 8080 open in your firewall (or whatever port you choose)

Node.js, pnpm, PM2 and everything else gets installed automatically.

---

## After Installing

| Command | What it does |
|---|---|
| `pm2 status` | Check if Fish Proxy is running |
| `pm2 logs fish-proxy` | View live server logs |
| `pm2 restart fish-proxy` | Restart the server |
| `pm2 stop fish-proxy` | Stop the server |
| `pm2 delete fish-proxy` | Remove from PM2 |

---

## License

AGPL-3.0 — open source, free forever.
