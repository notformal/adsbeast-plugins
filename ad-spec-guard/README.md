# Ad Spec Guard

Verified specifications and decision thresholds for paid advertising, as a
plugin for ChatGPT, Codex and Claude.

No account, no sign-in, no API key.

## The problem it solves

Ask any assistant for a Google search headline and you will often get 43
characters. The limit is 30. The copy reads well, nothing in the conversation
flags a problem, and the ad is rejected when someone uploads it.

The same failure shows up in other shapes:

- A 1200x628 image briefed for a vertical story placement.
- A recommendation to pause a campaign that has collected eleven clicks.
- An A/B test called after 20 conversions against 25.
- A budget plan whose conversion rate was an industry average presented as a
  projection.

None of these are reasoning failures. They are recall failures. The model is
remembering a number instead of looking one up, and there is nothing in a chat
window that catches it.

This plugin replaces recall with lookup.

## Tools

All nine are read-only. They compute from specification tables and stated
formulas held in the server, reach no advertising account, and store nothing.

| Tool | What it answers |
| --- | --- |
| `get_platform_specs` | The full specification sheet for a platform: copy limits, image formats, learning-phase windows, bidding prerequisites. |
| `validate_ad_copy` | Which drafted fields exceed the platform's hard character limit, and by how much. |
| `validate_creative_spec` | Whether an image or video meets a placement's dimensions, aspect ratio, weight and file type. |
| `check_decision_readiness` | Whether there is enough data to pause, scale, rotate a creative or switch bidding, and what is still missing. |
| `ab_test_significance` | The p-value of an A/B comparison and the traffic still needed if it is inconclusive. |
| `build_utm` | A tagged URL with values normalised so they do not fragment into duplicate rows in analytics. |
| `validate_utm` | What is wrong with tagging already on a URL. |
| `estimate_budget_feasibility` | Whether a budget can reach a cost or return goal, without filling gaps with industry averages. |
| `check_ad_policy_preflight` | Which category and claim patterns in the copy commonly trigger policy rejection. |

Platforms covered: Google Ads, Meta, TikTok, LinkedIn, Microsoft Advertising.

## What it will not do

- It will not approve an ad. `check_ad_policy_preflight` matches patterns and
  links the governing policy page. Only the platform's review decides whether
  an ad runs, and clearing the pre-check is not an approval.
- It will not invent an input. `estimate_budget_feasibility` never substitutes
  a benchmark for a figure you did not supply. It solves for the value your
  goal would require and labels it a condition, not a forecast.
- It will not answer for a platform it does not hold specs for. An unrecognised
  platform is an error, not a clean result, because a typo coming back as "no
  violations found" is worse than no answer.

## Install

### ChatGPT and Codex

Open **Plugins**, search for Ad Spec Guard, and select **Install**. There is no
account to connect.

To try it before it is listed, add this repository as a marketplace:

```
codex plugin marketplace add notformal/adsbeast-plugins
```

### Claude Code

```
/plugin marketplace add notformal/adsbeast-plugins
/plugin install ad-spec-guard@adsbeast-plugins
```

### Any other MCP client

The server speaks streamable HTTP with no authentication:

```json
{
  "mcpServers": {
    "ad-spec-guard": {
      "type": "http",
      "url": "https://adsbeast.pro/api/mcp"
    }
  }
}
```

## Try it

- "Write three Google search headlines for a plumbing service and check the limits"
- "My Meta campaign has 14 clicks and no conversions after 3 days. Pause it?"
- "Is a 1200x628 image valid for an Instagram story placement?"
- "Variant A got 20 conversions from 1000 clicks, variant B got 25 from 1000. Is that a real difference?"
- "Build UTM tags for a Google search campaign called Spring Sale 2026"

## Privacy

The server receives the arguments of the tool call and nothing else. It holds
no account, sets no cookie, issues no identifier, and writes no request to
storage. Requests are not used to train anything.

Do not send personal data in ad copy you are checking. The tools have no use
for it, and none of them ask for it.

Full policy: https://adsbeast.pro/privacy

## Where the data comes from

Specification tables are maintained by Denha Nexus s.r.o. alongside
[ADS Beast](https://adsbeast.pro), an ad operations platform, and are
transcribed from the platforms' own published specifications.

Platforms revise limits without notice. Each answer reports its source, and
figures that are operating thresholds rather than platform rules say so in the
result. Where a number matters for a large build, confirm it against the
platform's own specification page.

## Support

Issues: https://github.com/notformal/adsbeast-plugins/issues

## Licence

MIT. See [LICENSE](../LICENSE).
