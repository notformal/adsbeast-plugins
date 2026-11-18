# Install the ADS Beast skills and MCP servers for Codex CLI on Windows.
#
#   pwsh adsbeast/clients/codex/install.ps1
#
# Copies the workflow skills into ~/.agents/skills and registers two MCP
# servers in ~/.codex/config.toml unless they are already there. It never
# asks for, reads or stores the API key: Codex takes it from the
# ADSBEAST_API_KEY environment variable when it starts.
param(
    [string]$SkillsDir = (Join-Path $HOME ".agents/skills"),
    [string]$Config = (Join-Path ($(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" })) "config.toml")
)
$ErrorActionPreference = "Stop"

$pluginDir = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$source = Join-Path $pluginDir "skills"
if (-not (Test-Path $source)) {
    Write-Error "No skills directory next to this script ($source). Run it from a clone of https://github.com/notformal/adsbeast-plugins"
}

New-Item -ItemType Directory -Force $SkillsDir | Out-Null
$count = 0
foreach ($skill in Get-ChildItem -Directory $source) {
    $name = $skill.Name
    $target = Join-Path $SkillsDir "adsbeast-$name"
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    New-Item -ItemType Directory -Force $target | Out-Null
    # A skill's name has to match its directory. The prefix keeps these apart
    # from skills of the same name that another package may have installed.
    $text = [IO.File]::ReadAllText((Join-Path $skill.FullName "SKILL.md"))
    $text = $text -replace "(?m)^name: $([regex]::Escape($name))\r?$", "name: adsbeast-$name"
    [IO.File]::WriteAllText((Join-Path $target "SKILL.md"), $text)
    $count++
}
Write-Host "Skills: $count copied to $SkillsDir"

New-Item -ItemType Directory -Force (Split-Path $Config) | Out-Null
if (-not (Test-Path $Config)) { New-Item -ItemType File $Config | Out-Null }
$existing = [IO.File]::ReadAllText($Config)
function Add-Server([string]$Name, [string]$Block) {
    if ($script:existing -match "(?m)^\[mcp_servers\.$([regex]::Escape($Name))\]") {
        Write-Host "MCP server ${Name}: already in $Config, left as it is"
    } else {
        [IO.File]::AppendAllText($Config, "`n$Block`n")
        Write-Host "MCP server ${Name}: added to $Config"
    }
}
Add-Server "adsbeast" "[mcp_servers.adsbeast]`nurl = `"https://adsbeast.pro/api/mcp/workspace`"`nbearer_token_env_var = `"ADSBEAST_API_KEY`""
Add-Server "ad-spec-guard" "[mcp_servers.ad-spec-guard]`nurl = `"https://adsbeast.pro/api/mcp`""

Write-Host ""
if (-not $env:ADSBEAST_API_KEY) {
    Write-Host "Next: set ADSBEAST_API_KEY to a scoped key from ADS Beast (API Keys, admin only):"
    Write-Host '  [Environment]::SetEnvironmentVariable("ADSBEAST_API_KEY", "absk_...", "User")'
    Write-Host "Without it the ad-spec-guard tools work and the workspace tools answer 401."
} else {
    Write-Host "ADSBEAST_API_KEY is set. Start codex and ask it to call whoami."
}
