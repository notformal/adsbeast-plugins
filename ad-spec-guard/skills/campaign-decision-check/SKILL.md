---
name: campaign-decision-check
description: Workflow to run before recommending that a live paid campaign be paused, scaled, given a budget change or switched to a different bidding strategy, and before calling any metric good or bad. Use this when someone shares campaign numbers such as clicks, spend, conversions, CTR, CPA or ROAS and asks what to do, when a campaign is described as underperforming or as ready to scale, or when two ad variants are being compared. The workflow calls check_decision_readiness to establish whether the observed data supports the decision at all, states plainly when it does not and names what is still missing, and uses ab_test_significance for any A/B comparison instead of reading the difference off the numbers. Small samples move a lot by chance, so a decision taken on too little data is a guess presented as analysis.
---

# Campaign decision check

This workflow sits in front of every recommendation to change a running
paid campaign. Before advising a pause, a scale-up, a budget change or a
bidding change, establish whether the data underneath the decision is enough
to support it. The readiness thresholds come from the Ad Spec Guard tools,
maintained by ADS Beast, not from a rule of thumb recalled on the spot.

A campaign with a handful of clicks and one conversion has a CPA, but that
CPA carries almost no information. Saying so is the useful answer. Naming
the exact amount of additional data needed is more useful than a confident
recommendation built on noise.

## When to use

- Someone asks whether to pause, kill, scale, raise or lower budget, or
  change bidding on a live campaign, ad set or ad.
- Someone shares performance numbers and asks if they are good or bad.
- A campaign, ad group or creative is described as a winner or a loser.
- Two or more variants are being compared and one is called better.
- A recommendation is about to be written into a report, an audit or a
  client update.

## Steps

1. Collect the decision being considered and the observed data: platform,
   the specific decision, clicks, spend, conversions and days running. Ask
   for whichever of these is missing rather than filling it in.
2. Call `check_decision_readiness` with the platform, the decision and the
   data that exists. Pass only measured values; leave unknown arguments out
   rather than estimating them. Pick the decision that matches the question:
   `judge_rate_metric` for a verdict on a click-through rate or conversion
   rate, which is gated on clicks; `judge_metric` for a verdict on cost per
   acquisition or return on ad spend, which is gated on conversions. Asking
   for conversions before answering a question about click-through rate is
   the wrong gate.
3. Read the result before forming an opinion. If it reports the data is
   insufficient, that is the finding. Report what is missing and how much
   more is needed.
4. If the data is sufficient, make the recommendation and cite the
   readiness result as the basis for it.
5. For any comparison between two variants, call `ab_test_significance`
   with the trials and successes for each side. Use clicks as trials and
   conversions as successes for a conversion rate test, or impressions and
   clicks for a CTR test. Keep the units consistent across both variants.
6. Read the p-value and the significance flag. If the difference is not
   significant, say the two variants are not yet distinguishable and report
   the additional sample the tool says is needed.
7. If budget is part of the decision, run `estimate_budget_feasibility`
   against the CPA or ROAS goal and mark which inputs were assumptions.

## Reporting the result

- The decision that was assessed and the data it was assessed on.
- Whether the data was sufficient, as returned by the tool.
- If insufficient: what is missing, in the units the tool reported, and the
  recommendation to keep collecting rather than act.
- If sufficient: the recommendation, with the numbers that support it.
- For an A/B comparison: the p-value, the significance verdict and the
  additional sample needed if the result is not yet significant.
- Any metric that was reported as a rate without the underlying counts, so
  the reader knows the denominator was not available.

## Do not

- Do not recommend a pause, a scale or a bidding change before calling
  `check_decision_readiness`.
- Do not call a CTR, CPA or ROAS good or bad without saying what it is being
  compared against.
- Do not declare an A/B winner by comparing two percentages. Run the test.
- Do not conclude a test on a handful of clicks or a single conversion.
- Do not convert an insufficient-data result into a hedged recommendation.
  Say the data is insufficient.
- Do not fill a missing input with a plausible number in order to get a
  result out of a tool.
