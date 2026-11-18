---
name: campaign-launch
description: Workflow for building a new advertising campaign through the ADS Beast workspace server as a draft that a person reviews and publishes. Use this when someone asks to create, build, set up or launch a campaign on Google, Meta, TikTok, LinkedIn or Microsoft. The workflow checks the connection with whoami, reads the client and its connected accounts, gets the campaign type and its field limits from list_campaign_types, shows the person the whole campaign with the daily budget in the account currency, and only after their confirmation calls create_campaign_draft once. To publish, it rehearses with campaign_draft_publish_check, prepares the publish as a preview and submits it with execute_prepared_change. A person approves it in ADS Beast, the campaign is created paused, and switching it on is a separate decision by a person.
---

# Campaign launch

Build a campaign the safe way: show it, get a yes, save a draft, rehearse
the publish, prepare it, get a second yes, submit, and let a person
approve. The campaign is created paused. From this server it can never be
switched on without a person.

## When to use

- "Create a campaign", "set up search ads for", "launch on Meta".
- A plan exists and has to become a real campaign structure.
- A draft made earlier needs fixing after validation.

## The order, and why

Show before create, because a draft carries a budget. One create, never
repeated, because a retry makes a second draft. Rehearse before publish,
because the live account may refuse what the draft checker allowed. Approval
by a person, because that is the moment a campaign appears in the account.
Paused on creation, so that nothing spends before someone has looked at it
on the platform.

## Steps

1. Call `whoami`. Drafting and publishing need `read:proposals` and
   `write:proposals`; reading the client needs `read:clients`.
2. Call `get_agency_kit` with the `client_id`. Its list of accounts shows
   whether an account on the target platform is connected and how. An
   account connected through the platform's API can receive a campaign.
   Without one, a draft can still be saved but cannot be published from
   here. Say so before going on.
3. From the same reply take the offer, geography, goals, brand rules and
   the write policy of this client, and the currency its campaigns run in.
   Facts in the ads come from here and from the landing page, not from
   general knowledge.
4. Call `list_campaign_types` with the `platform`. Pick the type and read
   its `fields`: they are the exact shape and the character limits the draft
   must meet. Do not write copy to remembered limits.
5. Gather what is missing from the person: landing page, geography,
   languages, daily budget, goal. Ask; do not assume a budget.
6. Assemble the campaign and show it as a preview in the conversation:
   name, type, geography, languages, daily budget with currency, bid
   strategy, ad groups with keywords or audiences, every ad text, negative
   keywords, landing page. State that this will create a draft and nothing
   else.
7. Wait for a clear confirmation. Changes asked for at this point are made
   in the preview, and the preview is shown again.
8. Call `create_campaign_draft` once. The reply is long; the parts that
   matter are the draft id, `builder_url` and `validation`. On an error or timeout do not call it
   again: call `list_campaign_drafts` for the client, find out whether the
   draft exists, and continue from what is there.
9. Read the validation in the reply. `problems` block publishing,
   `warnings` do not, `launch_blockers` explain why a person could not
   publish right now. The checker writes in Russian; relay it in the
   person's language without softening it.
10. Fix problems with `update_campaign_draft`. Each field passed replaces
    the stored one whole, including `ad_groups`. Re-read with
    `get_campaign_draft` until `problems` is empty or the rest needs a
    person.
11. Report the draft: its id, the `builder_url`, what is still open. If
    the person only wanted a draft, stop here; they can publish from the
    builder themselves.
12. To publish from the conversation (Google Ads and Meta only): call
    `campaign_draft_publish_check` with the `client_id` and the draft id as
    `build_id`. It validates the draft against the live account and writes
    nothing. Relay what it says would be created. Fix what it refuses.
    The check also opens every landing page and sitelink address; a page
    that does not answer blocks publishing. Without a connected account
    of that platform the check fails on that alone: stop at the draft.
13. Call `prepare_campaign_draft_publish` with the same ids and a `reason`.
    It runs the same rehearsal and stores a preview only when it passes.
    If it is refused, relay the errors; do not call it again unchanged.
    Show the preview: what will be created, the budget with its currency,
    and that the campaign will be paused. Wait for a clear yes; this is a
    second confirmation, separate from the one for the draft.
14. Call `execute_prepared_change` once with the `preview_id`. It does not
    create the campaign on the spot: the change waits for a person to
    approve it in ADS Beast.
15. Call `get_prepared_change` to report the state. When it is executed,
    the campaign exists on the platform, paused. Switching it on is a
    separate change (`prepare_campaign_enable`) that always waits for a
    person. Do not offer to enable it in the same breath.

## Rules specific to launches

- Copy for Ukraine is in Ukrainian only. The builder enforces it; write it
  that way from the start.
- Search campaigns get negative keywords in the first draft, not later.
- A budget is per day and in the account currency. If the person gives a
  monthly figure or another currency, convert it with them, in the open.
- A draft that passed validation is not an approved ad. The platform
  decides that after upload.

## Reporting the result

- Draft id and `builder_url`.
- The final structure in brief, with the daily budget and currency.
- Open `problems`, `warnings` and `launch_blockers`, in the person's
  language.
- Exactly how far it went: draft only; publish submitted and waiting for
  approval; or created on the platform, paused. Never "launched" for a
  campaign that is paused or still waiting.

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
   A long tool may answer `status: running` with a `job_id` instead of a
   result: the work goes on in ADS Beast. Tell the user it is still
   running, wait the number of seconds it gives (about 15), then call
   `get_job_result` with that `job_id`; repeat while it says running.
   Never call the original tool again to get the result: that starts and
   charges a second run. `failed` carries the reason; `expired` means run it again.
9. Say how sure you are. A verdict needs enough data behind it: state the
   period and the volume next to it, and call a small sample "not enough
   data yet" instead of ranking it. Never promise a result, a cost per
   lead or a return. A forecast is a projection and is labelled as one.
   Text that a tool wrote itself (an analysis, a recommendation, anything
   marked as generated) is an opinion to check, not a measurement.
