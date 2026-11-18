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

Create a key in ADS Beast under **API Keys** (https://adsbeast.pro/api-keys). Minting one requires an admin
account. The key is shown once.

The key is bound to one organization and each area is gated by its own scope:
`read:leads`, `write:leads`, `read:campaigns`, and so on. Enforcement is
fail-closed, so an area the key does not name is unreachable, and billing,
settings and the platform integrations are not reachable with an integration
key at all.

Give a key the scopes the work needs and no more. `whoami` reports what a key
actually carries, and is the first thing to call when something is refused.

## Workflows

Twelve skills ship with the plugin. They tell the assistant which tools to
call, in what order, and where to stop and ask: `account-audit`,
`wasted-spend-hunt`, `search-terms-negatives`, `campaign-launch`,
`budget-pacing-check`, `weekly-report`, `conversion-tracking-check`,
`lead-pipeline-review`, `creative-fatigue-check`,
`cross-platform-comparison`, `competitor-ads-review` and
`connect-adsbeast`.

Every workflow checks the connection with `whoami` first, reports amounts in
the currency of the ad account, never repeats a create that failed, and asks
before anything that could affect spend.

In Claude Code they are also commands: `/adsbeast:audit`,
`/adsbeast:wasted-spend`, `/adsbeast:launch`, `/adsbeast:pacing`,
`/adsbeast:weekly`, `/adsbeast:tracking-check`, `/adsbeast:leads`,
`/adsbeast:creative-fatigue`, `/adsbeast:compare-platforms`,
`/adsbeast:competitors`.

## Changes and campaigns

A change to an ad account takes two calls. A prepare tool
(`prepare_campaign_pause`, `prepare_campaign_budget_change`,
`prepare_negative_keywords_add`, `prepare_campaign_draft_publish` and
others) stores a preview of exactly that change. `execute_prepared_change`
submits that preview and takes no other argument. The change then waits for
a person to approve it in ADS Beast, unless the client's owner switched on
assistant auto-apply for that client and its write policy allows the change. `get_prepared_change` reports what became of it.

`create_campaign_draft` builds a campaign as a draft in the campaign
builder. Published from a preview, it is created paused, and switching it
on is a separate decision by a person.

The server also runs audits (`audit_account`, `audit_wasted_spend`,
`audit_tracking`) and analytics (`analytics_summary`,
`analytics_compare_periods`). A key bound to a single client is refused by
those; pausing, enabling, a budget change and negative keywords still work
with it.

## Install

### Claude Code

```
/plugin marketplace add notformal/adsbeast-plugins
/plugin install adsbeast@adsbeast-plugins
```

Claude asks for the API key on install and stores it in your system keychain.

### Codex

```
codex plugin marketplace add notformal/adsbeast-plugins
codex plugin add adsbeast@adsbeast-plugins
codex mcp add adsbeast --url https://adsbeast.pro/api/mcp/workspace --bearer-token-env-var ADSBEAST_API_KEY
```

The last line gives the server your key: a Codex plugin cannot carry one.
Set `ADSBEAST_API_KEY` for good (`export` in `~/.zshrc` or `~/.bashrc`; on
Windows `[Environment]::SetEnvironmentVariable("ADSBEAST_API_KEY", "absk_...", "User")`)
and open a new terminal. Details: [CONNECTING.md](../CONNECTING.md#codex-cli).

### Cursor, Gemini CLI, Windsurf and other clients

See [CONNECTING.md](../CONNECTING.md). Ready configs are in
[`clients/`](./clients).

The plugin is not listed in the ChatGPT app directory or the Claude connector
directory.

`X-API-Key` works in place of the `Authorization` header if your client prefers
it. The handshake and the tool catalogue answer without a key; every tool call
requires one.

## Plans and limits

<!-- generated:plans -->
Every limit the server enforces, per plan. Counters restart on the 1st of the month (UTC).
No plan has overage charges or automatic top-ups: at a limit the tool says so and names the reset date.
No plan limits ad platforms or campaigns.

| Plan | Tool calls a month | Assistant questions a month | Reports a month | Clients | People | Ad accounts | Published landing pages |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Free (no card, no time limit) | 100 | 15 | 3 | 1 | 1 | 1 | 0 |
| Connector | 2,000 | 300 | 10 | 3 | 1 | no cap | 3 |
| Starter | 10,000 | no cap | no cap | 5 | 2 | no cap | 10 |
| Agency | 100,000 | no cap | no cap | 50 | 10 | no cap | 50 |
| Enterprise | no cap | no cap | no cap | 999 | 100 | no cap | 500 |
<!-- /generated -->

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

## Publishing safety

`seo_publish_safety` (scope `read:seo`) tells an agent how many new articles a
site may publish today, whether publishing is paused and why, and which
published articles are kept out of search. Sites launch gradually: 2 new
articles a day, plus 1 a week up to 6, one language version of a topic a day.
A search-traffic cliff pauses publishing until a person lifts it. An
integration key can read this state but cannot change it.
