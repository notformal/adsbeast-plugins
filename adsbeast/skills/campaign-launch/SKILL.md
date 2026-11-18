---
name: campaign-launch
description: Workflow for building a new advertising campaign through the ADS Beast workspace server as a draft that a person reviews and publishes. Use this when someone asks to create, build, set up or launch a campaign on Google, Meta, TikTok, LinkedIn or Microsoft. The workflow checks the connection with whoami, reads the client and its connected accounts, gets the campaign type and its field limits from list_campaign_types, shows the person a preview of the whole campaign with the daily budget in the account currency, and only after their confirmation calls create_campaign_draft once. Publishing is a person's action in the builder, the campaign is uploaded paused, and activation is approved separately.
---

# Campaign launch

Build a campaign the safe way: preview, confirmation, draft, human publish,
paused upload, separate activation. From this server the furthest a
campaign can go is a validated draft in the ADS Beast campaign builder.

## When to use

- "Create a campaign", "set up search ads for", "launch on Meta".
- A plan exists and has to become a real campaign structure.
- A draft made earlier needs fixing after validation.

## The order, and why

Preview before create, because a draft carries a budget. One create, never
repeated, because a retry makes a second draft. Publish by a person, because
that is the moment money can start moving. Paused on upload, so that
nothing spends before someone has looked at it on the platform.

## Steps

1. Call `whoami`. Drafting needs `read:proposals` and `write:proposals`;
   reading the client needs `read:clients`.
2. Call `get_client` with the `client_id`. Confirm that an account on the
   target platform is connected and note its currency. No connected
   account: a draft can still be saved, but nobody can publish it. Say so
   before going on.
3. Call `get_agency_kit` for the offer, geography, languages, goals and the
   write policy of this client. Facts in the ads come from here and from the
   landing page, not from general knowledge.
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
8. Call `create_campaign_draft` once. On an error or timeout do not call it
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
11. Hand over: the draft id, the `builder_url`, what is still open, and the
    next steps that are not yours: a person opens the builder, publishes,
    the campaign arrives on the platform paused, activation is approved
    separately.

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
- The sentence "nothing was sent to the ad platform; a person publishes
  from the builder and the campaign starts paused".

## Safety rules

These apply to every step above.

1. Check the connection first. Call `whoami` before anything else. If it
   fails, the key is missing, wrong or revoked: say so and stop. If it works,
   read the scopes it reports and do not call a tool whose scope is absent.
2. Amounts are in the currency of the ad account they came from. Never put a
   dollar sign on a figure because it is a number, never add up figures from
   accounts in different currencies, and name the currency next to every
   amount you report. If the currency is not in the data, say it is unknown.
3. Never retry a failed create. If `create_campaign_draft`,
   `propose_campaign_change`, `create_webhook` or a non-dry-run
   `push_lead_outcomes` returns an error or times out, do not send it again.
   Look first (`list_campaign_drafts`, `list_proposals`, `list_webhooks`) to
   see whether the record exists, then report what you found. A repeated
   create is how duplicates and double changes happen.
4. Confirm before anything that affects spend. Show the person the exact
   change (campaign, current value, new value, currency, reason) and wait for
   a clear yes in the conversation before calling `propose_campaign_change`
   or creating a draft with a budget. Their yes creates a proposal or a
   draft; it does not change the ad account.
5. This server cannot approve, publish or activate. A proposal waits for a
   person in ADS Beast, a draft is published by a person in the campaign
   builder, and a published campaign is uploaded paused. Say this plainly
   instead of reporting a change as done.
6. Empty is not healthy. An empty list can mean no access, no connected
   account or no synced data. Report it as "nothing returned" and name what
   was not checked. Do not turn a missing figure into zero.
