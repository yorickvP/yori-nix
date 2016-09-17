#!/usr/bin/env bash
set -e
userspace_update_cmd="$(cat <<EOF
echo "updating dotfiles"
if [ ! -d ~/dotfiles ]
then
    git clone git@git.yori.cc:yorick/dotfiles.git ~/dotfiles
else
    cd ~/dotfiles/
    git pull git@git.yori.cc:yorick/dotfiles.git
fi
~/dotfiles/install.sh
echo "updating userspace"
~/dotfiles/bin/update_userspace.sh
EOF
)"
if [ $1 == "local" ];
then
sudo nix-channel --update
echo "updating root conf"
./conf local-deploy
sh -c "$userspace_update_cmd"
else
	echo "updating" $1
	HOST=$(nix-instantiate --eval -A hostnames.$1 secrets.nix | tr -d '"')
	./conf remote-deploy $1 root@$HOST switch
	echo "updating userspace"
	#nix-copy-closure --to root@$HOST $(./conf remote nix-build --no-out-link "\<nixpkgs\>" -A hosts.$1)
	echo "nix-channel --update" | ssh root@$HOST
	cp deploy_key deploy_key2
	chmod 0600 deploy_key2
	ssh-agent bash <<J
ssh-add ./deploy_key2
rm ./deploy_key2
ssh -A $HOST sh -c "$userspace_update_cmd"
J
fi
