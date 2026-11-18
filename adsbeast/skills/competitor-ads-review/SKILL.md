---
name: competitor-ads-review
description: Workflow for reviewing what a client's competitors advertise, using the ADS Beast workspace server. Use this when someone asks what competitors are running, wants a competitor ads review, competitor messaging, offers and calls to action, or ideas for differentiating the client's own ads. The workflow checks the connection with whoami, reads the client's niche and market, starts from the competitors and collected ads already on record in competitor_list, reads named competitor sites with competitor_site_analyze, searches with competitor_search_intel, and uses competitor_ads_research for angles in the niche. The report separates what was observed from what was inferred, gives no competitor spend figures, and changes nothing in any ad account.
---

# Competitor ads review

Describe how the client's competitors present themselves in ads and on
their sites: offers, angles, calls to action, prices they show. Then say
where the client's own message is the same and where it could differ.

Most of what this workflow returns is research, not measurement. The
server holds the competitors a team has recorded and can read a public
site. It has no access to a competitor's ad account, and it does not see
their spend, their results or every ad they run.

## When to use

- "What are our competitors advertising", "review competitor ads".
- New ad copy is being planned and nobody has looked at the market.
- A client asks why a rival's offer seems to be everywhere.

## Steps

1. Call `whoami`. The review needs `read:clients`; `write:tasks` only if a
   follow-up task will be created.
2. Call `get_client` with the `client_id` for the niche, the market and
   the site. The review is made for this niche and this country, not in
   general.
3. Call `competitor_list` with the `client_id`. These are competitors the
   team has on record, with site and niche. Pass `with_ads` true when the
   collected ads are wanted; the reply is larger. Records here were
   gathered earlier, so give the age of the data if the reply shows it.
4. If nothing is on record, ask the person which competitors matter, by
   domain. Do not pick competitors yourself from general knowledge and
   present them as the client's market.
5. For each named competitor, at most three unless the person asks for
   more, call `competitor_site_analyze` with the `url` and the
   `client_id`. It reads the public site: selling points, prices shown,
   calls to action, tracking pixels. This is observed, and it is the most
   reliable part of the review. It never stores anything in the client's
   market analysis; that is done in ADS Beast itself.
6. Call `competitor_search_intel` with the `client_id`, the
   `competitor_domain` and `aspect` set to `ads` (or `pricing`,
   `positioning`). It returns web search results with titles, snippets
   and addresses. Always pass a domain: without one the results are loose
   and often unrelated. Read the snippets before using them, drop the
   ones that are not about this competitor, and keep the address next to
   every claim so a person can open it.
7. Call `competitor_ads_research` once with the `niche`, the `geo` as a
   country code and the `client_id`. It returns common angles, calls to
   action and suggested points of difference for the niche. Read its
   `source` field: when it says the content was generated, every line of
   it is an inference about the market, not an ad that was seen. It may
   also answer that it has too little to go on; then say so. It runs an
   analysis on the ADS Beast side, so do not repeat it with small
   variations.
8. Optionally, for one competitor the person cares about most, call
   `competitor_social_signals` with the `competitor_url` and the
   `client_id` for recent public activity outside the site.
9. Compare with the client: `get_agency_kit` with the `client_id` gives
   the client's own offer, voice and brand rules. Name where the client
   says the same as everyone else and where it has something the others
   do not show.
10. Report, then stop. If the person wants a follow-up recorded, call
    `task_create` with a `title`, a `priority` and the `client_id` after
    they agree.

## Reading the result

- Three labels only: observed on the competitor's site, found in search
  with a link, inferred. Never merge them into one list.
- An inferred angle is a hypothesis to check in the public ad libraries
  (Meta Ad Library, Google Ads Transparency Center). Say that, and give
  the person the competitor name to look up.
- No figures for a competitor's budget, traffic, cost per lead or
  results. This server has none, and an estimate would be invented.
- Do not copy a competitor's ad text, and do not suggest bidding on or
  writing ads with a competitor's brand name without telling the person
  that trademark rules differ by country and platform.
- A competitor that was not found is "not found by this search", not
  "does not advertise".

## Reporting the result

- The competitors covered and where each one came from (on record, named
  by the person).
- Per competitor: offer, prices shown, calls to action, with the label
  and the address behind each line.
- Angles for the niche, marked as inferred where they are.
- Where the client overlaps and two or three differences worth testing,
  worded as tests, not as outcomes.
- What was not covered: ad libraries were not read by this server, no
  spend data, competitors without a site reading.
- No change was made to any ad account.

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
   waits for a person to approve it in ADS Beast, unless the client's owner
   switched on assistant auto-apply for that client and its write policy
   allows the change (pauses, budgets within limits, negatives only); the
   reply says which. This server cannot approve, and it cannot switch a campaign on
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
