#!/usr/bin/env bash
set -euo pipefail

# copy-config.sh - Copy Libation auth config to OnTap's config directory
#
# Detects your OS, finds the Libation config directory, and copies
# the necessary auth files so the Docker container can use them.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"

# Detect OS and find Libation config path
detect_libation_dir() {
    case "$(uname -s)" in
        Darwin)
            echo "$HOME/Library/Application Support/Libation"
            ;;
        Linux)
            # Check for WSL
            if grep -qi microsoft /proc/version 2>/dev/null; then
                # WSL - check Windows AppData first
                local win_appdata
                win_appdata="$(cmd.exe /C "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r')" || true
                if [[ -n "$win_appdata" ]]; then
                    local wsl_path
                    wsl_path="$(wslpath "$win_appdata" 2>/dev/null)/Libation" || true
                    if [[ -d "$wsl_path" ]]; then
                        echo "$wsl_path"
                        return
                    fi
                fi
            fi
            echo "$HOME/.config/Libation"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "$LOCALAPPDATA/Libation"
            ;;
        *)
            echo ""
            ;;
    esac
}

LIBATION_DIR="$(detect_libation_dir)"

if [[ -z "$LIBATION_DIR" ]]; then
    echo "Error: Could not detect your OS. Please copy your Libation config files manually."
    echo "Copy AccountsSettings.json and Settings.json to: $CONFIG_DIR/"
    exit 1
fi

if [[ ! -d "$LIBATION_DIR" ]]; then
    echo "Error: Libation config directory not found at: $LIBATION_DIR"
    echo ""
    echo "Make sure Libation is installed and you've logged into your Audible account at least once."
    echo "Download Libation: https://github.com/rmcrackan/Libation/releases"
    exit 1
fi

# Check for required files
ACCOUNTS_FILE="$LIBATION_DIR/AccountsSettings.json"
SETTINGS_FILE="$LIBATION_DIR/Settings.json"

if [[ ! -f "$ACCOUNTS_FILE" ]]; then
    echo "Error: AccountsSettings.json not found in $LIBATION_DIR"
    echo "Open Libation and add your Audible account first."
    exit 1
fi

# Validate AccountsSettings.json has content
if [[ ! -s "$ACCOUNTS_FILE" ]]; then
    echo "Error: AccountsSettings.json is empty. Open Libation and add your Audible account."
    exit 1
fi

# Create config directory
mkdir -p "$CONFIG_DIR"

# Copy files
echo "Copying Libation config from: $LIBATION_DIR"
cp "$ACCOUNTS_FILE" "$CONFIG_DIR/"
echo "  -> AccountsSettings.json copied"

if [[ -f "$SETTINGS_FILE" ]]; then
    cp "$SETTINGS_FILE" "$CONFIG_DIR/"
    echo "  -> Settings.json copied"
else
    echo "  -> Settings.json not found (optional, skipping)"
fi

# Validate the copy
if [[ -f "$CONFIG_DIR/AccountsSettings.json" ]] && [[ -s "$CONFIG_DIR/AccountsSettings.json" ]]; then
    echo ""
    echo "Config copied successfully to: $CONFIG_DIR/"
    echo ""
    echo "Next steps:"
    echo "  1. cp .env.example .env"
    echo "  2. Edit .env and set BOOKS_PATH to your audiobook directory"
    echo "  3. docker compose up -d"
else
    echo ""
    echo "Error: Something went wrong during copy. Check permissions and try again."
    exit 1
fi
