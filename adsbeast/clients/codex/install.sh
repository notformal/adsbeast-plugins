#!/usr/bin/env bash
# Install the ADS Beast skills and MCP servers for Codex CLI.
#
#   bash adsbeast/clients/codex/install.sh            # from a clone
#   bash install.sh --skills-dir /path/to/.agents/skills
#
# What it does, and nothing more:
#   1. copies the workflow skills into ~/.agents/skills (where Codex looks);
#   2. registers two MCP servers in ~/.codex/config.toml, unless a server
#      with that name is already there.
#
# It never asks for, reads or stores the API key. Codex takes it from the
# ADSBEAST_API_KEY environment variable when it starts.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
plugin_dir="$(cd "$here/../.." && pwd)"
skills_dir="${HOME}/.agents/skills"
config="${CODEX_HOME:-$HOME/.codex}/config.toml"

while [ $# -gt 0 ]; do
  case "$1" in
    --skills-dir) skills_dir="$2"; shift 2 ;;
    --config) config="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$plugin_dir/skills" ]; then
  echo "No skills directory next to this script ($plugin_dir/skills)." >&2
  echo "Run it from a clone of https://github.com/notformal/adsbeast-plugins" >&2
  exit 1
fi

mkdir -p "$skills_dir"
count=0
for skill in "$plugin_dir"/skills/*/; do
  name="$(basename "$skill")"
  rm -rf "${skills_dir:?}/adsbeast-$name"
  mkdir -p "$skills_dir/adsbeast-$name"
  cp "$skill/SKILL.md" "$skills_dir/adsbeast-$name/SKILL.md"
  # A skill's name has to match its directory. The prefix keeps these apart
  # from skills of the same name that another package may have installed.
  sed -i.bak "s/^name: $name\$/name: adsbeast-$name/" "$skills_dir/adsbeast-$name/SKILL.md"
  rm -f "$skills_dir/adsbeast-$name/SKILL.md.bak"
  count=$((count + 1))
done
echo "Skills: $count copied to $skills_dir"

mkdir -p "$(dirname "$config")"
touch "$config"
add_server() {
  local name="$1" block="$2"
  if grep -q "^\[mcp_servers\.$name\]" "$config"; then
    echo "MCP server $name: already in $config, left as it is"
  else
    printf '\n%s\n' "$block" >> "$config"
    echo "MCP server $name: added to $config"
  fi
}
add_server "adsbeast" '[mcp_servers.adsbeast]
url = "https://adsbeast.pro/api/mcp/workspace"
bearer_token_env_var = "ADSBEAST_API_KEY"'
add_server "ad-spec-guard" '[mcp_servers.ad-spec-guard]
url = "https://adsbeast.pro/api/mcp"'

echo
if [ -z "${ADSBEAST_API_KEY:-}" ]; then
  echo "Next: set ADSBEAST_API_KEY to a scoped key from ADS Beast (API Keys, admin only),"
  echo "for example in your shell profile:  export ADSBEAST_API_KEY=absk_..."
  echo "Without it the ad-spec-guard tools work and the workspace tools answer 401."
else
  echo "ADSBEAST_API_KEY is set. Start codex and ask it to call whoami."
fi
