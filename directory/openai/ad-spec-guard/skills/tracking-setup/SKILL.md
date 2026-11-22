---
name: tracking-setup
description: Workflow for building UTM tagging and campaign naming that stays consistent across ad platforms, and for checking a planned budget against a CPA or ROAS goal before the campaign is built. Use this when someone asks how to tag a landing page URL, wants a naming convention for campaigns, ad sets or ads, is about to launch and needs the tracking plan, finds that traffic is landing in analytics as direct or unattributed, or asks whether a monthly budget can reach a target cost per acquisition or return on ad spend. The workflow builds each tagged URL with build_utm so the parameters and the naming convention are validated rather than hand-typed, and runs estimate_budget_feasibility for the goal check, labelling every input that was assumed rather than measured so the resulting forecast is not read as a promise.
---

# Tracking setup

This workflow covers the two things that are cheap before a campaign goes
live and expensive afterwards: the tracking parameters on the landing page
URLs, and an honest arithmetic check of whether the planned budget can
reach the stated goal.

Inconsistent tagging is not visible until reporting time, when the same
campaign appears under several spellings and the totals no longer add up.
Build the URLs and names through the tools so the convention is applied the
same way every time. The conventions and the arithmetic behind these tools
come from ADS Beast.

## When to use

- A campaign is about to launch and the landing page URLs need tagging.
- A naming convention is being defined or applied across platforms.
- Analytics shows paid traffic as direct, unassigned or split across
  near-duplicate source and medium values.
- Someone asks what source, medium, campaign, term or content should be.
- A monthly budget has been proposed and a CPA or ROAS goal has been stated.
- A media plan or a launch checklist is being written.

## Steps

1. Collect the landing page URL, the platform, and the campaign this traffic
   belongs to. Collect the naming convention if one already exists, so the
   new names match the old ones.
2. Call `build_utm` for each destination URL with base_url, source, medium,
   campaign, and term or content where the platform provides them. Pass the
   existing convention so the output matches what is already in the account.
3. Read the validation output. Fix anything the tool flags, such as an
   inconsistent medium value, a spelling variant of an existing source, or
   a parameter that would collide with an existing one.
4. Use the returned URLs verbatim. Do not retype or reorder the parameters,
   and do not edit the query string by hand afterwards.
5. Repeat per platform and per destination so every variant in the campaign
   carries a tagged URL.
6. For the budget check, collect the monthly budget and the goal, plus
   whichever of target_cpa, target_roas, avg_order_value, expected_cvr and
   expected_cpc are actually known from past data.
7. Call `estimate_budget_feasibility` with those values. Pass measured
   numbers where they exist. Where a number is an assumption, say so and
   keep the assumption visible in the output rather than folding it into the
   result.
8. If the tool reports the budget cannot reach the goal, report the gap and
   the levers: a larger budget, a higher conversion rate, a lower cost per
   click or a looser goal. Do not adjust an input until the answer comes out
   favourable.

## Reporting the result

- The full tagged URL per destination, ready to copy.
- The naming convention applied, and any existing name it was aligned with.
- Anything the tool flagged during validation and how it was resolved.
- For the budget check: the result, and a separate list naming each input
  that was an assumption rather than a measurement, with where the assumed
  value came from.
- The sensitivity where it matters, for example what the result becomes if
  an assumed conversion rate is half the assumed value.

## Do not

- Do not hand-write UTM parameters or a campaign name without running
  `build_utm` on them.
- Do not mix conventions across platforms in the same account.
- Do not present an estimate built on assumed inputs as a forecast or a
  target. Label the assumptions.
- Do not invent a conversion rate, an average order value or a cost per
  click and then report the output as if it were measured.
- Do not change an input in order to make the feasibility result come out
  positive.
- Do not drop the existing parameters already on a landing page URL when
  adding new ones.
