#!/bin/bash
# =============================================================
#   OpenClaw One-Line Installer - Techla Project
# =============================================================
#
# Usage (customer runs this single command):
#
#   curl -fsSL https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.sh | bash
#
# Or with options:
#   curl -fsSL https://URL/install.sh | bash -s -- --skip-chrome
#   curl -fsSL https://URL/install.sh | bash -s -- --api-key YOUR_KEY
#   curl -fsSL https://URL/install.sh | bash -s -- --codex   (login GPT Codex via OAuth)
#   curl -fsSL https://URL/install.sh | bash -s -- --skip-codex
#
# Supports: macOS, Ubuntu, Debian, Fedora, CentOS, RHEL, Arch
# =============================================================

set -e

# --------------- Config ---------------
NODE_VERSION="22"
SKIP_CHROME=false
SKIP_ONBOARD=false
SKIP_CODEX=false
USE_CODEX=true
API_KEY=""

# Codex OAuth Config (same as Codex CLI - whitelisted by OpenAI)
CODEX_CLIENT_ID="app_EMoamEEZ73f0CkXaXp7hrann"
CODEX_AUTH_URL="https://auth.openai.com/oauth/authorize"
CODEX_TOKEN_URL="https://auth.openai.com/oauth/token"
CODEX_SCOPE="openid profile email offline_access"
CODEX_CALLBACK_PORT=1455
CODEX_REDIRECT_URI="http://localhost:${CODEX_CALLBACK_PORT}/auth/callback"

for arg in "$@"; do
    case "$arg" in
        --skip-chrome)  SKIP_CHROME=true ;;
        --skip-onboard) SKIP_ONBOARD=true ;;
        --skip-codex)   SKIP_CODEX=true; USE_CODEX=false ;;
        --codex)        USE_CODEX=true ;;
        --api-key=*)    API_KEY="${arg#*=}" ;;
    esac
done

# --------------- Colors ---------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# --------------- Helpers ---------------
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()    { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# --------------- Banner ---------------
echo -e "${BOLD}${CYAN}"
cat << 'BANNER'

   ___                    ____ _
  / _ \ _ __   ___ _ __  / ___| | __ ___      __
 | | | | '_ \ / _ \ '_ \| |   | |/ _` \ \ /\ / /
 | |_| | |_) |  __/ | | | |___| | (_| |\ V  V /
  \___/| .__/ \___|_| |_|\____|_|\__,_| \_/\_/
       |_|

  One-Line Installer — Techla Project

BANNER
echo -e "${NC}"

# --------------- Detect OS ---------------
detect_os() {
    OS="unknown"
    DISTRO="unknown"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        OS="windows"
        DISTRO="windows"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS="linux"
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
            DISTRO="debian"
        elif [[ "$ID" == "fedora" || "$ID" == "centos" || "$ID" == "rhel" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
            DISTRO="rhel"
        elif [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
            DISTRO="arch"
        fi
    fi

    info "Detected: OS=$OS, Distro=$DISTRO"
}

# --------------- Check root/sudo ---------------
check_sudo() {
    if [[ "$EUID" -eq 0 ]]; then
        SUDO=""
    elif command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        fail "This script needs sudo. Please install sudo or run as root."
    fi
}

# --------------- Install dependencies ---------------
install_deps() {
    info "Installing system dependencies..."

    case "$DISTRO" in
        macos)
            if ! xcode-select -p &>/dev/null; then
                info "Installing Xcode CLI tools..."
                xcode-select --install 2>/dev/null || true
                echo ""
                warn "Please complete Xcode CLI tools install popup, then re-run:"
                echo "  curl -fsSL <url>/install.sh | bash"
                exit 1
            fi
            if ! command -v brew &>/dev/null; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add brew to PATH for Apple Silicon
                if [[ -f /opt/homebrew/bin/brew ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            ;;
        debian)
            $SUDO apt-get update -qq
            $SUDO apt-get install -y -qq curl wget git build-essential
            ;;
        rhel)
            $SUDO yum install -y curl wget git gcc-c++ make
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm curl wget git base-devel
            ;;
        *)
            fail "Unsupported distro: $DISTRO. Please install Node.js 22+ and OpenClaw manually."
            ;;
    esac

    success "Dependencies installed."
}

# --------------- Install Node.js ---------------
install_node() {
    # Check existing Node.js
    if command -v node &>/dev/null; then
        CURRENT=$(node --version | sed 's/v//' | cut -d. -f1)
        if [[ "$CURRENT" -ge "$NODE_VERSION" ]]; then
            success "Node.js already installed: $(node --version)"
            return 0
        fi
        warn "Node.js $(node --version) is too old, upgrading to v${NODE_VERSION}..."
    fi

    info "Installing Node.js ${NODE_VERSION}..."

    case "$DISTRO" in
        macos)
            brew install node@${NODE_VERSION}
            brew link --overwrite node@${NODE_VERSION} 2>/dev/null || true
            ;;
        debian)
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO apt-get install -y -qq nodejs
            ;;
        rhel)
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO yum install -y nodejs
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm nodejs npm
            ;;
    esac

    success "Node.js installed: $(node --version)"
}

# --------------- Install Chrome ---------------
install_chrome() {
    if [[ "$SKIP_CHROME" == true ]]; then
        info "Skipping Chrome install (--skip-chrome)."
        return 0
    fi

    # Check if already installed
    if command -v google-chrome &>/dev/null || command -v google-chrome-stable &>/dev/null; then
        success "Chrome already installed."
        return 0
    fi
    if [[ "$DISTRO" == "macos" && -d "/Applications/Google Chrome.app" ]]; then
        success "Chrome already installed."
        return 0
    fi

    info "Installing Google Chrome..."

    case "$DISTRO" in
        macos)
            brew install --cask google-chrome
            ;;
        debian)
            cd /tmp
            wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            $SUDO dpkg -i google-chrome-stable_current_amd64.deb || $SUDO apt-get install -f -y
            rm -f google-chrome-stable_current_amd64.deb
            ;;
        rhel)
            $SUDO dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
            ;;
        arch)
            $SUDO pacman -Sy --noconfirm chromium
            ;;
    esac

    success "Chrome installed."
}

# --------------- Install OpenClaw ---------------
install_openclaw() {
    info "Installing OpenClaw..."

    $SUDO npm install -g openclaw

    if command -v openclaw &>/dev/null; then
        success "OpenClaw installed: $(openclaw --version)"
    else
        fail "OpenClaw installation failed."
    fi
}

# --------------- Configure API key ---------------
configure_api_key() {
    if [[ -n "$API_KEY" ]]; then
        info "Configuring API key..."
        mkdir -p ~/.openclaw
        # Write config with API key
        cat > ~/.openclaw/config.json << EOF
{
  "apiKey": "$API_KEY"
}
EOF
        success "API key configured."
    fi
}

# =====================================================================
#  GPT Codex OAuth Authentication (PKCE Flow)
#
#  Same OAuth flow as Codex CLI:
#  1. Generate PKCE code_verifier + code_challenge (S256)
#  2. Open browser to OpenAI auth page
#  3. Listen on localhost:1455 for callback
#  4. Exchange auth code for access_token + refresh_token
#  5. Save tokens to ~/.openclaw/agents/main/agent/auth-profiles.json
#  6. Set default model to openai-codex/codex-mini-latest
# =====================================================================

# Generate PKCE code_verifier (43-128 chars, base64url)
generate_code_verifier() {
    openssl rand -base64 32 | tr '+/' '-_' | tr -d '='
}

# Generate PKCE code_challenge (SHA256 of verifier, base64url)
generate_code_challenge() {
    local verifier="$1"
    printf '%s' "$verifier" | openssl dgst -sha256 -binary | openssl base64 | tr '+/' '-_' | tr -d '='
}

# Generate random state
generate_state() {
    openssl rand -hex 16
}

# URL-encode a string
urlencode() {
    local string="$1"
    python3 -c "import urllib.parse; print(urllib.parse.quote('$string', safe=''))" 2>/dev/null \
        || node -e "console.log(encodeURIComponent('$string'))" 2>/dev/null \
        || echo "$string"
}

# Open URL in browser (cross-platform)
open_browser() {
    local url="$1"
    if [[ "$OS" == "macos" ]]; then
        open "$url"
    elif command -v xdg-open &>/dev/null; then
        xdg-open "$url" 2>/dev/null &
    elif command -v wslview &>/dev/null; then
        wslview "$url"
    else
        warn "Cannot open browser automatically."
        echo ""
        echo -e "${BOLD}Please open this URL in your browser:${NC}"
        echo ""
        echo "  $url"
        echo ""
    fi
}

# Start callback server, exchange code for tokens, save to OpenClaw
setup_codex_auth() {
    if [[ "$SKIP_CODEX" == true ]]; then
        info "Skipping GPT Codex auth (--skip-codex)."
        return 0
    fi

    echo ""
    echo -e "${BOLD}${CYAN}=== GPT Codex Authentication ===${NC}"
    echo ""
    info "Connecting your OpenAI account for GPT Codex models..."

    # Step 1: Generate PKCE
    local CODE_VERIFIER
    CODE_VERIFIER=$(generate_code_verifier)
    local CODE_CHALLENGE
    CODE_CHALLENGE=$(generate_code_challenge "$CODE_VERIFIER")
    local STATE
    STATE=$(generate_state)

    # Step 2: Build auth URL
    local AUTH_URL="${CODEX_AUTH_URL}?"
    AUTH_URL+="response_type=code"
    AUTH_URL+="&client_id=${CODEX_CLIENT_ID}"
    AUTH_URL+="&redirect_uri=$(urlencode "$CODEX_REDIRECT_URI")"
    AUTH_URL+="&scope=$(urlencode "$CODEX_SCOPE")"
    AUTH_URL+="&code_challenge=${CODE_CHALLENGE}"
    AUTH_URL+="&code_challenge_method=S256"
    AUTH_URL+="&state=${STATE}"
    AUTH_URL+="&id_token_add_organizations=true"
    AUTH_URL+="&codex_cli_simplified_flow=true"
    AUTH_URL+="&originator=codex_cli_rs"

    # Step 3: Start temporary callback server using Node.js
    info "Starting OAuth callback server on port ${CODEX_CALLBACK_PORT}..."

    # Create temporary Node.js script for the callback server
    local CALLBACK_SCRIPT
    CALLBACK_SCRIPT=$(mktemp /tmp/codex-oauth-XXXXXX.mjs)

    cat > "$CALLBACK_SCRIPT" << NODESCRIPT
import http from 'http';
import { URL } from 'url';
import fs from 'fs';
import path from 'path';
import os from 'os';

const CONFIG = {
    clientId: '${CODEX_CLIENT_ID}',
    tokenUrl: '${CODEX_TOKEN_URL}',
    redirectUri: '${CODEX_REDIRECT_URI}',
    codeVerifier: '${CODE_VERIFIER}',
    state: '${STATE}',
    port: ${CODEX_CALLBACK_PORT},
};

const server = http.createServer(async (req, res) => {
    const url = new URL(req.url || '/', \`http://localhost:\${CONFIG.port}\`);

    if (url.pathname !== '/auth/callback') {
        res.writeHead(404);
        res.end('Not found');
        return;
    }

    const code = url.searchParams.get('code');
    const state = url.searchParams.get('state');
    const error = url.searchParams.get('error');
    const errorDesc = url.searchParams.get('error_description');

    if (error) {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(\`<html><body style="font-family:system-ui;text-align:center;padding:60px">
            <h2 style="color:red">OAuth Failed</h2>
            <p>\${errorDesc || error}</p>
            <p style="color:#666">You can close this tab.</p>
        </body></html>\`);
        console.error(JSON.stringify({ error: errorDesc || error }));
        process.exit(1);
    }

    if (!code || state !== CONFIG.state) {
        res.writeHead(400, { 'Content-Type': 'text/html' });
        res.end(\`<html><body style="font-family:system-ui;text-align:center;padding:60px">
            <h2 style="color:red">Invalid callback</h2>
            <p>Missing code or state mismatch.</p>
        </body></html>\`);
        console.error(JSON.stringify({ error: 'state mismatch' }));
        process.exit(1);
    }

    try {
        // Exchange code for tokens
        const tokenBody = new URLSearchParams({
            grant_type: 'authorization_code',
            client_id: CONFIG.clientId,
            code,
            redirect_uri: CONFIG.redirectUri,
            code_verifier: CONFIG.codeVerifier,
        });

        const tokenResp = await fetch(CONFIG.tokenUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Accept': 'application/json',
            },
            body: tokenBody,
        });

        if (!tokenResp.ok) {
            const errText = await tokenResp.text();
            throw new Error('Token exchange failed: ' + errText);
        }

        const tokens = await tokenResp.json();

        // Extract email from id_token
        let email = 'default';
        try {
            if (tokens.id_token) {
                const payload = JSON.parse(
                    Buffer.from(tokens.id_token.split('.')[1], 'base64url').toString()
                );
                email = payload.email || 'default';
            }
        } catch {}

        // Extract accountId from access_token
        let accountId;
        try {
            const payload = JSON.parse(
                Buffer.from(tokens.access_token.split('.')[1], 'base64url').toString()
            );
            accountId = payload?.['https://api.openai.com/auth']?.chatgpt_account_id;
        } catch {}

        const expiresAt = Date.now() + (tokens.expires_in * 1000);

        // Save to ~/.openclaw/agents/main/agent/auth-profiles.json
        const authDir = path.join(os.homedir(), '.openclaw', 'agents', 'main', 'agent');
        fs.mkdirSync(authDir, { recursive: true });
        const authPath = path.join(authDir, 'auth-profiles.json');

        let store = { version: 1, profiles: {}, order: {}, lastGood: {} };
        try {
            if (fs.existsSync(authPath)) {
                store = JSON.parse(fs.readFileSync(authPath, 'utf-8'));
            }
        } catch {}

        const profileId = \`openai-codex:\${email}\`;
        store.profiles[profileId] = {
            type: 'oauth',
            provider: 'openai-codex',
            access: tokens.access_token,
            refresh: tokens.refresh_token,
            expires: expiresAt,
            savedAt: Date.now(),
            accountId,
        };

        if (!store.order) store.order = {};
        if (!store.order['openai-codex']) store.order['openai-codex'] = [];
        if (!store.order['openai-codex'].includes(profileId)) {
            store.order['openai-codex'].push(profileId);
        }
        if (!store.lastGood) store.lastGood = {};
        store.lastGood['openai-codex'] = profileId;

        fs.writeFileSync(authPath, JSON.stringify(store, null, 2));

        // Set default model in ~/.openclaw/openclaw.json
        const configPath = path.join(os.homedir(), '.openclaw', 'openclaw.json');
        let config = {};
        try {
            if (fs.existsSync(configPath)) {
                config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
            }
        } catch {}

        config.agents = config.agents || {};
        config.agents.defaults = config.agents.defaults || {};
        config.agents.defaults.model = { primary: 'openai-codex/codex-mini-latest' };
        config.models = config.models || {};
        config.models.providers = config.models.providers || {};
        config.models.providers['openai-codex'] = {
            baseUrl: 'https://api.openai.com/v1',
            api: 'openai-responses',
            apiKeyEnv: 'OPENAI_API_KEY',
        };
        config.gateway = config.gateway || {};
        if (!config.gateway.mode) config.gateway.mode = 'local';

        fs.writeFileSync(configPath, JSON.stringify(config, null, 2));

        // Success page
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end(\`<html><body style="font-family:system-ui;text-align:center;padding:60px">
            <h2 style="color:green">OpenAI Connected!</h2>
            <p>Logged in as: <strong>\${email}</strong></p>
            <p>Default model: <strong>codex-mini-latest</strong></p>
            <p style="color:#666">You can close this tab and return to the terminal.</p>
            <script>setTimeout(()=>window.close(),3000)</script>
        </body></html>\`);

        // Output result for the bash script to read
        console.log(JSON.stringify({ success: true, email, accountId, expiresAt }));
        setTimeout(() => process.exit(0), 500);

    } catch (err) {
        res.writeHead(500, { 'Content-Type': 'text/html' });
        res.end(\`<html><body style="font-family:system-ui;text-align:center;padding:60px">
            <h2 style="color:red">Error</h2>
            <p>\${err.message}</p>
        </body></html>\`);
        console.error(JSON.stringify({ error: err.message }));
        process.exit(1);
    }
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(JSON.stringify({ error: \`Port \${CONFIG.port} in use. Close any running Codex CLI first.\` }));
    } else {
        console.error(JSON.stringify({ error: err.message }));
    }
    process.exit(1);
});

// Timeout after 5 minutes
setTimeout(() => {
    console.error(JSON.stringify({ error: 'OAuth timeout (5 minutes)' }));
    process.exit(1);
}, 5 * 60 * 1000);

server.listen(CONFIG.port, '127.0.0.1', () => {
    console.error('READY');
});
NODESCRIPT

    # Start callback server in background
    local RESULT_FILE
    RESULT_FILE=$(mktemp /tmp/codex-result-XXXXXX.json)
    node "$CALLBACK_SCRIPT" > "$RESULT_FILE" 2>/tmp/codex-oauth-log.txt &
    local SERVER_PID=$!

    # Wait for server to be ready
    local WAIT_COUNT=0
    while ! grep -q "READY" /tmp/codex-oauth-log.txt 2>/dev/null; do
        sleep 0.5
        WAIT_COUNT=$((WAIT_COUNT + 1))
        if [[ $WAIT_COUNT -gt 10 ]]; then
            # Check if server failed
            if ! kill -0 $SERVER_PID 2>/dev/null; then
                local ERR_MSG
                ERR_MSG=$(cat /tmp/codex-oauth-log.txt 2>/dev/null)
                fail "Failed to start OAuth server: $ERR_MSG"
            fi
            fail "OAuth callback server timed out."
        fi
    done

    success "Callback server ready on port ${CODEX_CALLBACK_PORT}."

    # Step 4: Open browser
    echo ""
    echo -e "${BOLD}${YELLOW}Opening browser for OpenAI login...${NC}"
    echo ""
    open_browser "$AUTH_URL"
    echo -e "${CYAN}Waiting for you to login in the browser...${NC}"
    echo -e "${CYAN}(This will timeout in 5 minutes)${NC}"
    echo ""

    # Wait for callback server to finish
    wait $SERVER_PID 2>/dev/null
    local EXIT_CODE=$?

    # Clean up temp script
    rm -f "$CALLBACK_SCRIPT"

    # Check result
    if [[ $EXIT_CODE -eq 0 ]] && [[ -f "$RESULT_FILE" ]]; then
        local RESULT
        RESULT=$(cat "$RESULT_FILE")
        rm -f "$RESULT_FILE" /tmp/codex-oauth-log.txt

        if echo "$RESULT" | grep -q '"success":true'; then
            local EMAIL
            EMAIL=$(echo "$RESULT" | node -e "process.stdin.on('data',d=>{try{console.log(JSON.parse(d).email)}catch{console.log('unknown')}})" 2>/dev/null || echo "unknown")
            echo ""
            success "GPT Codex authenticated! (${EMAIL})"
            success "Default model set to: openai-codex/codex-mini-latest"
            echo ""
        else
            rm -f "$RESULT_FILE" /tmp/codex-oauth-log.txt
            warn "Codex OAuth did not complete. You can set it up later."
        fi
    else
        rm -f "$RESULT_FILE" /tmp/codex-oauth-log.txt
        warn "Codex OAuth did not complete. You can set it up later via ClawX-Web or manually."
    fi
}

# --------------- Run onboarding ---------------
run_onboard() {
    if [[ "$SKIP_ONBOARD" == true ]]; then
        info "Skipping onboarding (--skip-onboard)."
        return 0
    fi

    echo ""
    info "Starting OpenClaw onboarding wizard..."
    echo -e "${YELLOW}Follow the steps below to complete setup:${NC}"
    echo ""
    openclaw onboard --install-daemon
}

# --------------- Done ---------------
print_done() {
    echo -e "${BOLD}${GREEN}"
    cat << 'DONE'

=============================================
        Setup Complete!
=============================================

Useful commands:
  openclaw gateway start    — Start gateway
  openclaw gateway status   — Check status
  openclaw gateway restart  — Restart gateway
  openclaw tui              — Terminal UI

GPT Codex models available:
  codex-mini-latest         — Fast, lightweight
  gpt-5.4                   — Most capable
  gpt-5.3-codex             — Balanced

To reset everything:
  openclaw gateway stop
  rm -rf ~/.openclaw
  openclaw onboard --install-daemon

=============================================

DONE
    echo -e "${NC}"
}

# --------------- Main ---------------
main() {
    detect_os

    if [[ "$OS" == "windows" ]]; then
        fail "Windows detected. Please use PowerShell instead:\n  powershell -ExecutionPolicy RemoteSigned -File Setup-All.ps1"
    fi

    check_sudo
    install_deps
    install_node
    install_chrome
    install_openclaw
    configure_api_key
    setup_codex_auth
    print_done
    run_onboard
}

main "$@"
