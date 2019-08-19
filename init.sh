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

    if [ "$users" != "${users#[Nn]}" ] ;then
        sed 's/users//g' buildly/bifrost-api/settings/base.py > buildly/bifrost-api/settings/base-buildly.py
    fi

    echo -n "Would you like to use Templates to manage reuseable workflows with Buildly? Yes [Y/y] or No [N/n]"
    read templates
    
    if [ "$templates" != "${templates#[Nn]}" ] ;then
        sed 's/templates//g' buildly/bifrost-api/settings/base.py > buildly/bifrost-api/settings/base-buildly.py
    fi
    echo -n "Would you like to enable the data mesh functions? Yes [Y/y] or No [N/n]"
    read mesh

    if [ "$mesh" != "${mesh#[Nn]}" ] ;then
        sed 's/mesh//g' buildly/bifrost-api/settings/base.py > buildly/bifrost-api/settings/base-buildly.py
    fi
fi
