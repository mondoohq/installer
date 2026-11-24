# Mondoo MSI Builder

This is home to the Mondoo MSI builder, which takes the mql and cnspec binaries
and merges them into a single MSI package, signed, sealed and delivered.

## Required Secrets

- MSI_SIGNING_CERT: The base64 encoded [DigiCert Code Signing Certificate](https://www.digicert.com/signing/code-signing-certificates)
- MSI_SIGNING_PASSWORD: Password protecting the certificate
- INSTALL_TEST_MONDOO_REGISTRATION_TOKEN: Registration token for the release test space on edge (see below)

## Release test

Before an MSI is published, the `Test Signed Package` job in
[`pkg_msi.yaml`](../../.github/workflows/pkg_msi.yaml) installs it on a Windows
runner and checks it:

1. The MSI signature is valid.
2. The MSI installs, the `Mondoo` service has its recovery settings, and a repair
   install (`msiexec /fa`) keeps them.
3. `mql` and `cnspec` report the release version and can query the local system.
4. `cnspec login` registers with edge using `INSTALL_TEST_MONDOO_REGISTRATION_TOKEN`.
5. `cnspec scan` runs [`test/cnspec/mondoo-windows-installer.mql.yaml`](../../test/cnspec/mondoo-windows-installer.mql.yaml)
   with `--score-threshold 100`. The policy checks the package, the binaries in
   `C:\Program Files\Mondoo`, the `Mondoo` service, the `HKLM\SOFTWARE\Mondoo`
   registry key, and the config file the login wrote.
6. `cnspec logout` removes the agent again.

If this job fails, the MSI is not published, and neither are the container,
Chocolatey, Homebrew and Arch packages.

### The edge test space

The test logs in to a dedicated space on edge. Its registration token is stored as
`INSTALL_TEST_MONDOO_REGISTRATION_TOKEN`, and the token's description names the
installer release tests, so `cnspec login` prints it at the start of the step.

**Do not delete this space.** If it is gone, `cnspec login` fails with
`could not create agent credential`, and the release is blocked until the token is
replaced (see below).

The policy is kept in this repo rather than in the space, so the space holds no state
the test depends on. `cnspec scan --policy-bundle` runs a local bundle incognito,
so nothing is uploaded to the space either.

### Replacing the space or the token

1. Create a space on edge, or pick an existing one that will be kept.
2. Create a registration token in it: no expiry, agent role, and a description
   that says what uses it.
3. Store it as the `INSTALL_TEST_MONDOO_REGISTRATION_TOKEN` repository secret.
4. Re-run the failed release jobs: `gh run rerun <run-id> -R mondoohq/installer --failed`.

### Changing the policy

Lint it before you push:

```bash
cnspec policy lint test/cnspec/mondoo-windows-installer.mql.yaml
```

Every check must pass on a fresh install, so check only what the MSI itself sets up.
For example, the standard MSI installs the service with `demand` start, so the
policy checks that the service is installed, not that it is running.
