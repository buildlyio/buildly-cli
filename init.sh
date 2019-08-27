#!/bin/bash
# init
figlet buildly
echo -n "Buildy Core configuratioin tool, what type of app are building? [F/f] Fast and lightweight or [S/s] Scaleable and feature rich?"
read answer

if [ "$answer" != "${answer#[Ss]}" ] ;then
    echo "Cloning Buildly Core"
    git clone git@github.com:buildlyio/buildly.git

    echo -n "Would you like to Manage Users with Buildly? Yes [Y/y] or No [N/n]"
    read users
    
    # cp config file to make changes
    cp buildly/bifrost-api/settings/base.py buildly/bifrost-api/settings/base-buildly.py

    if [ "$users" != "${users#[Nn]}" ] ;then
        sed 's/users//g' buildly/bifrost-api/settings/base-buildly.py > buildly/bifrost-api/settings/base-buildly.py
    fi

    echo -n "Would you like to use Templates to manage reuseable workflows with Buildly? Yes [Y/y] or No [N/n]"
    read templates
    
    if [ "$templates" != "${templates#[Nn]}" ] ;then
        sed 's/workflow//g' buildly/bifrost-api/settings/base-buildly.py > buildly/bifrost-api/settings/base-buildly.py
    fi
    echo -n "Would you like to enable the data mesh functions? Yes [Y/y] or No [N/n]"
    read mesh

    if [ "$mesh" != "${mesh#[Nn]}" ] ;then
        sed 's/datamesh//g' buildly/bifrost-api/settings/base-buildly.py > buildly/bifrost-api/settings/base-buildly.py
    fi
fi

# create new repo
if ! [ -x "$(command -v hub)" ]; then    
    git clone \
    --config transfer.fsckobjects=false \
    --config receive.fsckobjects=false \
    --config fetch.fsckobjects=false \
    https://github.com/github/hub.git

    cd hub
    make install prefix=/usr/local
fi
cd ../buildly
rm -Rf .git
git init
git add -A .
git commit -m "a new buildly repo init"
# init remote in users repo
hub init -g
