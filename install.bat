@echo off
rem ============================================================================
rem  Server pack installer (Paper + plugins) - Windows 10/11
rem  Reads versions and plugins from plugins.json (same file used by install.sh).
rem
rem  Usage:  install.bat [--accept-eula] [--config path\plugins.json] [folder]
rem        (default folder: .\server, next to this script)
rem  Requirements: Windows 10+ (PowerShell 5.1 already installed) and Java 21+ to run.
rem  Optional:   set GITHUB_TOKEN=xxxx  (avoids GitHub's 60 req/h limit)
rem ============================================================================
setlocal
set "SELF=%~f0"
set "CONFIG_PATH=%~dp0server\plugins.json"
set "SERVER_DIR=%~dp0server"
set "ACCEPT_EULA=0"

:args
if "%~1"=="" goto run
if /i "%~1"=="--accept-eula" (
    set "ACCEPT_EULA=1"
) else if /i "%~1"=="--config" (
    set "CONFIG_PATH=%~2"
    shift
) else (
    set "SERVER_DIR=%~1"
)
shift
goto args

:run
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[IO.File]::ReadAllText($env:SELF,[Text.Encoding]::UTF8); $i=$s.LastIndexOf('#PS1'+'START'); & ([scriptblock]::Create($s.Substring($i)))"
set "RC=%ERRORLEVEL%"
rem Se foi aberto com duplo clique, mantem a janela aberta
echo %cmdcmdline% | find /i "/c" >nul && pause
exit /b %RC%

#PS1START
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$UA         = 'server-pack-installer/2.0'
$ServerDir  = $env:SERVER_DIR
$ConfigPath = $env:CONFIG_PATH
$AcceptEula = ($env:ACCEPT_EULA -eq '1')

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Good($m) { Write-Host " [OK] $m" -ForegroundColor Green }
function Bad($m)  { Write-Host " [ERROR] $m" -ForegroundColor Red }

# ----------------------------- configuração ------------------------------------
if (-not (Test-Path -LiteralPath $ConfigPath)) { Bad "Config not found: $ConfigPath"; exit 1 }
try { $cfg = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { Bad "Invalid JSON in $ConfigPath"; exit 1 }
$McVersion = $cfg.minecraftVersion
if (-not $McVersion) { Bad "'minecraftVersion' missing in $ConfigPath"; exit 1 }

$PluginsDir = Join-Path $ServerDir 'plugins'
New-Item -ItemType Directory -Force -Path $PluginsDir | Out-Null

$GhHeaders = @{ 'User-Agent' = $UA; 'Accept' = 'application/vnd.github+json' }
if ($env:GITHUB_TOKEN) { $GhHeaders['Authorization'] = "Bearer $env:GITHUB_TOKEN" }
$UaHeaders = @{ 'User-Agent' = $UA }

# --------------------------- manifesto (limpa versões antigas) -----------------
$ManifestPath = Join-Path $ServerDir '.install-manifest.json'
$Manifest = @{}
if (Test-Path -LiteralPath $ManifestPath) {
  try {
    (Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json).PSObject.Properties |
      ForEach-Object { $Manifest[$_.Name] = $_.Value }
  } catch { $Manifest = @{} }
}
function Record($key, $rel) {
  $old = $Manifest[$key]
  if ($old -and $old -ne $rel) {
    $oldPath = Join-Path $ServerDir $old
    if (Test-Path -LiteralPath $oldPath) { Remove-Item -Force -LiteralPath $oldPath; Write-Host "   removed old version: $old" }
  }
  $Manifest[$key] = $rel
  $json = $Manifest | ConvertTo-Json
  [IO.File]::WriteAllText((Join-Path (Resolve-Path $ServerDir) '.install-manifest.json'), $json, (New-Object Text.UTF8Encoding $false))
}

# --------------------------------- download ------------------------------------
function Save-Jar($url, $dest, $sha) {
  $tmp = "$dest.part"
  try {
    Invoke-WebRequest -Uri $url -OutFile $tmp -Headers $UaHeaders -UseBasicParsing
    $fs = [IO.File]::OpenRead($tmp)
    try { $b1 = $fs.ReadByte(); $b2 = $fs.ReadByte() } finally { $fs.Dispose() }
    if ($b1 -ne 0x50 -or $b2 -ne 0x4B) { throw 'the downloaded file is not a valid .jar' }
    if ($sha -and ((Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash -ne $sha)) { throw 'SHA-256 does not match' }
    Move-Item -Force -LiteralPath $tmp -Destination $dest
  } catch {
    Remove-Item -Force -ErrorAction SilentlyContinue -LiteralPath $tmp
    $msg = $_.Exception.Message
    $resp = $_.Exception.Response
    if ($resp -and $resp.ResponseUri) { $msg = "$msg [at $($resp.ResponseUri.Host)]" }
    throw $msg
  }
}

# ------------------------------- resolvedores ----------------------------------
# No PowerShell 5.1, Invoke-RestMethod devolve um array JSON como UM objeto só (array aninhado).
# Esta função devolve sempre uma lista "achatada" de itens.
function Get-JsonList($uri) {
  @(Invoke-RestMethod -Uri $uri -Headers $UaHeaders -UseBasicParsing | ForEach-Object { $_ })
}

function New-Dl($url, $file, $sha, $version = $null) { [pscustomobject]@{ Url = $url; File = $file; Sha256 = $sha; Version = $version } }

function Resolve-GitHub($p, $ver) {
  $re = if ($p.assetRegex) { $p.assetRegex } else { '\.jar$' }
  $eps = if ($ver -eq 'latest') { @('latest') } else { @("tags/$ver", "tags/v$ver", "tags/$($ver.TrimStart('v'))") }
  foreach ($e in $eps) {
    try { $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$($p.repo)/releases/$e" -Headers $GhHeaders -UseBasicParsing }
    catch { continue }
    $a = $rel.assets | Where-Object { $_.name -match $re -and $_.name -notmatch 'sources|javadoc' } | Select-Object -First 1
    if ($a) { return New-Dl $a.browser_download_url $a.name $null }
  }
  throw "release '$ver' not found at github.com/$($p.repo)"
}

function Resolve-GeyserMC($p, $ver) {
  $plat = if ($p.platform) { $p.platform } else { 'spigot' }
  $base = "https://download.geysermc.org/v2/projects/$($p.project)/versions/$ver/builds"
  try { $j = Invoke-RestMethod -Uri "$base/latest" -Headers $UaHeaders -UseBasicParsing }
  catch { throw 'build not found in GeyserMC API' }
  $build = if ($j.build) { $j.build } else { 'latest' }
  $d = $j.downloads.$plat
  $file = if ($d.name) { $d.name } else { "$($p.project)-$plat.jar" }
  New-Dl "$base/$build/downloads/$plat" $file $d.sha256
}

function Resolve-Hangar($p, $ver) {
  $plat = if ($p.platform) { $p.platform } else { 'PAPER' }
  if ($ver -eq 'latest') {
    $ver = ([string](Invoke-RestMethod -Uri "https://hangar.papermc.io/api/v1/projects/$($p.project)/latestrelease" -Headers $UaHeaders -UseBasicParsing)).Trim()
  }
  New-Dl "https://hangar.papermc.io/api/v1/projects/$($p.project)/versions/$ver/$plat/download" "$($p.project)-$ver.jar" $null
}

function Resolve-Modrinth($p, $ver) {
  $slug = $p.slug
  $v = $null
  if ($ver -eq 'latest') {
    $q = 'loaders=' + [uri]::EscapeDataString('["paper","spigot","bukkit"]') +
         '&game_versions=' + [uri]::EscapeDataString("[`"$McVersion`"]") +
         '&include_changelog=false'
    try { $vs = Get-JsonList "https://api.modrinth.com/v2/project/$slug/version?$q" }
    catch { throw "project '$slug' not found on Modrinth" }
    $v = $vs | Where-Object { $_.version_type -eq 'release' } | Select-Object -First 1
    if (-not $v) { $v = $vs | Select-Object -First 1 }
  } else {
    foreach ($t in @($ver, "v$ver", $ver.TrimStart('v'))) {
      try { $v = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$slug/version/$([uri]::EscapeDataString($t))" -Headers $UaHeaders -UseBasicParsing; break }
      catch { $v = $null }
    }
  }
  if (-not $v) { throw "version '$ver' not found on Modrinth (project $slug, MC $McVersion)" }
  $f = $v.files | Where-Object { $_.primary } | Select-Object -First 1
  if (-not $f) { $f = $v.files | Select-Object -First 1 }
  if (-not $f) { throw 'the Modrinth version has no file' }
  New-Dl $f.url $f.filename $null
}

function Resolve-Spigot($p, $ver) {
  $api   = "https://api.spiget.org/v2/resources/$($p.resourceId)"
  $want  = $ver.TrimStart('v')
  $allow = [bool]$p.allowLatest
  $list = @(); $latestName = $null
  try { $list = Get-JsonList "$api/versions?size=200&sort=-releaseDate" } catch {}
  try { $latestName = ([string](Invoke-RestMethod -Uri "$api/versions/latest" -Headers $UaHeaders -UseBasicParsing).name).Trim().TrimStart('v') } catch {}
  # /download delivers the LATEST version (path that Spiget manages itself).
  # Older versions go through spigotmc.org, protected by Cloudflare, and often return 403.
  $n = if ($latestName) { $latestName } else { 'latest' }
  $latestDl = New-Dl "$api/download" "$($p.name)-$n.jar" $null $latestName
  if ($ver -eq 'latest' -or $latestName -eq $want) { return $latestDl }
  $hit = $list | Where-Object { ([string]$_.name).Trim().TrimStart('v') -eq $want } | Select-Object -First 1
  if ($hit) {
    $dl = New-Dl "$api/versions/$($hit.id)/download" "$($p.name)-$want.jar" $null $want
    if ($allow -and $latestName) { $dl | Add-Member -NotePropertyName Fallback -NotePropertyValue $latestDl }
    return $dl
  }
  if ($allow -and $latestName) {
    Write-Host "   [WARN] version '$ver' not in Spiget list; using latest ($latestName) because allowLatest=true." -ForegroundColor Yellow
    return $latestDl
  }
  $names = ($list | Select-Object -First 8 | ForEach-Object { $_.name }) -join ', '
  if (-not $names) { $names = 'none (API down or external resource?)' }
  throw "version '$ver' not found on Spiget (resource $($p.resourceId)). Latest: '$latestName'. Known: $names"
}

# versão declarada no plugin.yml do .jar ($null se não for possível ler)
function Get-JarVersion($path) {
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [IO.Compression.ZipFile]::OpenRead($path)
    try {
      $e = $z.GetEntry('plugin.yml')
      if ($e) {
        $rd = New-Object IO.StreamReader($e.Open()); $t = $rd.ReadToEnd(); $rd.Dispose()
        if ($t -match '(?m)^version:\s*[''"]?([^''"\s]+)') { return $Matches[1] }
      }
    } finally { $z.Dispose() }
  } catch {}
  return $null
}

$Ok = New-Object Collections.Generic.List[string]
$Failed = New-Object Collections.Generic.List[string]

# ----------------------------------- PAPER -------------------------------------
Info "Paper $McVersion (latest build)"
try {
  $b = Invoke-RestMethod -Uri "https://fill.papermc.io/v3/projects/paper/versions/$McVersion/builds/latest" -Headers $UaHeaders -UseBasicParsing
  $d = $b.downloads.'server:default'
  if (-not $d.url) { throw "version $McVersion not found in PaperMC API" }
  Save-Jar $d.url (Join-Path $ServerDir 'paper.jar') $d.checksums.sha256
  Record 'Paper' 'paper.jar'
  Good "Paper $McVersion build $($b.id) -> paper.jar"
  $Ok.Add('Paper')
} catch {
  Bad "Paper: $($_.Exception.Message)"; $Failed.Add('Paper')
}

# ---------------------------------- PLUGINS ------------------------------------
foreach ($p in $cfg.plugins) {
  $name = $p.name
  $src  = "$($p.source)".ToLower()
  $ver  = if ($p.version) { "$($p.version)" } else { 'latest' }
  Info "$name $ver"
  $manualHit = $null
  try {
    switch ($src) {
      'github'   { $r = Resolve-GitHub  $p $ver }
      'geysermc' { $r = Resolve-GeyserMC $p $ver }
      'hangar'   { $r = Resolve-Hangar   $p $ver }
      'modrinth' { $r = Resolve-Modrinth $p $ver }
      'spigot'   { $r = Resolve-Spigot   $p $ver }
      'url'      {
        $f = if ($p.fileName) { $p.fileName } else { Split-Path -Leaf ([Uri]$p.url).AbsolutePath }
        $r = New-Dl $p.url $f $null
      }
      'manual'   {
        # plugin you download manually and place in plugins\ (e.g.: SpigotMC, protected by Cloudflare)
        $pat = if ($p.fileName) { $p.fileName } else { "$name*.jar" }
        $manualHit = Get-ChildItem -LiteralPath $PluginsDir -Filter $pat -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $manualHit) { throw "file '$pat' not found in $PluginsDir" }
      }
      default    { throw "unknown source: '$($p.source)'" }
    }
    if ($manualHit) {
      Good "$name -> $($manualHit.Name) (already present, manual installation)"
      $Ok.Add($name)
      if ($ver -ne 'latest') {
        $jv = Get-JarVersion $manualHit.FullName
        if ($jv -and $jv -ne $ver.TrimStart('v')) {
          Write-Host "   [WARN] the .jar declares version '$jv', but plugins.json asks for '$ver'." -ForegroundColor Yellow
        }
      }
    } else {
      $expect = if ($r.Version) { $r.Version } else { $ver }
      try {
        Save-Jar $r.Url (Join-Path $PluginsDir $r.File) $r.Sha256
      } catch {
        if (-not $r.Fallback) { throw }
        Write-Host "   [WARN] failed to download version $ver ($($_.Exception.Message)); using latest ($($r.Fallback.Version)) because allowLatest=true." -ForegroundColor Yellow
        $r = $r.Fallback; $expect = $r.Version
        Save-Jar $r.Url (Join-Path $PluginsDir $r.File) $r.Sha256
      }
      Record $name "plugins/$($r.File)"
      Good "$name -> $($r.File)"
      $Ok.Add($name)
      if ($src -eq 'spigot' -and $expect -and $expect -ne 'latest') {
        $jv = Get-JarVersion (Join-Path $PluginsDir $r.File)
        if ($jv -and $jv -ne $expect.TrimStart('v')) {
          Write-Host "   [WARN] the .jar declares version '$jv', but expected was '$expect'. Check." -ForegroundColor Yellow
        }
      }
    }
  } catch {
    Bad "$name failed: $($_.Exception.Message)"
    if ($src -eq 'spigot') { Write-Host '   SpigotMC blocks automatic downloads (Cloudflare). Use "source": "manual" in plugins.json for this plugin.' }
    if ($p.manualUrl) { Write-Host "   Download manually at: $($p.manualUrl) (version $ver) and place in $PluginsDir" }
    $Failed.Add($name)
  }
}

# ----------------------------------- EULA --------------------------------------
if ($AcceptEula) {
  Set-Content -LiteralPath (Join-Path $ServerDir 'eula.txt') -Value 'eula=true' -Encoding ASCII
  Info 'eula.txt created (you accepted the Mojang EULA: https://aka.ms/MinecraftEULA)'
}

# ---------------------------------- RESUMO -------------------------------------
Write-Host ''
Write-Host '================ SUMMARY ================'
Write-Host "Installed: $($Ok.Count)   Failed: $($Failed.Count)"
if ($Failed.Count -gt 0) {
  $Failed | ForEach-Object { Write-Host "  - $_" }
  Write-Host 'Fix the items above and run again (safe to repeat).'
  exit 1
}
Write-Host 'All set! Start with:'
Write-Host "  cd `"$ServerDir`" ; java -Xms2G -Xmx4G -jar paper.jar --nogui"
exit 0
