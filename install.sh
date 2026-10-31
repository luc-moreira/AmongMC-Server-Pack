#!/usr/bin/env bash
# ==============================================================================
# Server pack installer (Paper + plugins) - Linux / macOS / Git Bash / WSL
# Reads versions and plugins from plugins.json (same file used by install.bat).
#
# Usage:  ./install.sh [--accept-eula] [--config path/plugins.json] [server_folder]
#       (default folder: ./server, next to this script)
# Requirements: bash, curl, jq (and Java 21+ to run the server)
# Optional:   export GITHUB_TOKEN=xxxx  (avoids GitHub's 60 req/h limit)
# ==============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/server/plugins.json"
SERVER_DIR="$SCRIPT_DIR/server"
ACCEPT_EULA=false

while [ $# -gt 0 ]; do
  case "$1" in
    --accept-eula) ACCEPT_EULA=true ;;
    --config)      shift; CONFIG="${1:-}" ;;
    -h|--help)     sed -n '2,11p' "$0"; exit 0 ;;
    *)             SERVER_DIR="$1" ;;
  esac
  shift
done

UA="server-pack-installer/2.0"
c_ok=$'\e[32m'; c_err=$'\e[31m'; c_inf=$'\e[36m'; c_off=$'\e[0m'
info() { echo "${c_inf}==>${c_off} $*"; }
good() { echo "${c_ok} ✔${c_off} $*"; }
bad()  { echo "${c_err} ✘${c_off} $*" >&2; }

for dep in curl jq; do
  command -v "$dep" >/dev/null 2>&1 || { bad "'$dep' not found. Install it and run again."; exit 1; }
done
[ -f "$CONFIG" ] || { bad "Config not found: $CONFIG"; exit 1; }
jq -e . "$CONFIG" >/dev/null 2>&1 || { bad "Invalid JSON in $CONFIG"; exit 1; }

GH_AUTH=()
[ -n "${GITHUB_TOKEN:-}" ] && GH_AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")

PLUGINS_DIR="$SERVER_DIR/plugins"
MANIFEST="$SERVER_DIR/.install-manifest.json"
mkdir -p "$PLUGINS_DIR" || { bad "Failed to create $PLUGINS_DIR"; exit 1; }
[ -f "$MANIFEST" ] || echo '{}' > "$MANIFEST"

OK=(); FAILED=()
ERR=""; URL=""; FILE=""; SHA=""; FB_URL=""; FB_FILE=""; FB_VER=""; EXPECT=""

MC_VERSION=$(jq -r '.minecraftVersion // empty' "$CONFIG")
[ -n "$MC_VERSION" ] || { bad "'minecraftVersion' missing in $CONFIG"; exit 1; }

# ---------------------------------- helpers ------------------------------------
field() { jq -r --arg k "$2" '.[$k] // empty' <<<"$1"; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}

# download_jar <url> <destino> [sha256]
download_jar() {
  local url=$1 dest=$2 sha=${3:-} tmp="$2.part" out code eff
  out=$(curl -sSL --retry 3 --retry-delay 2 -A "$UA" -o "$tmp" -w '%{http_code} %{url_effective}' "$url" 2>/dev/null) || true
  code=${out%% *}; eff=${out#* }
  if [ "$code" != "200" ]; then
    rm -f "$tmp"; ERR="HTTP ${code:-000} at ${eff:-$url}"; return 1
  fi
  if [ "$(head -c2 "$tmp")" != "PK" ]; then
    rm -f "$tmp"; ERR="the downloaded file is not a valid .jar (likely a blocking page from ${eff:-$url})"; return 1
  fi
  if [ -n "$sha" ] && [ "$(sha256_of "$tmp" | tr 'A-Z' 'a-z')" != "$(echo "$sha" | tr 'A-Z' 'a-z')" ]; then
    rm -f "$tmp"; ERR="SHA-256 does not match"; return 1
  fi
  mv -f "$tmp" "$dest"
}

# record <chave> <caminho_relativo>  -> guarda no manifesto e apaga versão antiga
record() {
  local old tmp
  old=$(jq -r --arg k "$1" '.[$k] // empty' "$MANIFEST")
  if [ -n "$old" ] && [ "$old" != "$2" ] && [ -f "$SERVER_DIR/$old" ]; then
    rm -f "$SERVER_DIR/$old"; echo "   removed old version: $old"
  fi
  tmp=$(mktemp)
  jq --arg k "$1" --arg v "$2" '.[$k]=$v' "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"
}

# ------------------------------ resolvedores (URL/FILE/SHA) --------------------
resolve_github() { # repo versão regex
  local repo=$1 ver=$2 regex=${3:-'\.jar$'} e json eps
  if [ "$ver" = latest ]; then eps=("latest"); else eps=("tags/$ver" "tags/v$ver" "tags/${ver#v}"); fi
  for e in "${eps[@]}"; do
    json=$(curl -fsSL -A "$UA" ${GH_AUTH[@]+"${GH_AUTH[@]}"} \
      "https://api.github.com/repos/$repo/releases/$e" 2>/dev/null) || continue
    URL=$(jq -r --arg re "$regex" '
      [.assets[] | select(.name | test($re))
                 | select(.name | test("sources|javadoc"; "i") | not)
      ][0].browser_download_url // empty' <<<"$json")
    if [ -n "$URL" ]; then FILE=$(basename "$URL"); SHA=""; return 0; fi
  done
  ERR="release '$ver' not found at github.com/$repo"; return 1
}

resolve_geysermc() { # projeto plataforma versão
  local project=$1 plat=$2 ver=$3 json build
  json=$(curl -fsSL -A "$UA" \
    "https://download.geysermc.org/v2/projects/$project/versions/$ver/builds/latest" 2>/dev/null) \
    || { ERR="build not found in GeyserMC API"; return 1; }
  build=$(jq -r '.build // "latest"' <<<"$json")
  FILE=$(jq -r --arg p "$plat" '.downloads[$p].name // empty' <<<"$json")
  SHA=$(jq -r --arg p "$plat" '.downloads[$p].sha256 // empty' <<<"$json")
  [ -n "$FILE" ] || FILE="$project-$plat.jar"
  URL="https://download.geysermc.org/v2/projects/$project/versions/$ver/builds/$build/downloads/$plat"
}

resolve_hangar() { # projeto plataforma versão
  local project=$1 plat=$2 ver=$3
  if [ "$ver" = latest ]; then
    ver=$(curl -fsSL -A "$UA" "https://hangar.papermc.io/api/v1/projects/$project/latestrelease" 2>/dev/null) \
      || { ERR="could not get latest version from Hangar"; return 1; }
  fi
  URL="https://hangar.papermc.io/api/v1/projects/$project/versions/$ver/$plat/download"
  FILE="$project-$ver.jar"; SHA=""
}

resolve_modrinth() { # slug versão
  local slug=$1 ver=$2 json t
  if [ "$ver" = latest ]; then
    json=$(curl -fsSL -A "$UA" -G "https://api.modrinth.com/v2/project/$slug/version" \
      --data-urlencode 'loaders=["paper","spigot","bukkit"]' \
      --data-urlencode "game_versions=[\"$MC_VERSION\"]" \
      --data-urlencode 'include_changelog=false' 2>/dev/null) \
      || { ERR="project '$slug' not found on Modrinth"; return 1; }
    # prefere a primeira versão "release"; senão, a mais recente de qualquer tipo
    json=$(jq 'map(select(.version_type=="release"))[0] // .[0] // empty' <<<"$json")
  else
    for t in "$ver" "v$ver" "${ver#v}"; do
      json=$(curl -fsSL -A "$UA" "https://api.modrinth.com/v2/project/$slug/version/$t" 2>/dev/null) && break
      json=""
    done
  fi
  [ -n "$json" ] || { ERR="version '$ver' not found on Modrinth (project $slug, MC $MC_VERSION)"; return 1; }
  URL=$(jq -r '(.files | (map(select(.primary))[0] // .[0])).url // empty' <<<"$json")
  FILE=$(jq -r '(.files | (map(select(.primary))[0] // .[0])).filename // empty' <<<"$json")
  SHA=""
  [ -n "$URL" ] || { ERR="the Modrinth version has no file"; return 1; }
}

resolve_spigot() { # resource_id versão nome allowLatest
  local id=$1 ver=$2 name=$3 allow=${4:-false} want=${2#v} list latest latest_name vid names
  local api="https://api.spiget.org/v2/resources/$id"
  list=$(curl -fsSL -A "$UA" "$api/versions?size=200&sort=-releaseDate" 2>/dev/null) || list="[]"
  latest=$(curl -fsSL -A "$UA" "$api/versions/latest" 2>/dev/null) || latest="{}"
  latest_name=$(jq -r '.name // empty' <<<"$latest" 2>/dev/null)
  latest_name=${latest_name#v}
  SHA=""; FB_URL=""; FB_FILE=""; FB_VER=""
  # /download entrega a ÚLTIMA versão (caminho que o Spiget guarda por conta própria).
  # Versões antigas passam pelo spigotmc.org, protegido por Cloudflare, e costumam dar 403.
  if [ "$ver" = latest ] || [ "$latest_name" = "$want" ]; then
    URL="$api/download"; FILE="$name-${latest_name:-latest}.jar"; EXPECT="$latest_name"; return 0
  fi
  vid=$(jq -r --arg w "$want" \
    'map(select((.name|tostring|ltrimstr("v")|gsub("^\\s+|\\s+$";"")) == $w))[0].id // empty' \
    <<<"$list" 2>/dev/null)
  if [ -n "$vid" ]; then
    URL="$api/versions/$vid/download"; FILE="$name-$want.jar"
    if [ "$allow" = true ] && [ -n "$latest_name" ]; then
      FB_URL="$api/download"; FB_FILE="$name-$latest_name.jar"; FB_VER="$latest_name"
    fi
    return 0
  fi
  if [ "$allow" = true ] && [ -n "$latest_name" ]; then
    echo "   ⚠ version '$ver' not in Spiget list; using latest ($latest_name) because allowLatest=true."
    URL="$api/download"; FILE="$name-$latest_name.jar"; EXPECT="$latest_name"; return 0
  fi
  names=$(jq -r 'map(.name)[:8] | join(", ")' <<<"$list" 2>/dev/null)
  ERR="version '$ver' not found on Spiget (resource $id). Latest: '${latest_name:-?}'. Known: ${names:-none (API down or external resource?)}"
  return 1
}

# versão declarada no plugin.yml do .jar (vazio se não for possível ler)
jar_version() {
  unzip -p "$1" plugin.yml 2>/dev/null \
    | sed -n "s/^version:[[:space:]]*['\"]\{0,1\}\([^'\"[:space:]]*\).*/\1/p" | head -1
}

# ----------------------------------- PAPER -------------------------------------

info "Paper $MC_VERSION (latest build)"
build_json=$(curl -fsSL -A "$UA" \
  "https://fill.papermc.io/v3/projects/paper/versions/$MC_VERSION/builds/latest" 2>/dev/null) || build_json="{}"
URL=$(jq -r '.downloads["server:default"].url // empty' <<<"$build_json" 2>/dev/null)
SHA=$(jq -r '.downloads["server:default"].checksums.sha256 // empty' <<<"$build_json" 2>/dev/null)
build=$(jq -r '.id // "?"' <<<"$build_json" 2>/dev/null)
if [ -z "$URL" ]; then
  bad "Paper: version $MC_VERSION not found in PaperMC API."; FAILED+=("Paper")
elif download_jar "$URL" "$SERVER_DIR/paper.jar" "$SHA"; then
  record "Paper" "paper.jar"; good "Paper $MC_VERSION build $build → paper.jar"; OK+=("Paper")
else
  bad "Paper: $ERR"; FAILED+=("Paper")
fi

# ---------------------------------- PLUGINS ------------------------------------
while IFS= read -r p; do
  name=$(field "$p" name); source=$(field "$p" source); ver=$(field "$p" version)
  ver=${ver:-latest}
  info "$name $ver"
  ERR=""; URL=""; FILE=""; SHA=""; rc=0; FB_URL=""; FB_FILE=""; FB_VER=""; EXPECT="$ver"
  case "$source" in
    github)
      resolve_github "$(field "$p" repo)" "$ver" "$(field "$p" assetRegex)" || rc=1 ;;
    geysermc)
      plat=$(field "$p" platform); resolve_geysermc "$(field "$p" project)" "${plat:-spigot}" "$ver" || rc=1 ;;
    hangar)
      plat=$(field "$p" platform); resolve_hangar "$(field "$p" project)" "${plat:-PAPER}" "$ver" || rc=1 ;;
    modrinth)
      resolve_modrinth "$(field "$p" slug)" "$ver" || rc=1 ;;
    spigot)
      allow=$(field "$p" allowLatest)
      resolve_spigot "$(field "$p" resourceId)" "$ver" "$name" "${allow:-false}" || rc=1 ;;
    url)
      URL=$(field "$p" url); FILE=$(field "$p" fileName); FILE=${FILE:-$(basename "$URL")} ;;
    manual)
      # plugin you download manually and place in plugins/ (e.g.: SpigotMC, protected by Cloudflare)
      pat=$(field "$p" fileName); pat=${pat:-"$name*.jar"}
      found=$(find "$PLUGINS_DIR" -maxdepth 1 -type f -iname "$pat" 2>/dev/null | head -1)
      if [ -n "$found" ]; then
        good "$name → $(basename "$found") (already present, manual installation)"; OK+=("$name")
        if [ "$ver" != latest ]; then
          jv=$(jar_version "$found")
          if [ -n "$jv" ] && [ "$jv" != "${ver#v}" ]; then
            echo "   ⚠ the .jar declares version '$jv', but plugins.json asks for '$ver'."
          fi
        fi
        continue
      fi
      ERR="file '$pat' not found in $PLUGINS_DIR" ;;
    *)
      ERR="unknown source: '$source'"; rc=1 ;;
  esac
  [ -z "$URL" ] && rc=1
  done_ok=false
  if [ $rc -eq 0 ]; then
    if download_jar "$URL" "$PLUGINS_DIR/$FILE" "$SHA"; then
      done_ok=true
    elif [ -n "$FB_URL" ]; then
      echo "   ⚠ failed to download version $ver ($ERR); using latest ($FB_VER) because allowLatest=true."
      FILE=$FB_FILE; EXPECT=$FB_VER
      download_jar "$FB_URL" "$PLUGINS_DIR/$FILE" "" && done_ok=true
    fi
  fi
  if $done_ok; then
    record "$name" "plugins/$FILE"; good "$name → $FILE"; OK+=("$name")
    if [ "$source" = spigot ] && [ -n "$EXPECT" ] && [ "$EXPECT" != latest ]; then
      jv=$(jar_version "$PLUGINS_DIR/$FILE")
      if [ -n "$jv" ] && [ "$jv" != "${EXPECT#v}" ]; then
        echo "   ⚠ the .jar declares version '$jv', but expected was '$EXPECT'. Check."
      fi
    fi
  else
    bad "$name failed: ${ERR:-unknown error}"
    [ "$source" = spigot ] && echo "   SpigotMC blocks automatic downloads (Cloudflare). Use \"source\": \"manual\" in plugins.json for this plugin."
    manual=$(field "$p" manualUrl)
    [ -n "$manual" ] && echo "   Download manually at: $manual (version $ver) and place in $PLUGINS_DIR"
    FAILED+=("$name")
  fi
done < <(jq -c '.plugins[]' "$CONFIG")

# ---------------------------------- EULA ---------------------------------------
if $ACCEPT_EULA; then
  echo "eula=true" > "$SERVER_DIR/eula.txt"
  info "eula.txt created (you accepted the Mojang EULA: https://aka.ms/MinecraftEULA)"
fi

# --------------------------------- RESUMO --------------------------------------
echo
echo "================ SUMMARY ================"
echo "Installed: ${#OK[@]}   Failed: ${#FAILED[@]}"
if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '  - %s\n' "${FAILED[@]}"
  echo "Fix the items above and run again (safe to repeat)."
  exit 1
fi
echo "All set! Start with:"
echo "  cd \"$SERVER_DIR\" && java -Xms2G -Xmx4G -jar paper.jar --nogui"
