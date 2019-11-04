#!/bin/bash
# init
figlet buildly
echo -n "Buildy Core configuratioin tool, what type of app are building? [F/f] Fast and lightweight or [S/s] Scaleable and feature rich?"
read answer

if [ "$answer" != "${answer#[Ss]}" ] ;then
    echo "Cloning Buildly Core"
    git clone git@github.com:buildlyio/buildly-core.git

    echo -n "Would you like to Manage Users with Buildly? Yes [Y/y] or No [N/n]"
    read users

    # cp config file to make changes
    # this should have 4 config files (1 with all modules base.py, 1 with Templates and Mesh, and 1 with just Template, and 1 with just Mesh)
    # then the Mesh should just be an option
    cp buildly-core/buildly/settings/base.py buildly-core/buildly/settings/base-buildly.py

    if [ "$users" != "${users#[Nn]}" ] ;then
        sed 's/users//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi

    echo -n "Would you like to use Templates to manage reuseable workflows with Buildly? Yes [Y/y] or No [N/n]"
    read templates

    if [ "$templates" != "${templates#[Nn]}" ] ;then
        sed 's/workflow//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi
    echo -n "Would you like to enable the data mesh functions? Yes [Y/y] or No [N/n]"
    read mesh

    if [ "$mesh" != "${mesh#[Nn]}" ] ;then
        sed 's/datamesh//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi
fi

# set up application and services
mkdir YourApplication
mv buildly-core YourApplication/
mkdir YourApplication/services

echo -n "Would you like to import a service from the marketplace? Yes [Y/y] or No [N/n]"
read service_answer2

if [ "$service_answer2" != "${service_answer2#[Yy]}" ] ;then
  # list marketplace open source repost
  curl -s https://api.github.com/orgs/Buildly-Marketplace/repos?per_page=1000 | grep git_url |awk '{print $2}'| sed 's/"\(.*\)",/\1/'

  # clone all repositories
  for repo in `curl -s https://api.github.com/orgs/Buildly-Marketplace/repos?per_page=1000 |grep git_url |awk '{print $2}'| sed 's/"\(.*\)",/\1/'`;do
    remove="git://github.com/Buildly-Marketplace/"
    name=${repo//$remove/}
    echo -n "Would you like to clone and use " $name " from the marketplace? Yes [Y/y] or No [N/n]"
    read service_answer3

    if [ "$service_answer3" != "${service_answer3#[Yy]}" ] ;then
      git clone $repo YourApplication/services/$name;
    fi
  done;
fi

echo -n "Now... would you like to create a new service from scratch? Yes [Y/y] or No [N/n]"
read service_answer

if [ "$service_answer" != "${service_answer#[Yy]}" ] ;then
  cd django-service-wizard
  # create a new service use django-service-wizard for now
  docker-compose run --rm django_service_wizard -u $(id -u):$(id -g) -v "$(pwd)":/code || echo "Docker not configured, installed or running"
fi

cd ../YourApplication

echo "Buildly services cloned and ready for configuration"

echo -n "Now... would you like to connect your services to docker and a minikube instance? Yes [Y/y] or No [N/n]"
read mini_kube

if [ "$mini_kube" != "${mini_kube#[Yy]}" ] ;then
  # start mini kube if not already
  minikube start
  # clone the helm chart to deploy core to minikube
  git clone https://github.com/buildlyio/helm-charts.git
  # setup kubectl context and configure to use minikube and buildly
  kubectl config use-context minikube
  kubectl config set-cluster minikube
  kubectl create namespace buildly || echo "Name space buildly already exists"
  echo "Configure your buildly core to connect to a Database..."
  echo -n "Enter host name or IP:"
  read dbhost
  echo -n "Enter Database Port:"
  read dbport
  echo -n "Enter Database Username:"
  read dbuser
  echo -n "Enter Database Password:"
  read dbpass
  # start helm
  helm init
  # install to minikube via hlem
  helm install . --name buildly-core --namespace buildly \
  --set configmap.data.DATABASE_HOST=$dbhost \
  --set configmap.data.DATABASE_PORT=$dbport \
  --set secret.data.DATABASE_USER=$dbuser \
  --set secret.data.DATABASE_PASSWORD=$dbpass

  # build local images for each service
  cd YourApplication/services
  for service in ls
    cd $service
    # build a local image
    docker-compose build $service
    # deploy to kubectl
    kubectl run $service --image=$service --image-pull-policy=Never -n buildly
    cd ../
  done

  # check on pods
  kubect get pods -n buildly

  echo "Done!  Check you configuration and pods running your minikube and start coding!"
  echo "Trouble? try the README files in the core or go to https://buildly-core.readthedocs.io/en/latest/"
fi
