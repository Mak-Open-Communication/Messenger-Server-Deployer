# Messenger Server Deployer

A launcher script that automatically clones, updates, and runs the [Messenger Server](https://github.com/Mak-Open-Communication/Messenger-Server).

## Prerequisites

- **git**
- **Python 3.***

## Quick Start

```bash
chmod +x up_server.sh
./up_server.sh
```

On the first run the script will:

1. Clone the server repository into `./server`
2. Create a Python virtual environment at `./server/.venv`
3. Copy `.env.example` to `.env` and **exit** with a prompt to configure it

Edit `./server/.env` with your settings (database, S3, etc.), then run the script again to start the server.

## What It Does on Each Launch

1. Verifies `git` and `python3` are installed
2. Checks Python version (>= 3)
3. Clones the server repository if `./server` doesn't exist
4. Fetches the latest commits from the `main` branch and pulls updates if available
5. Creates `./server/.venv` if it doesn't exist
6. Checks for `./server/.env` — copies from `.env.example` and exits if missing
7. Reinstalls dependencies if `requirements.txt` changed or the venv was just created
8. Starts the server (`python3 -m src.main`)

## Options

| Flag                    | Description                                                                                                       |
|-------------------------|-------------------------------------------------------------------------------------------------------------------|
| `--disable-auto-update` | Skip `git pull`. Shows a warning if the local version is behind remote, but launches the existing version anyway. |

## License

This deployer is part of the [Mak Open Communication](https://github.com/Mak-Open-Communication/Messenger-Server) project.
