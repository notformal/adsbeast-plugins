---
name: creative-fatigue-check
description: Workflow for checking whether a client's ads are wearing out, using the ADS Beast workspace server. Use this when someone asks about creative fatigue, ad fatigue, rising frequency, a falling click rate on Meta or TikTok, weak Google ad strength, or whether it is time to refresh creatives. The workflow checks the connection with whoami, reads how fresh the data is, calls creative_fatigue_report for campaigns with high frequency and a falling click rate, confirms the trend with analytics_compare_periods, reads meta_ads_learning_phase and google_ads_ad_strength where those platforms are connected, and reports which campaigns are tired, which only look it and which have too little data. Filing the finding for the team goes through creative_fatigue_check or task_create, only after the person agrees.
---

# Creative fatigue check

Find the campaigns whose ads the audience has seen too often, and separate
them from campaigns that are merely having a slow week. The answer is a
short list: tired, watch, not enough data.

Fatigue is measured where the platform reports frequency, which here means
Meta and TikTok. Google has no frequency in this data; for Google the
matching signal is the ad strength of its search ads.

## When to use

- "Are our creatives tired", "frequency is climbing", "CTR keeps dropping".
- Cost per result rose on Meta or TikTok and the audience did not change.
- A creative refresh is being planned and someone asks where to start.

## Steps

1. Call `whoami`. The check needs `read:campaigns` and `read:clients`;
   filing the result needs `write:proposals` or `write:tasks`.
2. Call `get_client` with the `client_id` for the connected platforms. If
   neither Meta nor TikTok is connected, say that frequency-based fatigue
   cannot be measured for this client and go to step 6 for Google.
3. Call `client_data_freshness` with the `client_id`. Fatigue is a trend;
   on stale data it is a trend that ended on the last sync date. Say so.
4. Call `creative_fatigue_report` with the `client_id`. It lists campaigns
   whose average frequency is above the threshold (3.5 unless
   `threshold_frequency` is passed) and whose click rate is falling, with
   `avg_frequency`, `ctr_decline_pct` and a `fatigue_score`. Quote the
   frequency and the decline. The score is the tool's own ranking, not a
   unit; do not quote the early and recent click figures it carries, they
   are not percentages. Lower the threshold only when the person asks for
   an earlier warning, and say that you did.
5. For each campaign on the list, at most three, call
   `analytics_compare_periods` with the `client_id`, the `platform`,
   `current_days` 14 and `previous_days` 14. Fatigue shows as a lower click
   rate and a higher cost per result at similar spend. If cost per result
   held, the ads are seen often but still work: that is "watch", not
   "tired". Use `campaign_analyze` for a single campaign only when the
   two periods disagree and the reason matters.
6. Platform detail, only for platforms the client has connected through
   the API: `meta_ads_learning_phase` with the `client_id` shows ad sets
   stuck in learning, which also depresses results and is not fatigue;
   `google_ads_ad_strength` with the `client_id` lists weak search ads with
   Google's own action items, from the stored snapshot. Either may answer
   that it has no access or no data yet. Report that as not checked.
7. Call `list_alerts` with the `client_id` and `is_resolved` false, and
   `list_proposals` with the `client_id`. A fatigue alert or a creative
   rotation proposal that already exists is part of the answer and must
   not be filed again.
8. Report, then stop. Only if the person wants the finding recorded: call
   `creative_fatigue_check` with the `client_id` once. It files an alert
   and a change proposal for each tired Meta or TikTok campaign, and the
   proposals wait for a person in ADS Beast. Say that before calling it,
   and wait for a yes. For anything else (a brief for new creatives, a
   reminder), use `task_create` with a `title`, a `priority` and the
   `client_id`.

## Judging the result

- High frequency alone is not fatigue. A small retargeting audience runs
  at a high frequency by design. It becomes fatigue when the click rate
  falls and the cost per result rises with it.
- Two weeks against two weeks is the shortest comparison worth making. A
  campaign younger than that, or with a few dozen clicks per period, goes
  under "not enough data".
- A drop on one date across every campaign of an account is not fatigue;
  look at tracking, billing and delivery alerts first.
- This server shows fatigue per campaign. It does not show which single ad
  inside the campaign is tired; that needs the platform's own ad report.

## Reporting the result

- Per campaign: platform, frequency, change in click rate and in cost per
  result with the two periods named, spend with its currency, verdict
  (tired, watch, not enough data).
- What was not checked and why: platform not connected, no frequency data,
  a tool that answered without access.
- What already exists: open fatigue alerts and pending proposals.
- What was filed, if anything, and that proposals wait for a person.
- No promise that new creatives will restore the earlier results. Say
  what the data shows and what a refresh is expected to test.

## Safety rules

These apply to every step above.

1. Check the connection first. Call `whoami` before anything else. If it
   fails, the key is missing, wrong or revoked: say so and stop. If it works,
   read the scopes it reports and do not call a tool whose scope is absent.
2. Amounts are in the currency of the ad account they came from. Never put a
   dollar sign on a figure because it is a number, never add up figures from
   accounts in different currencies, and name the currency next to every
   amount you report. If the currency is not in the data, say it is unknown.
   Budgets are whole units of that currency, never cents or micros. Some
   tool texts print a dollar sign in front of an amount; go by the currency
   field of the reply and of the account, not by the sign. Only fields
   whose name ends in usd are US dollars.
3. Never retry a failed create. If `execute_prepared_change`,
   `create_campaign_draft`, `create_webhook` or a non-dry-run
   `push_lead_outcomes` returns an error or times out, do not send it again
   and do not prepare the same change a second time. Look first:
   `get_prepared_change` with the same `preview_id`, `list_proposals`,
   `list_campaign_drafts`, `list_webhooks`. Then report what you found. A
   repeated create is how duplicates and double changes happen.
4. Confirm before anything that affects spend. A change to an ad account
   takes two calls. A prepare tool stores a preview of exactly that change
   and returns a `preview_id` that works once, for 15 minutes. Show the
   person the preview (campaign, current value, new value, currency,
   reason) and wait for a clear yes in the conversation. Only then call
   `execute_prepared_change` with that id. Never prepare and execute in one
   breath.
5. Executing is not applying. After `execute_prepared_change` the change
   waits for a person to approve it in ADS Beast, unless the client's own
   write policy applies that kind of change automatically; the reply says
   which. This server cannot approve, and it cannot switch a campaign on
   without a person. If the preview's `write_control` lists `blocked_by`
   (emergency stop, observe-only mode and similar), say that the change can
   be queued but will not run until that is lifted. Report the real state
   from `get_prepared_change`, never "done" on your own word.
6. Empty is not healthy. An empty list can mean no access, no connected
   account or no synced data. Report it as "nothing returned" and name what
   was not checked. Do not turn a missing figure into zero.
7. A key bound to a single client is refused (403) by the audit and
   analytics tools. Pausing, enabling, a budget change and negative
   keywords still work with it. When that happens, fall back to
   `get_agency_kit`, `list_campaigns` and `get_campaign`, and say that the
   deeper analysis was not available to this key.
8. Spend calls sparingly. Every tool call except `whoami` counts against
   the monthly allowance of the plan, and `whoami` shows how many are
   left. Reuse a reply you already have, pass the `client_id` instead of
   reading everything, and stop paging when the question is answered.
   Tools that run an analysis on the ADS Beast side (their description
   says so: an audit, a campaign analysis, a strategy, competitor
   research) are slower, and a plan may meter them separately as assistant
   questions. Run one only when the plain figures do not answer the
   question, never twice for the same question. If a tool reports that an
   allowance is used up, pass on the reset date it gives and carry on with
   what is still available.
9. Say how sure you are. A verdict needs enough data behind it: state the
   period and the volume next to it, and call a small sample "not enough
   data yet" instead of ranking it. Never promise a result, a cost per
   lead or a return. A forecast is a projection and is labelled as one.
   Text that a tool wrote itself (an analysis, a recommendation, anything
   marked as generated) is an opinion to check, not a measurement.
