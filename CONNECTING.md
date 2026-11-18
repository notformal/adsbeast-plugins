# Connecting to ADS Beast

Two hosted MCP servers, both streamable HTTP:

| Server | URL | Authentication |
| --- | --- | --- |
| ADS Beast workspace | `https://adsbeast.pro/api/mcp/workspace` | `Authorization: Bearer absk_...` |
| Ad Spec Guard | `https://adsbeast.pro/api/mcp` | none |

## 1. Get a key

Only the workspace server needs one.

1. Sign in to ADS Beast as an admin and open **API Keys**.
2. Create a key. Give it the scopes the work needs and no more: read scopes
   for reporting, `write:proposals` to let the assistant draft campaigns and
   propose changes, `write:leads` to let it update leads.
3. Copy the key. It starts with `absk_` and is shown once.
4. Put it in an environment variable named `ADSBEAST_API_KEY`. Do not paste
   it into a chat and do not commit it.

```bash
export ADSBEAST_API_KEY=absk_...        # macOS, Linux, Git Bash
```

```powershell
[Environment]::SetEnvironmentVariable("ADSBEAST_API_KEY", "absk_...", "User")
```

## 2. Connect your client

### Claude Code

Plugin, with skills and commands:

```
/plugin marketplace add notformal/adsbeast-plugins
/plugin install adsbeast@adsbeast-plugins
/plugin install ad-spec-guard@adsbeast-plugins
```

Claude Code asks for the key when the plugin is installed and keeps it in
the system keychain.

Server only, without the plugin:

```bash
claude mcp add --transport http adsbeast https://adsbeast.pro/api/mcp/workspace \
  --header "Authorization: Bearer $ADSBEAST_API_KEY"
claude mcp add --transport http ad-spec-guard https://adsbeast.pro/api/mcp
```

### Codex CLI

As a plugin marketplace:

```
codex plugin marketplace add notformal/adsbeast-plugins
```

Or skills plus servers with the install script:

```bash
git clone https://github.com/notformal/adsbeast-plugins
bash adsbeast-plugins/adsbeast/clients/codex/install.sh
```

On Windows run `adsbeast/clients/codex/install.ps1`. The script copies the
skills to `~/.agents/skills` and adds this to `~/.codex/config.toml`:

```toml
[mcp_servers.adsbeast]
url = "https://adsbeast.pro/api/mcp/workspace"
bearer_token_env_var = "ADSBEAST_API_KEY"

[mcp_servers.ad-spec-guard]
url = "https://adsbeast.pro/api/mcp"
```

### Cursor

Add to `~/.cursor/mcp.json`, or to `.cursor/mcp.json` in a project:

```json
{
  "mcpServers": {
    "adsbeast": {
      "url": "https://adsbeast.pro/api/mcp/workspace",
      "headers": { "Authorization": "Bearer ${env:ADSBEAST_API_KEY}" }
    },
    "ad-spec-guard": { "url": "https://adsbeast.pro/api/mcp" }
  }
}
```

For the rules and skills as well, copy `adsbeast/rules/adsbeast-safety.mdc`
into `.cursor/rules/` and the folders under `adsbeast/skills/` into
`.cursor/skills/`. This repository also carries a Cursor plugin manifest
(`.cursor-plugin/`); it is not listed in the Cursor marketplace yet.

### Gemini CLI

```bash
gemini extensions install https://github.com/notformal/adsbeast-plugins
gemini extensions config adsbeast
```

The second command asks for the API key and stores it in the keychain. The
extension brings both servers, the skills, and commands such as
`/adsbeast:audit`.

### Windsurf

Add to `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "adsbeast": {
      "serverUrl": "https://adsbeast.pro/api/mcp/workspace",
      "headers": { "Authorization": "Bearer ${env:ADSBEAST_API_KEY}" }
    },
    "ad-spec-guard": { "serverUrl": "https://adsbeast.pro/api/mcp" }
  }
}
```

### Any other MCP client

Point it at the URL with the header. Most clients take this shape:

```json
{
  "mcpServers": {
    "adsbeast": {
      "type": "http",
      "url": "https://adsbeast.pro/api/mcp/workspace",
      "headers": { "Authorization": "Bearer absk_your_key" }
    }
  }
}
```

A client that only launches local commands can bridge with `mcp-remote`:

```json
{
  "mcpServers": {
    "adsbeast": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://adsbeast.pro/api/mcp/workspace",
               "--header", "Authorization: Bearer ${ADSBEAST_API_KEY}"]
    }
  }
}
```

### ChatGPT and Claude on the web

Not available today. Both add custom connectors through OAuth sign-in. The
server implements it, but its discovery documents are not reachable on the
production domain yet. Neither product lists ADS Beast in its directory.

## 3. Check that it works

Ask the assistant to call `whoami`. It should name your organization and
list the scopes of the key.

Without an assistant:

```bash
curl -s https://adsbeast.pro/api/mcp/workspace \
  -H "Authorization: Bearer $ADSBEAST_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"whoami","arguments":{}}}'
```

## When something is refused

| Symptom | Meaning |
| --- | --- |
| 401 on every tool call | No key reached the server, or the key was revoked. Check the environment variable in the process that starts the client. |
| 403 on one tool | The key lacks that tool's scope, or it is bound to one client and the tool is an audit or analytics tool. `whoami` shows what it has; an admin issues a key with the missing scope. |
| 404 on a record you can see in the dashboard | The key is bound to a different client or organization. |
| Tools are listed but every call fails | The catalogue answers without a key on purpose. A listing is not proof of a working key. |
| The client opens a browser sign-in that fails | The client is trying OAuth. Configure the header instead. |

## What an assistant can and cannot do

It can read what the key's scopes allow, run audits and analytics, update
leads, write lead outcomes (dry run first), build campaign drafts, and
submit changes to an ad account in two steps: a prepare tool stores a
preview, and `execute_prepared_change` submits that preview and nothing
else.

It cannot approve a change, switch a campaign on without a person, or reach
billing, settings and platform credentials. A submitted change waits for a
person in ADS Beast unless the client's write policy applies it. New
campaigns are created paused.

A key bound to a single client is refused (403) by the audit and analytics
tools. It can still read that client's data and prepare a pause, an enable,
a budget change and negative keywords. For the full set use a key that is
not bound to one client.
