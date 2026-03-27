# =============================================================
#   OpenClaw One-Line Installer for Windows - Techla Project
# =============================================================
#
# Usage (customer runs in PowerShell as Admin):
#
#   Set-ExecutionPolicy RemoteSigned -Scope Process -Force; iwr -useb https://raw.githubusercontent.com/theducdev/openclaw-one-line-installer/main/install.ps1 | iex
#
# Or with options:
#   $env:SKIP_CHROME="true"; iwr -useb https://URL/install.ps1 | iex
#   $env:API_KEY="sk-xxx"; iwr -useb https://URL/install.ps1 | iex
#
# =============================================================

$ErrorActionPreference = "Stop"

# --------------- Config ---------------
$SkipChrome = $env:SKIP_CHROME -eq "true"
$SkipShortcuts = $env:SKIP_SHORTCUTS -eq "true"
$SkipCodex = $env:SKIP_CODEX -eq "true"
$ApiKey = $env:API_KEY

# --------------- Check Admin ---------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Please run PowerShell as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell -> Run as Administrator, then run the command again." -ForegroundColor Yellow
    exit 1
}

# --------------- Banner ---------------
Write-Host @"

   ___                    ____ _
  / _ \ _ __   ___ _ __  / ___| | __ ___      __
 | | | | '_ \ / _ \ '_ \| |   | |/ _`` \ \ /\ / /
 | |_| | |_) |  __/ | | | |___| | (_| |\ V  V /
  \___/| .__/ \___|_| |_|\____|_|\__,_| \_/\_/
       |_|

  One-Line Installer for Windows — Techla Project

"@ -ForegroundColor Cyan

# =============================================
# Step 1: WSL
# =============================================
Write-Host "[Step 1/6] Checking WSL..." -ForegroundColor Cyan

$wslCheck = wsl --list --quiet 2>$null
if (-not $wslCheck) {
    Write-Host "Installing WSL with Ubuntu..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host ""
    Write-Host "=== WSL installed. Please RESTART your computer, then run this command again. ===" -ForegroundColor Red
    Write-Host ""
    exit 0
}
Write-Host "WSL is ready." -ForegroundColor Green

# --------------- Detect WSL user ---------------
$WslUser = (wsl -- whoami 2>$null).Trim()
if ([string]::IsNullOrEmpty($WslUser)) {
    $WslUser = Read-Host "Enter your WSL username"
    $WslUser = $WslUser.Trim()
}
Write-Host "WSL user: $WslUser" -ForegroundColor Gray

# =============================================
# Step 2: Configure systemd
# =============================================
Write-Host "`n[Step 2/6] Configuring WSL systemd..." -ForegroundColor Cyan

wsl -u root -e bash -c @'
cat > /etc/wsl.conf << 'EOF'
[boot]
systemd=true
[interop]
enabled=true
appendWindowsPath=true
EOF
'@

wsl --shutdown
Start-Sleep -Seconds 3
Write-Host "WSL configured." -ForegroundColor Green

# =============================================
# Step 3: Node.js
# =============================================
Write-Host "`n[Step 3/6] Installing Node.js 22..." -ForegroundColor Cyan

$nodeCheck = wsl -u $WslUser -- bash -c "node --version 2>/dev/null" 2>$null
if ($nodeCheck -match "v2[2-9]|v[3-9]") {
    Write-Host "Node.js already installed: $nodeCheck" -ForegroundColor Green
} else {
    wsl -u root -- bash -c "curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs"
    # Configure passwordless sudo
    wsl -u root -- bash -c "echo '$WslUser ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$WslUser"
    Write-Host "Node.js installed." -ForegroundColor Green
}

# =============================================
# Step 4: OpenClaw
# =============================================
Write-Host "`n[Step 4/6] Installing OpenClaw..." -ForegroundColor Cyan

wsl -u $WslUser -- bash -c "sudo npm install -g openclaw"
$version = wsl -u $WslUser -- openclaw --version 2>$null
Write-Host "OpenClaw installed: $version" -ForegroundColor Green

# =============================================
# Step 5: Chrome (optional)
# =============================================
if (-not $SkipChrome) {
    Write-Host "`n[Step 5/6] Installing Chrome in WSL..." -ForegroundColor Cyan

    $chromeCheck = wsl -u $WslUser -- bash -c "command -v google-chrome 2>/dev/null"
    if ($chromeCheck) {
        Write-Host "Chrome already installed." -ForegroundColor Green
    } else {
        wsl -u $WslUser -- bash -c "cd /tmp && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get install -f -y && rm -f google-chrome-stable_current_amd64.deb"
        Write-Host "Chrome installed." -ForegroundColor Green
    }
} else {
    Write-Host "`n[Step 5/6] Skipping Chrome." -ForegroundColor Gray
}

# =============================================
# Step 6: Desktop shortcuts
# =============================================
if (-not $SkipShortcuts) {
    Write-Host "`n[Step 6/6] Creating desktop shortcuts..." -ForegroundColor Cyan

    $Desktop = [Environment]::GetFolderPath("Desktop")

    @"
@echo off
wsl -u $WslUser -- openclaw tui
"@ | Out-File "$Desktop\OpenClaw-TUI.bat" -Encoding ASCII

    @"
@echo off
wsl -u $WslUser -- openclaw gateway status
pause
"@ | Out-File "$Desktop\OpenClaw-Status.bat" -Encoding ASCII

    @"
@echo off
wsl -u $WslUser -- openclaw gateway restart
echo Gateway restarted.
pause
"@ | Out-File "$Desktop\OpenClaw-Restart.bat" -Encoding ASCII

    Write-Host "Shortcuts created on Desktop." -ForegroundColor Green
} else {
    Write-Host "`n[Step 6/6] Skipping shortcuts." -ForegroundColor Gray
}

# =============================================
# Step 7: API Key (if provided)
# =============================================
if (-not [string]::IsNullOrEmpty($ApiKey)) {
    Write-Host "`nConfiguring API key..." -ForegroundColor Cyan
    wsl -u $WslUser -- bash -c "mkdir -p ~/.openclaw && echo '{\"apiKey\": \"$ApiKey\"}' > ~/.openclaw/config.json"
    Write-Host "API key configured." -ForegroundColor Green
}

# =============================================
# Step 8: GPT Codex OAuth Authentication
# =============================================
if (-not $SkipCodex) {
    Write-Host "`n=== GPT Codex Authentication ===" -ForegroundColor Cyan
    Write-Host "Connecting your OpenAI account for GPT Codex models..." -ForegroundColor Yellow

    # Run the OAuth flow inside WSL using Node.js (same PKCE logic as install.sh)
    $codexScript = @'
const http = require("http");
const crypto = require("crypto");
const { URL } = require("url");
const fs = require("fs");
const path = require("path");
const os = require("os");

const CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann";
const AUTH_URL = "https://auth.openai.com/oauth/authorize";
const TOKEN_URL = "https://auth.openai.com/oauth/token";
const SCOPE = "openid profile email offline_access";
const PORT = 1455;
const REDIRECT_URI = `http://localhost:${PORT}/auth/callback`;

const codeVerifier = crypto.randomBytes(32).toString("base64url");
const codeChallenge = crypto.createHash("sha256").update(codeVerifier).digest("base64url");
const state = crypto.randomBytes(16).toString("hex");

const params = new URLSearchParams({
    response_type: "code", client_id: CLIENT_ID, redirect_uri: REDIRECT_URI,
    scope: SCOPE, code_challenge: codeChallenge, code_challenge_method: "S256",
    state, id_token_add_organizations: "true", codex_cli_simplified_flow: "true", originator: "codex_cli_rs",
});
const authUrl = `${AUTH_URL}?${params}`;

const server = http.createServer(async (req, res) => {
    const url = new URL(req.url || "/", `http://localhost:${PORT}`);
    if (url.pathname !== "/auth/callback") { res.writeHead(404); res.end(); return; }
    const code = url.searchParams.get("code");
    const error = url.searchParams.get("error");
    if (error || !code || url.searchParams.get("state") !== state) {
        res.writeHead(200, {"Content-Type":"text/html"});
        res.end(`<html><body style="font-family:system-ui;text-align:center;padding:60px"><h2 style="color:red">Failed</h2><p>${error||"Invalid callback"}</p></body></html>`);
        process.exit(1);
    }
    try {
        const tokenBody = new URLSearchParams({ grant_type:"authorization_code", client_id:CLIENT_ID, code, redirect_uri:REDIRECT_URI, code_verifier:codeVerifier });
        const r = await fetch(TOKEN_URL, { method:"POST", headers:{"Content-Type":"application/x-www-form-urlencoded","Accept":"application/json"}, body:tokenBody });
        if (!r.ok) throw new Error(await r.text());
        const tokens = await r.json();
        let email = "default";
        try { if(tokens.id_token){const p=JSON.parse(Buffer.from(tokens.id_token.split(".")[1],"base64url").toString());email=p.email||"default";} } catch{}
        let accountId;
        try { const p=JSON.parse(Buffer.from(tokens.access_token.split(".")[1],"base64url").toString());accountId=p?.["https://api.openai.com/auth"]?.chatgpt_account_id; } catch{}
        const expiresAt = Date.now() + tokens.expires_in * 1000;
        const authDir = path.join(os.homedir(), ".openclaw","agents","main","agent");
        fs.mkdirSync(authDir, {recursive:true});
        const authPath = path.join(authDir, "auth-profiles.json");
        let store = {version:1,profiles:{},order:{},lastGood:{}};
        try { if(fs.existsSync(authPath)) store = JSON.parse(fs.readFileSync(authPath,"utf-8")); } catch{}
        const pid = `openai-codex:${email}`;
        store.profiles[pid] = {type:"oauth",provider:"openai-codex",access:tokens.access_token,refresh:tokens.refresh_token,expires:expiresAt,savedAt:Date.now(),accountId};
        if(!store.order) store.order={};
        if(!store.order["openai-codex"]) store.order["openai-codex"]=[];
        if(!store.order["openai-codex"].includes(pid)) store.order["openai-codex"].push(pid);
        if(!store.lastGood) store.lastGood={};
        store.lastGood["openai-codex"] = pid;
        fs.writeFileSync(authPath, JSON.stringify(store,null,2));
        const cfgPath = path.join(os.homedir(), ".openclaw","openclaw.json");
        let cfg = {};
        try { if(fs.existsSync(cfgPath)) cfg = JSON.parse(fs.readFileSync(cfgPath,"utf-8")); } catch{}
        cfg.agents=cfg.agents||{}; cfg.agents.defaults=cfg.agents.defaults||{}; cfg.agents.defaults.model={primary:"openai-codex/codex-mini-latest"};
        cfg.models=cfg.models||{}; cfg.models.providers=cfg.models.providers||{};
        cfg.models.providers["openai-codex"]={baseUrl:"https://api.openai.com/v1",api:"openai-responses",apiKeyEnv:"OPENAI_API_KEY"};
        cfg.gateway=cfg.gateway||{}; if(!cfg.gateway.mode) cfg.gateway.mode="local";
        fs.writeFileSync(cfgPath, JSON.stringify(cfg,null,2));
        res.writeHead(200,{"Content-Type":"text/html"});
        res.end(`<html><body style="font-family:system-ui;text-align:center;padding:60px"><h2 style="color:green">OpenAI Connected!</h2><p>Logged in as: <b>${email}</b></p><p>You can close this tab.</p><script>setTimeout(()=>window.close(),3000)</script></body></html>`);
        console.log(JSON.stringify({success:true,email,accountId}));
        setTimeout(()=>process.exit(0),500);
    } catch(e) {
        res.writeHead(500,{"Content-Type":"text/html"});
        res.end(`<html><body style="font-family:system-ui;text-align:center;padding:60px"><h2 style="color:red">Error</h2><p>${e.message}</p></body></html>`);
        process.exit(1);
    }
});
setTimeout(()=>{console.error("timeout");process.exit(1);},300000);
server.listen(PORT,"127.0.0.1",()=>{console.error("AUTH_URL:"+authUrl);});
'@

    # Write script to temp file in WSL and run it
    $tempScript = "/tmp/codex-oauth-$([guid]::NewGuid().ToString('N').Substring(0,8)).cjs"
    wsl -u $WslUser -- bash -c "cat > $tempScript << 'ENDSCRIPT'
$codexScript
ENDSCRIPT"

    # Start OAuth server and capture auth URL
    $logFile = "/tmp/codex-oauth-log.txt"
    wsl -u $WslUser -- bash -c "node $tempScript > /tmp/codex-result.json 2>$logFile &
        WAIT=0
        while ! grep -q 'AUTH_URL:' $logFile 2>/dev/null; do
            sleep 0.5
            WAIT=\$((WAIT+1))
            if [ \$WAIT -gt 10 ]; then echo 'TIMEOUT'; exit 1; fi
        done
        grep 'AUTH_URL:' $logFile | sed 's/AUTH_URL://'"

    $authUrlResult = wsl -u $WslUser -- bash -c "grep 'AUTH_URL:' $logFile 2>/dev/null | sed 's/AUTH_URL://'"

    if ($authUrlResult) {
        Write-Host "`nOpening browser for OpenAI login..." -ForegroundColor Yellow
        Start-Process $authUrlResult.Trim()
        Write-Host "Waiting for you to login in the browser..." -ForegroundColor Cyan
        Write-Host "(This will timeout in 5 minutes)`n" -ForegroundColor Gray

        # Wait for result
        $waitCount = 0
        $maxWait = 600  # 5 minutes in half-seconds
        while ($waitCount -lt $maxWait) {
            $result = wsl -u $WslUser -- bash -c "cat /tmp/codex-result.json 2>/dev/null" 2>$null
            if ($result -match '"success":true') {
                $email = ($result | ConvertFrom-Json).email
                Write-Host "GPT Codex authenticated! ($email)" -ForegroundColor Green
                Write-Host "Default model: openai-codex/codex-mini-latest" -ForegroundColor Green
                break
            }
            Start-Sleep -Milliseconds 500
            $waitCount++
        }

        if ($waitCount -ge $maxWait) {
            Write-Host "Codex OAuth timed out. You can set it up later." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Could not start OAuth flow. You can set it up later." -ForegroundColor Yellow
    }

    # Cleanup
    wsl -u $WslUser -- bash -c "rm -f $tempScript /tmp/codex-result.json $logFile" 2>$null
} else {
    Write-Host "`nSkipping GPT Codex auth." -ForegroundColor Gray
}

# =============================================
# Done
# =============================================
Write-Host @"

=============================================
      Setup Complete!
=============================================

What was installed:
  - WSL2 with Ubuntu
  - Node.js 22
  - OpenClaw $version
  - Chrome in WSL
  - Desktop shortcuts (TUI, Status, Restart)
  - GPT Codex OAuth (OpenAI account connected)

GPT Codex models available:
  codex-mini-latest         - Fast, lightweight
  gpt-5.4                   - Most capable
  gpt-5.3-codex             - Balanced

Next step - run in WSL:
  wsl
  openclaw onboard --install-daemon

Shortcuts on Desktop:
  OpenClaw-TUI.bat     - Terminal UI
  OpenClaw-Status.bat  - Check status
  OpenClaw-Restart.bat - Restart gateway

=============================================
"@ -ForegroundColor Green
