# Mondoo MSI Builder

This is home to the Mondoo MSI builder, which takes the cnquery and cnspec binaries
and merges them into a single MSI package, signed, sealed and delivered.

## Required Secrets

- MSI_SIGNING_CERT: The base64 encoded [DigiCert Code Signing Certificate](https://www.digicert.com/signing/code-signing-certificates)
- MSI_SIGNING_PASSWORD: Password protecting the certificate
