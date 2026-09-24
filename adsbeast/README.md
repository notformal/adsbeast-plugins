# ADS Beast

Work with your own ADS Beast advertising workspace from ChatGPT, Codex or
Claude.

Requires an ADS Beast account and a scoped API key. If you do not have one,
[ad-spec-guard](../ad-spec-guard) needs no account and may be what you want.

## What it does

ADS Beast is an ad operations platform for teams running paid campaigns across
Google, Meta, TikTok, LinkedIn and Microsoft. This plugin puts that workspace
in the conversation instead of the dashboard.

| Area | Tools |
| --- | --- |
| Leads | `get_new_leads`, `get_lead`, `list_lead_forms`, `lead_pipeline_stats`, `update_lead`, `move_lead_stage` |
| Conversion outcomes | `push_lead_outcomes`, `lead_outcome_contract` |
| Campaigns | `list_campaigns`, `get_campaign`, `campaign_dashboard_summary` |
| Clients | `list_clients`, `get_client` |
| Reporting and operations | `list_reports`, `list_alerts`, `alerts_unread_count`, `list_tasks` |
| Webhooks | `list_webhooks`, `list_webhook_events`, `create_webhook` |
| Diagnostics | `whoami` |

`get_new_leads` takes the timestamp of your last sync and returns only leads
created or updated since then, with contact details, qualification and full
attribution: UTM parameters, click identifiers, and the Meta form and campaign
the lead came from. For real-time delivery instead of polling, register a
`lead.created` webhook.

`push_lead_outcomes` is the return path that matters most. Without it the ad
platforms only learn that a lead arrived, never whether it became a customer,
so they optimise for lead volume rather than quality. It defaults to a dry run.

## Access

Create a key in ADS Beast under **API Keys**. Minting one requires an admin
account. The key is shown once.

The key is bound to one organization and each area is gated by its own scope:
`read:leads`, `write:leads`, `read:campaigns`, and so on. Enforcement is
fail-closed, so an area the key does not name is unreachable, and billing,
settings and the platform integrations are not reachable with an integration
key at all.

Give a key the scopes the work needs and no more. `whoami` reports what a key
actually carries, and is the first thing to call when something is refused.

## Install

### ChatGPT and Codex

Open **Plugins**, select ADS Beast, install, and supply your API key when
prompted.

### Claude Code

```
/plugin marketplace add notformal/adsbeast-plugins
/plugin install adsbeast@adsbeast-plugins
```

Claude asks for the API key on install and stores it in your system keychain.

### Any other MCP client

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

`X-API-Key` works in place of the `Authorization` header if your client prefers
it. The handshake and the tool catalogue answer without a key; every tool call
requires one.

## Safety

Read tools and write tools are separate, and the two tools that are hard to
undo say so in their metadata, so a client that asks for confirmation before
destructive actions will ask before these:

- `push_lead_outcomes` sends outcomes onward to the ad platforms, which then
  optimise on them.
- `create_webhook` starts sending your data to an address outside the platform.

## Privacy

The plugin reaches only the organization its key belongs to. It sends no data
anywhere except back to ADS Beast, and stores nothing outside it.

Full policy: https://adsbeast.pro/privacy

## Support

Issues: https://github.com/notformal/adsbeast-plugins/issues

## Licence

MIT. See [LICENSE](../LICENSE).
