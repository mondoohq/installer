The following secrets are utilized when generating packages:

- AUR_EMAIL: Email Address used on Git Commits ("patrick@mondoo.com")
- AUR_USERNAME: Username for Git Commits ("Patrick Münch")
- AUR_SSH_PRIVATE_KEY: The SSH Private key for pushing changes to the AUR git repo, 

The first two will appear in the Git log, like: 

```
$ git log
commit d3a95cb518a1d6d1dc0eb6f6b910a596486985ac (HEAD -> master, origin/master, origin/HEAD)
Author: Patrick Münch <patrick@mondoo.com>
Date:   Tue Jul 25 09:33:55 2023 +0000

    8.20.0
```
