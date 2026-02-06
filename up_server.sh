#!/bin/bash

# Constants
REQUIRED_PROGRAMS=(git python3)
REPO_URL="https://github.com/Mak-Open-Communication/Messenger-Server.git"
REPO_BRANCH="main"
MIN_PYTHON_MAJOR_VERSION=3

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/server"
VENV_DIR="$SERVER_DIR/.venv"
REQUIREMENTS_FILE="$SERVER_DIR/requirements.txt"
ENV_FILE="$SERVER_DIR/.env"
ENV_EXAMPLE_FILE="$SERVER_DIR/.env.example"
DEPS_HASH_FILE="$VENV_DIR/.deps_hash"

# Logger functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
}

# Parse arguments
AUTO_UPDATE=true

for arg in "$@"; do
    case "$arg" in
        --disable-auto-update)
            AUTO_UPDATE=false
            ;;
    esac
done

# Check required programs
for prog in "${REQUIRED_PROGRAMS[@]}"; do
    if ! command -v "$prog" &>/dev/null; then
        log_error "'$prog' is not installed. Please install it and try again."
        exit 1
    fi
done

# Check Python version
PYTHON_MAJOR_VERSION=$(python3 -c "import sys; print(sys.version_info.major)")

if [ "$PYTHON_MAJOR_VERSION" -lt "$MIN_PYTHON_MAJOR_VERSION" ]; then
    log_error "Python major version must be >= $MIN_PYTHON_MAJOR_VERSION. Current: $PYTHON_MAJOR_VERSION."
    exit 1
fi

log "Python version: $(python3 --version)"

# Clone server if not exists
if [ ! -d "$SERVER_DIR/.git" ]; then
    log "Server not found. Cloning from $REPO_URL ..."
    if ! git clone -b "$REPO_BRANCH" "$REPO_URL" "$SERVER_DIR"; then
        log_error "Failed to clone repository."
        exit 1
    fi
    log "Repository cloned successfully."
fi

# Check for updates
log "Checking for updates..."

if ! git -C "$SERVER_DIR" fetch origin "$REPO_BRANCH" 2>/dev/null; then
    log_warn "Failed to fetch updates from remote. Continuing with current version."
else
    LOCAL_COMMIT=$(git -C "$SERVER_DIR" rev-parse HEAD)
    REMOTE_COMMIT=$(git -C "$SERVER_DIR" rev-parse "origin/$REPO_BRANCH")

    if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
        if [ "$AUTO_UPDATE" = true ]; then
            log "Update available (local: ${LOCAL_COMMIT:0:7}, remote: ${REMOTE_COMMIT:0:7}). Pulling..."

            if ! git -C "$SERVER_DIR" pull origin "$REPO_BRANCH"; then
                log_error "Failed to pull updates."
                exit 1
            fi
            log "Server updated successfully."
        else
            log_warn "Server is outdated (local: ${LOCAL_COMMIT:0:7}, remote: ${REMOTE_COMMIT:0:7}). Auto-update is disabled."
        fi
    else
        log "Server is up to date. (${LOCAL_COMMIT:0:7})"
    fi
fi

# Create venv if not exists
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    log "Creating virtual environment..."
    if ! python3 -m venv "$VENV_DIR"; then
        log_error "Failed to create virtual environment."
        exit 1
    fi
    log "Virtual environment created."
fi

# Check .env
if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_EXAMPLE_FILE" ]; then
        cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
        log_warn "==========================================="
        log_warn " .env file was not found!"
        log_warn " A copy has been created from .env.example."
        log_warn " Please configure: $ENV_FILE"
        log_warn " Then run this script again."
        log_warn "==========================================="
    else
        log_error ".env.example not found in $SERVER_DIR. Cannot create .env."
    fi
    exit 1
fi

# Install dependencies if needed
CURRENT_REQ_HASH=""
if [ -f "$REQUIREMENTS_FILE" ]; then
    CURRENT_REQ_HASH=$(md5sum "$REQUIREMENTS_FILE" | awk '{print $1}')
fi

INSTALLED_REQ_HASH=""
if [ -f "$DEPS_HASH_FILE" ]; then
    INSTALLED_REQ_HASH=$(cat "$DEPS_HASH_FILE")
fi

if [ "$CURRENT_REQ_HASH" != "$INSTALLED_REQ_HASH" ]; then
    log "Installing dependencies..."
    if ! "$VENV_DIR/bin/pip" install -r "$REQUIREMENTS_FILE"; then
        log_error "Failed to install dependencies."
        exit 1
    fi
    echo "$CURRENT_REQ_HASH" > "$DEPS_HASH_FILE"
    log "Dependencies installed successfully."
fi

# Start server
log "Starting server..."
cd "$SERVER_DIR" || exit 1
source "$VENV_DIR/bin/activate"
python3 -m src.main
