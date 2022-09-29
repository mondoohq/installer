![Mondoo](https://mondoo.com/docs/img/mondoo.logo.svg)

> This is a legacy repo. We recommend using [mondoo/client](https://hub.docker.com/r/mondoo/client) instead.

# Quick reference

* Basic use: ```docker run mondoo/client <args>```
* Sign up for free: https://console.mondoo.com
* Release Notes: https://mondoo.com/releases/
* Documentation: [mondoo.com/docs](https://mondoo.com/docs/)
* Where to get help: [Mondoo Community GitHub Discussions](https://github.com/orgs/mondoohq/discussions)
* Dockerfile Source: https://github.com/mondoohq/client/blob/master/Dockerfile
* Where to file issues: https://github.com/mondoohq/client/issues
* Mondoo Client Binary Downloads (Non-Container):  https://releases.mondoo.com/mondoo/
* Supported Architectures: `amd64`, `arm64`, `i386`, `arm32v6`, `arm32v7`

# Supported tags
- `latest` - always pinned to the latest release of Mondoo Client
- `6` - starting from `6.3.0` we offer a major version container, which is always pinned to the latest release for a given major version
- `6.4.0` - always pinned to a specific Mondoo Client release

# What is Mondoo

Mondoo is a cloud security platform for infrastructure developers. Using Mondoo, your team will get an automated risk assessment and real-time insights into all of your business-critical infrastructure, across all of your infrastructure platforms.

## Policy as Code

Security policies, compliance frameworks, or other types of regulatory policies, typically start in the form of a document that describes the policy, the rationale for it, as well as the impact, risk, or consequence if the policy is not followed. Some of the best examples of security policies are the <a href="https://www.cisecurity.org/cis-benchmarks/" target="_blank">CIS Benchmarks</a> which cover everything from operating systems, to containers and Kubernetes, and entire cloud platforms.

While the CIS Benchmarks provide detailed information for each individual rule or control, including auditing and remediation steps, it still falls to individuals within an organization to carry out the work of implementing these policies. The work to prove compliance with CIS Benchmarks is often manual, which can lead to errors. When carried out as an exercise such as passing an audit, manual compliance only provides a temporary, snapshot in time, rather than an automated and continuous assessment.

As change is constant in modern application and infrastructure environments, it is critical businesses have a way of applying policy in a manner that is fast, efficient, and fully automated using code.

## Business-Critical Infrastructure

Business-critical infrastructure is any infrastructure in which major fault or interruption will result in a high cost for the business.

Some high-level examples of business-critical infrastructure may include:

- Public cloud environments such as AWS, GCP, Azure, and Microsoft 365
- Private cloud environments such as VMware (VCenter and ESXi)
- Kubernetes Clusters (EKS, GKE, AKS, and self-managed)
- Servers and Endpoints (Linux, Windows, and macOS)
- Software Supply Chain services and tooling (GitHub, GitLab, Jenkins, Azure DevOps Pipelines, CircleCI, and more)

Within the examples above there are many individual assets and resources that are critical to operating a secure business such as SSL certificates, system packages, and SSH configurations.

Mondoo is designed to ensure you have real-time visibility, and continuous assessment not just at the high-level, but also down to each individual component.

## Continuous, Automated Risk Assessment

Change in your environment is constant, and the need to audit your system's configuration must be continuously monitored.

Mondoo continuously monitors your business-critical systems according to the policies you apply and reports any deviation from those policies so that you can take immediate action.

Additionally, Mondoo policies also update continuously as new versions of benchmarks are released, or as they are customized to meet your specific requirements. Mondoo continuously checks for updates to policies and will immediately execute new versions of policies across any systems where those policies have been applied giving you real-time visibility.

## Real-Time Answers to Your Most Pressing Questions

Mondoo Query Language (MQL) is a simple to understand, yet extremely powerful graphql-like query language that can be used to answer fine-grained questions about your entire fleet, or specific assets and resources within your fleet.

Mondoo queries can be run in real-time to provide answers to the most pressing security concerns, or you can use Mondoo queries to create policies that run continuously across your environment.

## Certified Security Policies

Mondoo comes stocked with a massive library of certified security policies and benchmarks built on MQL, that are ready to be deployed across your fleet on day one.

Mondoo content is designed to be both flexible, and extensible. Use our content as-is to discover security vulnerabilities, exploits, and misconfigurations within your fleet, or easily customize the policies as needed per application, environment, team, business unit, or account.

Should you need to develop your own policies from scratch, MQL is both fast and easy to learn.

## Ready to Get Going?

Sign up at https://console.mondoo.com today!