# chocolatey

Chocolatey is a popular package manager for Windows, similar to Homebrew. This repository generates and updates "NuGet" packages for Chocolately.

- [View the Mondoo Overview Chocolatey](https://community.chocolatey.org/profiles/mondoo)
- [View our published packages here](https://community.chocolatey.org/packages?q=mondoo)
- [View our packages pending moderation here](https://community.chocolatey.org/packages?q=tag%3Amondoo&moderatorQueue=true&moderationStatus=all-statuses&prerelease=false&sortOrder=relevance')

## Package Lifecycle

It's very important to be aware of how packages are published for Chocolatey:

1. You create a NuGet and submit it to the Chocolatey API
2. A series of automated checks are carried out on the packages. If you look at the package page, you will see the new version in the [Version History](https://community.chocolatey.org/packages/cnquery#versionhistory), but it won't be "Listed" and it's Status will not be "Approved"
3. If all the checks pass, it waits until a Moderator (yes, a human) approves the package (***this can take hours to days***)
4. Once approved, the package is now listed and accessible

To learn more, review the Chocolatey [Package Review Process](https://docs.chocolatey.org/en-us/community-repository/moderation/#package-review-process) documentation.

## Building Packages

The basic process is simple:

```shell
choco apikey --key ${CHOCO_API_KEY} --source https://push.chocolatey.org/
choco pack
choco push 
```

To avoid using Windows, instead use a Docker container which runs Choco thanks to Mono. Here is a complete example of using it to pack and push:

```shell
$ docker run -v `pwd`:/packages -ti  chocolatey/choco bash
root@0ac102431698:~# cd /packages/cnquery

### Configure the APIKEY and Source
root@0ac102431698:/packages/cnquery# CHOCO_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
root@0ac102431698:/packages/cnquery# choco apikey --key ${CHOCO_API_KEY} --source https://push.chocolatey.org/
Chocolatey v1.3.0
Added ApiKey for https://push.chocolatey.org/


### Now Pack
root@0ac102431698:/packages/cnquery# choco pack
Chocolatey v1.3.0
Attempting to build package from 'cnquery.nuspec'.
Successfully created package '/packages/cnquery/cnquery.8.0.0.nupkg'


### Finally, Push
root@0ac102431698:/packages/cnquery# choco push
Chocolatey v1.3.0
Attempting to push cnquery.8.0.0.nupkg to https://push.chocolatey.org/
cnquery 8.0.0 was pushed successfully to https://push.chocolatey.org/
```

## About the API-Key

Our packages are owned and published by the ['mondoo'](https://community.chocolatey.org/profiles/mondoo) user, with the email/login of 'hello@mondoo.com'. The password is in BitWarden's 'Development' Collection entitled: "Chocolatey Mondoo User & API Key". You can find the API Key here: https://community.chocolatey.org/account

If you rotate the API key, be sure to update the CHOCOLATEY_API_KEY secret in this repo.

## Learn more

* [Chocolatey Guide: Running on Non-Windows Systems](https://docs.chocolatey.org/en-us/guides/non-windows)
* [Chocolatey Guide: Package Creation](https://docs.chocolatey.org/en-us/create/)
