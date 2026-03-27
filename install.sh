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
#  1. Generate PKCE code_verifier + code_challenge (S256)
#  2. Print login URL for user to copy
#  3. User logs in, browser redirects to localhost:1455 (will fail - that's OK)
#  4. User copies the full callback URL and pastes it back
#  5. Exchange auth code for access_token + refresh_token
#  6. Save tokens to ~/.openclaw/agents/main/agent/auth-profiles.json
#  7. Set default model to openai-codex/codex-mini-latest
# =====================================================================

setup_codex_auth() {
    if [[ "$SKIP_CODEX" == true ]]; then
        info "Skipping GPT Codex auth (--skip-codex)."
        return 0
    fi

    echo ""
    echo -e "${BOLD}${CYAN}=== GPT Codex Authentication ===${NC}"
    echo ""
    info "Connecting your OpenAI account for GPT Codex models..."

    # Step 1: Generate PKCE using Node.js
    local PKCE_JSON
    PKCE_JSON=$(node -e "const c=require('crypto');const v=c.randomBytes(32).toString('base64url');const ch=c.createHash('sha256').update(v).digest('base64url');const s=c.randomBytes(16).toString('hex');console.log(JSON.stringify({v,ch,s}))")

    local CODE_VERIFIER CODE_CHALLENGE STATE
    CODE_VERIFIER=$(echo "$PKCE_JSON" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).v))")
    CODE_CHALLENGE=$(echo "$PKCE_JSON" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).ch))")
    STATE=$(echo "$PKCE_JSON" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).s))")

    # Step 2: Build auth URL
    local ENCODED_REDIRECT ENCODED_SCOPE
    ENCODED_REDIRECT=$(node -e "console.log(encodeURIComponent('${CODEX_REDIRECT_URI}'))")
    ENCODED_SCOPE=$(node -e "console.log(encodeURIComponent('${CODEX_SCOPE}'))")

    local LOGIN_URL="${CODEX_AUTH_URL}"
    LOGIN_URL+="?response_type=code"
    LOGIN_URL+="&client_id=${CODEX_CLIENT_ID}"
    LOGIN_URL+="&redirect_uri=${ENCODED_REDIRECT}"
    LOGIN_URL+="&scope=${ENCODED_SCOPE}"
    LOGIN_URL+="&code_challenge=${CODE_CHALLENGE}"
    LOGIN_URL+="&code_challenge_method=S256"
    LOGIN_URL+="&state=${STATE}"
    LOGIN_URL+="&id_token_add_organizations=true"
    LOGIN_URL+="&codex_cli_simplified_flow=true"
    LOGIN_URL+="&originator=codex_cli_rs"

    # Step 3: Show login URL
    echo ""
    echo -e "${BOLD}${YELLOW}Copy this URL and open in your browser:${NC}"
    echo ""
    echo -e "  ${LOGIN_URL}"
    echo ""
    echo -e "${CYAN}After login, your browser will redirect to a URL like:${NC}"
    echo -e "  ${YELLOW}http://localhost:1455/auth/callback?code=...&state=...${NC}"
    echo ""
    echo -e "${CYAN}That page may show an error (connection refused) - that is normal.${NC}"
    echo -e "${BOLD}Copy the FULL URL from your browser address bar and paste it below.${NC}"
    echo ""

    read -rp "Paste callback URL here: " CALLBACK_URL

    if [[ -z "$CALLBACK_URL" ]]; then
        warn "No URL provided. Skipping Codex auth."
        return 0
    fi

    # Step 4: Exchange code for tokens using Node.js
    local EXCHANGE_RESULT
    EXCHANGE_RESULT=$(node -e "
const fs=require('fs'),path=require('path'),os=require('os');
(async()=>{try{
const u=new URL('$CALLBACK_URL');
const code=u.searchParams.get('code');
if(!code){console.log(JSON.stringify({error:'No code in URL'}));process.exit(1);}
const body=new URLSearchParams({grant_type:'authorization_code',client_id:'${CODEX_CLIENT_ID}',code,redirect_uri:'${CODEX_REDIRECT_URI}',code_verifier:'${CODE_VERIFIER}'});
const r=await fetch('${CODEX_TOKEN_URL}',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','Accept':'application/json'},body});
if(!r.ok){console.log(JSON.stringify({error:await r.text()}));process.exit(1);}
const t=await r.json();
let email='default';try{if(t.id_token){const p=JSON.parse(Buffer.from(t.id_token.split('.')[1],'base64url').toString());email=p.email||'default';}}catch{}
let accountId;try{const p=JSON.parse(Buffer.from(t.access_token.split('.')[1],'base64url').toString());accountId=p?.['https://api.openai.com/auth']?.chatgpt_account_id;}catch{}
const exp=Date.now()+t.expires_in*1000;
const ad=path.join(os.homedir(),'.openclaw','agents','main','agent');
fs.mkdirSync(ad,{recursive:true});
const ap=path.join(ad,'auth-profiles.json');
let s={version:1,profiles:{},order:{},lastGood:{}};
try{if(fs.existsSync(ap))s=JSON.parse(fs.readFileSync(ap,'utf-8'));}catch{}
const pid='openai-codex:'+email;
s.profiles[pid]={type:'oauth',provider:'openai-codex',access:t.access_token,refresh:t.refresh_token,expires:exp,savedAt:Date.now(),accountId};
if(!s.order)s.order={};if(!s.order['openai-codex'])s.order['openai-codex']=[];
if(!s.order['openai-codex'].includes(pid))s.order['openai-codex'].push(pid);
if(!s.lastGood)s.lastGood={};s.lastGood['openai-codex']=pid;
fs.writeFileSync(ap,JSON.stringify(s,null,2));
const cp=path.join(os.homedir(),'.openclaw','openclaw.json');
let c={};try{if(fs.existsSync(cp))c=JSON.parse(fs.readFileSync(cp,'utf-8'));}catch{}
c.agents=c.agents||{};c.agents.defaults=c.agents.defaults||{};c.agents.defaults.model={primary:'openai-codex/codex-mini-latest'};
c.models=c.models||{};c.models.providers=c.models.providers||{};
c.models.providers['openai-codex']={baseUrl:'https://api.openai.com/v1',api:'openai-responses',apiKeyEnv:'OPENAI_API_KEY'};
c.gateway=c.gateway||{};if(!c.gateway.mode)c.gateway.mode='local';
fs.writeFileSync(cp,JSON.stringify(c,null,2));
console.log(JSON.stringify({success:true,email,accountId}));
}catch(e){console.log(JSON.stringify({error:e.message}));process.exit(1);}})();
")

    if echo "$EXCHANGE_RESULT" | grep -q '"success":true'; then
        local EMAIL
        EMAIL=$(echo "$EXCHANGE_RESULT" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).email))" 2>/dev/null || echo "unknown")
        echo ""
        success "GPT Codex authenticated! (${EMAIL})"
        success "Default model set to: openai-codex/codex-mini-latest"
    else
        echo ""
        warn "Codex auth failed: $EXCHANGE_RESULT"
        warn "You can try again later."
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
