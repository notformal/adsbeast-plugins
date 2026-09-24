# ADS Beast plugins

Plugins for ChatGPT, Codex and Claude, maintained by
[Denha Nexus s.r.o.](https://adsbeast.pro)

| Plugin | What it does | Account required |
| --- | --- | --- |
| [ad-spec-guard](./ad-spec-guard) | Verified platform specifications, creative specs, statistical gates before acting on a campaign, UTM tagging and policy pre-checks. | No |
| [adsbeast](./adsbeast) | Your own ADS Beast workspace: leads with attribution, campaigns, clients, alerts, tasks, conversion outcomes and webhooks. | Yes |

## Add this marketplace

### Codex

```
codex plugin marketplace add notformal/adsbeast-plugins
```

### Claude Code

```
/plugin marketplace add notformal/adsbeast-plugins
/plugin install ad-spec-guard@adsbeast-plugins
/plugin install adsbeast@adsbeast-plugins
```

## Why these exist

An assistant helping with paid advertising fails in a specific, repeatable way:
it recalls a platform limit instead of checking one. The copy reads well and
the ad is rejected on upload. The same shape of failure produces creative at
the wrong dimensions, campaigns paused on a dozen clicks, and budget plans
built on an industry average presented as a projection.

These plugins answer from maintained tables and stated formulas, and say
plainly when a figure is an operating threshold rather than a platform rule.

## Licence

MIT. See [LICENSE](./LICENSE).
