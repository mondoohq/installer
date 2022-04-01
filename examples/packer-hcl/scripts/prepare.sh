set -ux

# update all packages
sudo apk update && apk upgrade

# add ssh, bash for login and curl to fetch vagrant ssh key
sudo apk add bash curl