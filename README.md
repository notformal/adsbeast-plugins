# ADS Beast plugins

Connect an AI assistant to [ADS Beast](https://adsbeast.pro), an ad operations
platform for agencies and in-house teams. Maintained by Denha Nexus s.r.o.

This repository holds no server code. It holds what an assistant needs to use
two hosted MCP servers well: manifests for each client, and workflow skills
that tell the assistant which tools to call, in what order, and where to stop
and ask.

| Plugin | Server | What it does | Account |
| --- | --- | --- | --- |
| [adsbeast](./adsbeast) | `https://adsbeast.pro/api/mcp/workspace` | Your own workspace: account audits, analytics, campaigns, leads with attribution, alerts, reports, campaign drafts, and changes that run only from a preview you approved. | Yes |
| [ad-spec-guard](./ad-spec-guard) | `https://adsbeast.pro/api/mcp` | Ad platform character limits, creative specs, statistical gates before pausing or scaling, UTM tagging, policy pre-checks. | No |

Both servers speak MCP over streamable HTTP.

## Install

| Client | How |
| --- | --- |
| Claude Code | `/plugin marketplace add notformal/adsbeast-plugins`, then `/plugin install adsbeast@adsbeast-plugins` and `/plugin install ad-spec-guard@adsbeast-plugins` |
| Codex CLI | `codex plugin marketplace add notformal/adsbeast-plugins`, or clone and run `adsbeast/clients/codex/install.sh` (`install.ps1` on Windows) |
| Cursor | Copy [`adsbeast/clients/cursor/mcp.json`](./adsbeast/clients/cursor/mcp.json) into `~/.cursor/mcp.json` |
| Gemini CLI | `gemini extensions install https://github.com/notformal/adsbeast-plugins` |
| Windsurf | Copy [`adsbeast/clients/windsurf/mcp_config.json`](./adsbeast/clients/windsurf/mcp_config.json) into `~/.codeium/windsurf/mcp_config.json` |
| Anything else | See [CONNECTING.md](./CONNECTING.md) |

Details, variations and troubleshooting for each client are in
[CONNECTING.md](./CONNECTING.md).

Where this is not available yet: the plugins are not listed in the ChatGPT app
directory or in the Claude connector directory. In ChatGPT and in Claude on the
web they cannot be added from a catalogue today.

## Tool groups of the workspace server

The workspace server serves 170+ tools. The table shows the groups the
workflows below rely on; the full, current list is the server's own, and
`tools/list` answers without a key.

| Group | Examples | Writes |
| --- | --- | --- |
| Diagnostics | `whoami` | no |
| Clients | `list_clients`, `get_client`, `get_agency_kit` | no |
| Campaigns | `list_campaigns`, `get_campaign`, `campaign_dashboard_summary`, `campaign_analyze` | no |
| Audits | `audit_account`, `audit_google_ads`, `audit_meta_ads`, `audit_wasted_spend`, `audit_tracking`, `audit_conversion_goals`, `audit_campaign_portfolio` | no |
| Analytics | `analytics_summary`, `analytics_compare_periods`, `analytics_attribution`, `analytics_forecast`, `client_goals`, `client_data_freshness` | no |
| Creatives | `creative_fatigue_report`, `meta_ads_learning_phase`, `google_ads_ad_strength` | no |
| Competitors | `competitor_list`, `competitor_site_analyze`, `competitor_search_intel`, `competitor_ads_research` | no |
| Changes, in two steps | `prepare_campaign_pause`, `prepare_campaign_budget_change`, `prepare_negative_keywords_add`, `prepare_campaign_draft_publish`, then `execute_prepared_change` and `get_prepared_change` | only from a stored preview |
| Proposals | `list_proposals`, `reject_proposal` | reject only |
| Campaign drafts | `list_campaign_types`, `create_campaign_draft`, `update_campaign_draft`, `get_campaign_draft`, `list_campaign_drafts`, `campaign_draft_publish_check` | drafts only |
| Leads | `get_new_leads`, `get_lead`, `lead_pipeline_stats`, `update_lead`, `move_lead_stage` | yes |
| Conversion outcomes | `lead_outcome_contract`, `push_lead_outcomes` | yes, dry run by default |
| Alerts, tasks, reports | `list_alerts`, `alerts_unread_count`, `list_tasks`, `list_reports` | no |
| Outreach | `list_outreach_campaigns`, `outreach_campaign_check`, `list_offer_packs` | no |
| Webhooks | `list_webhooks`, `list_webhook_events`, `create_webhook` | yes |

## Workflow skills

Shipped in [`adsbeast/skills`](./adsbeast/skills). Each one starts by checking
the connection and ends by saying what it could not check.

| Skill | Use it for |
| --- | --- |
| `account-audit` | A health check of one client's account |
| `wasted-spend-hunt` | Campaigns that spend and do not return |
| `search-terms-negatives` | Turning a search terms export into negative keywords |
| `campaign-launch` | Building a campaign as a draft: preview, confirm, draft |
| `budget-pacing-check` | Whether budgets last the period |
| `weekly-report` | A factual weekly status for one client |
| `conversion-tracking-check` | Whether results are being counted |
| `lead-pipeline-review` | Lead quality, stuck leads, writing outcomes back |
| `creative-fatigue-check` | Ads the audience has seen too often, on Meta and TikTok |
| `cross-platform-comparison` | Platforms side by side on cost per result and return |
| `competitor-ads-review` | What competitors advertise, observed and inferred kept apart |
| `connect-adsbeast` | A tool answered 401 or 403 |

In Claude Code, Cursor and Gemini CLI the same workflows are commands, for
example `/adsbeast:audit` and `/adsbeast:launch`.

Every tool call counts against the monthly allowance of the plan, and
`whoami` reports how many calls are left. The skills are written to ask
for what a question needs and no more.

## Authentication

The workspace server takes a scoped API key, `Authorization: Bearer absk_...`
(`X-API-Key` also works). An admin creates the key in ADS Beast under API
Keys; it is shown once. The key belongs to one organization and carries
scopes such as `read:campaigns` or `write:leads`. An area the key does not
name is unreachable. `whoami` reports what a key carries.

Sign-in without a key (OAuth 2.1 with PKCE) is implemented on the server, but
the discovery documents are not reachable on the production domain yet, so
clients that insist on OAuth cannot connect today. Use a key.

Ad Spec Guard needs no authentication.

## Security model

- Read tools and write tools are separate, and every tool declares whether it
  is read-only or destructive.
- A change to an ad account runs only from a stored preview. A prepare
  tool saves exactly what would change and returns a preview id that works
  once, for 15 minutes. `execute_prepared_change` takes that id and nothing
  else, so what runs cannot differ from what was shown. A preview is
  refused if the campaign changed in the meantime.
- After that the change waits for a person to approve it in ADS Beast,
  unless the client's own write policy applies that kind of change
  automatically. Switching a campaign on always waits for a person.
- A new campaign is created paused.
- An integration key cannot approve, roll back, or reach billing, settings
  and platform credentials. A key bound to a single client can prepare a
  pause, an enable, a budget change and negative keywords; the audit and
  analytics tools refuse it.
- Writing lead outcomes defaults to a dry run.
- A key can be bound to a single client, and can be revoked at any time under
  API Keys.
- Keys are never part of this repository. Every config here reads the key
  from an environment variable or from the client's own secret store.

## What the platform covers

ADS Beast reads campaigns from Google Ads, Meta, TikTok, LinkedIn and
Microsoft Advertising accounts that you connect. Its Google Ads API access is
at the Basic level; an application for Standard access is pending.

## Pricing

Ad Spec Guard is free. The workspace server is part of an ADS Beast account;
plans and their MCP allowances are on https://adsbeast.pro/pricing.

## Support and legal

- Issues: https://github.com/notformal/adsbeast-plugins/issues
- Privacy: https://adsbeast.pro/privacy
- Terms: https://adsbeast.pro/terms

## Licence

MIT. See [LICENSE](./LICENSE).
