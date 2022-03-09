# Assess state of individual instances with EC2 Instance Connect

## Precondition

 * [Mondoo CLI installed on workstation](https://mondoo.com/docs/operating_systems/installation/installation)

## Spin Up EC2 instance

Spin up a Amazon Linux 2 instance. By default [EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html) is configured.


## Assess Security with Mondoo

Run `mondoo` to assess the security of the server:

```
$ mondoo scan -t aws-ec2-connect://ec2-user@i-0b033277c54499187 --insecure ../shared/policies/linux-baseline.yaml --incognito --sudo
→ Mondoo 5.15.0 (Space: "//captain.api.mondoo.app/spaces/musing-saha-952142", Service Account: "1zDY7cJ7bA84JxxNBWDxBdui2xE", Managed Client: "1zDY7auR20SgrFfiGUT5qZWx6mE")
→ loaded configuration from /Users/chris/.config/mondoo/mondoo.yml using source default
                        .-.            
                        : :            
,-.,-.,-. .--. ,-.,-. .-' : .--.  .--. ™
: ,. ,. :' .; :: ,. :' .; :' .; :' .; :
:_;:_;:_;`.__.':_;:_;`.__.'`.__.'`.__.'

→ discover related assets for 1 asset(s)
→ resolved assets resolved-assets=1
→ execute policies
→ enabled incognito mode
→ establish connection to asset ip-172-31-87-237.ec2.internal (unknown)
→ run policies for asset asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21ZAVC4Zch55xtdVX1ITPI583yk

███████████████████████████████████████████████████████████████████████████ 100% ip-172-31-87-237.ec2.internal

→ send all results asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21ZAVC4Zch55xtdVX1ITPI583yk
→ generate report asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21ZAVC4Zch55xtdVX1ITPI583yk
→ scan complete asset=//assets.api.mondoo.app/spaces/musing-saha-952142/assets/21ZAVC4Zch55xtdVX1ITPI583yk

ip-172-31-87-237.ec2.internal
=============================

┌▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄┐
│   ___                      │
│  / __|+  Fair 50/100       │
│ | (__    100% complete     │
│  \___|   ▄▄ ▄▄             │
└────────────────────────────┘

Url: https://console.mondoo.app/space/fleet/21ZAVC4Zch55xtdVX1ITPI583yk?spaceId=musing-saha-952142

Asset Policy 21ZAVC4Zch55xtdVX1ITPI583yk
----------------------------------------

■  C+  Linux Security Baseline

Linux Security Baseline
-----------------------

┌▄▄▄▄▄▄▄▄▄┐
│   ___   │  Policy:  Linux Security Baseline
│  / __|+ │  Version: 2.8.1
│ | (__   │  Mrn:     //policy.api.mondoo.app/spaces/musing-saha-952142/policies/linux-baseline
│  \___|  │  Score:   50 (completion: 100%, via average score)
└─────────┘

Scoring Queries:
┌──────────────────────────────────────┐
│ Passed:  ███████████████ 50.0%       │
│ Failed:  ███████████████ 50.0%       │
│ Errors:  0.0%                        │
│ Ignored: 0.0%                        │
│ Unknown: 0.0%                        │
└──────────────────────────────────────┘



Summary
=======

Asset Overview

■  C+  ip-172-31-87-237.ec2.internal

Aggregated Policy Overview

Linux Security Baseline ████████████████████████████████████████████████████████ C: 1 

```