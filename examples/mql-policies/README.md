# MQL Policies - Policy as Code

The following policies implement a Linux and SSH Security Policy. They are are derived from Apache 2 -Licensed DevSec's Linux and SSH Baselines.

You can easily run them locally:

```bash
mondoo scan --incognito linux-baseline.yaml
```

To run the policy for a remote target (also enables sudo):

```bash
$ mondoo scan -t ssh://chris@5.9.18.140 --sudo --incognito linux-baseline.yaml

Debian-107-buster-64-minimal
============================

┌▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄┐
│    _                       │
│   /_\    Excellent 85/100  │
│  / _ \   100% complete     │
│ /_/ \_\  ▄▄ ▄▄ ▄▄ ▄▄       │
└────────────────────────────┘

Url: https://console.mondoo.app/space/fleet/21erPr7OX7uxHkMc3DmE0VgSg3o?spaceId=musing-saha-952142

Asset Policy 21erPr7OX7uxHkMc3DmE0VgSg3o
----------------------------------------

■  A   Linux Security Baseline

Linux Security Baseline
-----------------------

┌▄▄▄▄▄▄▄▄▄┐
│    _    │  Policy:  Linux Security Baseline
│   /_\   │  Version: 2.8.1
│  / _ \  │  Mrn:     //policy.api.mondoo.app/spaces/musing-saha-952142/policies/linux-baseline
│ /_/ \_\ │  Score:   85 (completion: 100%, via average score)
└─────────┘

Scoring Queries:
┌──────────────────────────────────────┐
│ Passed:  ███████████████████ 85.7%   │
│ Failed:  ██ 14.3%                    │
│ Errors:  0.0%                        │
│ Ignored: 0.0%                        │
│ Unknown: 0.0%                        │
└──────────────────────────────────────┘

...
```