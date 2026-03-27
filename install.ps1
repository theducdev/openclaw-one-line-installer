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
    Write-Host "Connecting your OpenAI account for GPT Codex models...`n" -ForegroundColor Yellow

    # Step 1: Generate PKCE values using Node.js in WSL
    $pkceJson = wsl -u $WslUser -- node -e "const c=require('crypto');const v=c.randomBytes(32).toString('base64url');const ch=c.createHash('sha256').update(v).digest('base64url');const s=c.randomBytes(16).toString('hex');console.log(JSON.stringify({v,ch,s}))"

    $pkce = $pkceJson | ConvertFrom-Json
    $codeVerifier = $pkce.v
    $codeChallenge = $pkce.ch
    $state = $pkce.s

    # Step 2: Build auth URL
    $clientId = "app_EMoamEEZ73f0CkXaXp7hrann"
    $redirectUri = "http://localhost:1455/auth/callback"
    $scope = "openid profile email offline_access"

    $authUrl = "https://auth.openai.com/oauth/authorize" +
        "?response_type=code" +
        "&client_id=$clientId" +
        "&redirect_uri=$([uri]::EscapeDataString($redirectUri))" +
        "&scope=$([uri]::EscapeDataString($scope))" +
        "&code_challenge=$codeChallenge" +
        "&code_challenge_method=S256" +
        "&state=$state" +
        "&id_token_add_organizations=true" +
        "&codex_cli_simplified_flow=true" +
        "&originator=codex_cli_rs"

    # Step 3: Show login link
    Write-Host "Copy this URL and open in your browser:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  $authUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "After login, your browser will redirect to a URL starting with:" -ForegroundColor Yellow
    Write-Host "  http://localhost:1455/auth/callback?code=...&state=..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "That page may show an error (connection refused) - that is normal." -ForegroundColor Gray
    Write-Host "Copy the FULL URL from your browser address bar and paste it below." -ForegroundColor Yellow
    Write-Host ""

    $callbackUrl = Read-Host "Paste callback URL here"

    if ([string]::IsNullOrWhiteSpace($callbackUrl)) {
        Write-Host "No URL provided. Skipping Codex auth." -ForegroundColor Yellow
    } else {
        # Step 4: Exchange code for tokens using Node.js in WSL
        # Escape the callback URL and code verifier for safe passing
        $escapedCallback = $callbackUrl.Replace("'", "'\''")
        $escapedVerifier = $codeVerifier.Replace("'", "'\''")

        $exchangeResult = wsl -u $WslUser -- node -e @"
const fs=require('fs'),path=require('path'),os=require('os');
(async()=>{try{
const u=new URL('$escapedCallback');
const code=u.searchParams.get('code');
if(!code){console.log(JSON.stringify({error:'No code in URL'}));process.exit(1);}
const body=new URLSearchParams({grant_type:'authorization_code',client_id:'$clientId',code,redirect_uri:'$redirectUri',code_verifier:'$escapedVerifier'});
const r=await fetch('https://auth.openai.com/oauth/token',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded','Accept':'application/json'},body});
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
"@

        if ($exchangeResult -match '"success":true') {
            $resultObj = $exchangeResult | ConvertFrom-Json
            Write-Host ""
            Write-Host "GPT Codex authenticated! ($($resultObj.email))" -ForegroundColor Green
            Write-Host "Default model: openai-codex/codex-mini-latest" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "Codex auth failed: $exchangeResult" -ForegroundColor Red
            Write-Host "You can try again later." -ForegroundColor Yellow
        }
    }
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
