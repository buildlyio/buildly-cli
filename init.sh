#!/bin/bash

#
# This is a command line interface for buildly platform.
#
# LICENSE: GPL-3.0
#
# CONTACT: team@buildly.io
#


###############################################################################
#
# Make sure Bash is at least in version 4.3
#
###############################################################################
if ! ( (("${BASH_VERSION:0:1}" == "4")) && (("${BASH_VERSION:2:1}" >= "3")) ) \
  && ! (("${BASH_VERSION:0:1}" >= "5")); then
    echo ""
    echo "Sorry - your Bash version is ${BASH_VERSION}"
    echo ""
    echo "You need at least Bash 4.3 to run this script."
    echo ""
    exit 1
fi

###############################################################################
#
# Global variables
#
###############################################################################

github_url="https://github.com"
github_api_url="https://api.github.com"
buildly_core_repo_path="buildlyio/buildly-core.git"
buildly_helm_repo_path="buildlyio/helm-charts.git"
buildly_mkt_path="Buildly-Marketplace"

###############################################################################
#
# Global Functions
#
###############################################################################

# method responsible for starting a minikube instance
setupMinikube()
{
  status=$(minikube status)
  if [[ ! ( $status == *"host: Running"*  &&  $status == *"kubelet: Running"* &&  $status == *"apiserver: Running"* \
  &&  $status == *"kubeconfig: Configured"*) ]]; then
    minikube start
  else
    echo "The current Minikube instance will be used"
  fi

  kubectl config use-context minikube
  kubectl config set-cluster minikube
}

# method responsible for initializing helm
setupHelm()
{
  status=$(helm version)
  if [[ ! ( $status == *"Client: &version.Version"*  &&  $status == *"Server: &version.Version"*) ]]; then
    helm init
  else
    echo "Helm is already configured"
  fi
}

# method to clone buidly into the application folder
setupBuildlyCore()
{
  echo -n "Buildy Core configuration tool, what type of app are building? [F/f] Fast and lightweight or [S/s] Scaleable and feature rich? "
  read answer

  if [ "$answer" != "${answer#[Ss]}" ] ;then
    echo "Cloning Buildly Core"
    git clone "$github_url/$buildly_core_repo_path" "buildly-core"

    echo -n "Would you like to Manage Users with Buildly? Yes [Y/y] or No [N/n] "
    read users

    # cp config file to make changes
    # this should have 4 config files (1 with all modules base.py, 1 with Templates and Mesh, and 1 with just Template, and 1 with just Mesh)
    # then the Mesh should just be an option
    cp buildly-core/buildly/settings/base.py buildly-core/buildly/settings/base-buildly.py

    if [ "$users" != "${users#[Nn]}" ] ;then
        sed 's/users//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi

    echo -n "Would you like to use Templates to manage reuseable workflows with Buildly? Yes [Y/y] or No [N/n] "
    read templates

    if [ "$templates" != "${templates#[Nn]}" ] ;then
        sed 's/workflow//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi
    echo -n "Would you like to enable the data mesh functions? Yes [Y/y] or No [N/n] "
    read mesh

    if [ "$mesh" != "${mesh#[Nn]}" ] ;then
        sed 's/datamesh//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi
  fi
}

# method to list services availables on Buildly Marketplace
listMktpServices()
{
  services=$(curl -s $github_api_url/orgs/$buildly_mkt_path/repos?per_page=1000 | grep full_name | awk '{print $2}'| sed 's/.*\/\(.*\)",/\1/')
  echo "$services"
}

# method to clone services from Buildly Marketplace
cloneMktpService()
{
  git clone "$github_url/$buildly_mkt_path/$1.git" "YourApplication/services/$1";
}

# method to create django services from scratch using django wizard
createDjangoService()
{
  (
  cd "django-service-wizard" || exit
  # create a new service use django-service-wizard for now
  docker-compose run --rm django_service_wizard -u $(id -u):$(id -g) -v "$(pwd)":/code || echo "Docker not configured, installed or running"
  )
}

# method to create new applications
createApplication()
{
  # create application and services folder
  if [ -d YourApplication/ ]; then
    echo -n "A folder called YourApplication already exists. Do you want to delete it and recreate? Yes [Y/y] or No [N/n] "
    read folder_answer
    if [ "$folder_answer" != "${folder_answer#[Yy]}" ] ;then
      sudo rm -r YourApplication
    else
      exit
    fi
  fi
  mkdir "YourApplication"
  mkdir "YourApplication/services"

  # set up application and services
  (
  cd YourApplication || exit
  setupBuildlyCore
  )

  # clone service repositories from GitHub
  echo -n "Would you like to import a service from the marketplace? Yes [Y/y] or No [N/n] "
  read mktp_service_answer1
  if [ "$mktp_service_answer1" != "${mktp_service_answer1#[Yy]}" ] ;then
    # list marketplace services and clone selected ones
    for repo in $(listMktpServices);do
      echo -n "Would you like to clone and use "$repo" from the marketplace? Yes [Y/y] or No [N/n] "
      read mktp_service_answer2

      if [ "$mktp_service_answer2" != "${mktp_service_answer2#[Yy]}" ] ;then
        cloneMktpService "$repo"
      fi
    done;
  fi

  # loop for creation of multiple services from scratch
  while :
  do
    echo -n "Would you like to create a service from scratch? Yes [Y/y] or No [N/n] "
    read scratch_service_answer

    if [ "$scratch_service_answer" != "${scratch_service_answer#[Yy]}" ] ;then
      createDjangoService
    else
      break
    fi
  done

  deploy2Minikube
  deploy2Provider
}

deploy2Minikube()
{
  echo -n "Now... would you like to connect your services to docker and a minikube instance? Yes [Y/y] or No [N/n] "
  read mini_kube

  if [ "$mini_kube" != "${mini_kube#[Yy]}" ] ;then
    # start mini kube if not already
    setupMinikube
    # clone the helm chart to deploy core to minikube
    if [ ! -d helm-charts/ ]; then
      git clone $github_url/$buildly_helm_repo_path
    fi
    # create buildly namespace
    kubectl create namespace buildly || echo "Name space buildly already exists"
    echo "Configure your buildly core to connect to a Database..."
    echo -n "Enter host name or IP: "
    read dbhost
    echo -n "Enter Database Port: "
    read dbport
    echo -n "Enter Database Username: "
    read dbuser
    echo -n "Enter Database Password: "
    read dbpass
    # start helm
    (
    setupHelm
    cd "helm-charts/buildly-core-chart" || exit
    # install to minikube via helm
    helm install . --name buildly-core --namespace buildly \
    --set configmap.data.DATABASE_HOST=$dbhost \
    --set configmap.data.DATABASE_PORT=\"$dbport\" \
    --set secret.data.DATABASE_USER=$dbuser \
    --set secret.data.DATABASE_PASSWORD=$dbpass
    )

    # build local images for each service
    (
    cd "YourApplication/services" || exit
    eval $(minikube docker-env)
    ls | while IFS= read -r service
    do
      (
      cd $service || exit
      cleanedService=$(echo "$service" | tr "[:punct:]" -)
      # build a local image
      docker build . -t "${cleanedService}:latest"
      # deploy to kubectl
      kubectl run $cleanedService --image=$cleanedService --image-pull-policy=Never -n buildly
      )
    done
    )

    echo "Done!  Check your configuration and make sure pods running on your minikube instance and start coding!"
    echo "Trouble? try the README files in the core or go to https://buildly-core.readthedocs.io/en/latest/"
  fi
}

deploy2Provider()
{
  echo -n "Would you like to deploy to AWS, GCP or Digital Ocean Yes [Y/y] or No [N/n] "
  read provider

  if [ "$provider" != "${provider#[Yy]}" ] ;then
    echo -n "Would you like to deploy to AWS? [Y/y] or No [N/n]"
    read provider_name_aws
    if [ "$provider_name_aws" != "${provider_name_aws#[Yy]}" ] ;then
      echo "AWS ok....good luck with that!"
    fi

    echo -n "Would you like to deploy to GCP (Google Cloud)? [Y/y] or No [N/n]"
    read provider_name_gcp
    if [ "$provider_name_gcp" != "${provider_name_gcp#[Yy]}" ] ;then
      echo "GCP...ok good luck with that!"
    fi

    echo -n "Would you like to deploy to Digital Ocean? [Y/y] or No [N/n]"
    read provider_name_do
    if [ "$provider_name_do" != "${provider_name_do#[Yy]}" ] ;then
      echo "Digital OCean hosted Kubernetes... ok let's go!"
      # clone the helm chart to deploy core to minikube
      git clone $github_url/$buildly_helm_repo_path

      echo "Let's make sure you have your DO configs ready..."
      # auth to DO
      doctl auth init
      echo "Get or set your local access token from Digital Oceans API manager https://cloud.digitalocean.com/account/api/tokens
      Download the kubeconfig file for the cluster and move to your ~/.kube directory"
      echo -n "Enter the name of your DO kubectl config file..."
      # get file and path
      read config_file

      kubectl config current-context --kubeconfig ~/.kube/$config_file
      kubectl config use-context $config_file

      echo "Now we will set your context to DO and init helm..."
      kubectl config use-context $config_file
      helm init

      echo "Now we will create a buildly Namespace and deploy with helm"
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
      do
        cd $service
        # build a local image
        docker-compose build $service
        # deploy to kubectl
        kubectl run $service --image=$service --image-pull-policy=Never -n buildly
        cd ../
      done

      # check on pods
      kubectl get pods -n buildly

    fi
  fi
}

##############################################################################
#
# Main
#
##############################################################################

# Check dependencies
type curl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'cURL' installed."; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Git' installed."; exit 1; }

for key in "$@"; do
# Execute workflows based on the operation
case $key in
    -ca|--create-application)
    createApplication
    exit 0
    ;;
    --list-marketplace)
    listMktpServices
    exit 0
    ;;
    -cm|--clone-markeplace)
    cloneMktpService
    exit 0
    ;;
    -cs|--create-service)
    createDjangoService
    exit 0
    ;;
    -d2m|--deploy-minikube)
    deploy2Minikube
    exit 0
    ;;
    -d2p|--deploy-provider)
    deploy2Provider
    exit 0
    ;;
    *)
    exit 1
esac
done