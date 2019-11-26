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
#if ! ( (("${BASH_VERSION:0:1}" == "4")) && (("${BASH_VERSION:2:1}" >= "3")) ) \
#  && ! (("${BASH_VERSION:0:1}" >= "5")); then
#    echo ""
#    echo "Sorry - your Bash version is ${BASH_VERSION}"
#    echo ""
#    echo "You need at least Bash 4.3 to run this script."
#    echo ""
#    exit 1
#fi

###############################################################################
#
# Global variables
#
###############################################################################

##
# The filename of this script for help messages
script_name=$(basename "$0")

##
# Declare colors with autodection if output is terminal
if [ -t 1 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    MAGENTA="$(tput setaf 5)"
    CYAN="$(tput setaf 6)"
    WHITE="$(tput setaf 7)"
    BOLD="$(tput bold)"
    OFF="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    BOLD=""
    OFF=""
fi

declare -a result_color_table=( "$WHITE" "$WHITE" "$GREEN" "$YELLOW" "$WHITE" "$MAGENTA" "$WHITE" )

##
# The user credentials for basic authentication
action=""
service_name=""
framework_name=""
provider_name=""

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
  # Check specific dependencies
  type kubectl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'K8S CLI' installed.
  Check the documentation of how to install it: https://kubernetes.io/docs/tasks/tools/install-kubectl/"; exit 1; }
  type minikube >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Minikube' installed.
  Check the documentation of how to install it: https://minikube.sigs.k8s.io/docs/start/"; exit 1; }

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
  # Check specific dependencies
  type helm >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Helm' installed.
  Check the documentation of how to install it: https://helm.sh/docs/"; exit 1; }

  status=$(helm version)
  if [[ ! ($status == *"Client: &version.Version"*  &&  $status == *"Server: &version.Version"* || $status == *"Version:\"v3.0.0\""*) ]]; then
    helm init
  else
    echo "Helm is already configured"
  fi
}

# method to clone buidly into the application folder
setupBuildlyCore()
{
  echo -n "${BOLD}${WHITE}Buildy Core configuration tool, what type of app are building? [F/f] Fast and lightweight or [S/s] Scaleable and feature rich? ${OFF}"
  read answer

  if [ "$answer" != "${answer#[Ss]}" ] ;then
    echo "Cloning Buildly Core"
    git clone "$github_url/$buildly_core_repo_path" "buildly-core"

    echo -n "${BOLD}${WHITE}Would you like to Manage Users with Buildly? Yes [Y/y] or No [N/n] ${OFF}"
    read users

    # cp config file to make changes
    # this should have 4 config files (1 with all modules base.py, 1 with Templates and Mesh, and 1 with just Template, and 1 with just Mesh)
    # then the Mesh should just be an option
    cp buildly-core/buildly/settings/base.py buildly-core/buildly/settings/base-buildly.py

    if [ "$users" != "${users#[Nn]}" ] ;then
        sed 's/users//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi

    echo -n "${BOLD}${WHITE}Would you like to use Templates to manage reuseable workflows with Buildly? Yes [Y/y] or No [N/n] ${OFF}"
    read templates

    if [ "$templates" != "${templates#[Nn]}" ] ;then
        sed 's/workflow//g' buildly-core/buildly/settings/base-buildly.py > buildly-core/buildly/settings/base-buildly.py
    fi

    echo -n "${BOLD}${WHITE}Would you like to enable the data mesh functions? Yes [Y/y] or No [N/n] ${OFF}"
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
  # Check specific dependencies
  type docker-compose >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker Compose' installed.
  Check the documentation of how to install it: https://docs.docker.com/compose/install/"; exit 1; }

  if [ ! -d django-service-wizard ]; then
    MSG="The Django service wizard \"django-service-wizard\" wasn't found"
    print_message "error" "$MSG"
  fi

  (
  cd "django-service-wizard" || return
  # create a new service use django-service-wizard for now
  docker-compose run --rm django_service_wizard -u "$(id -u):$(id -g)" -v "$(pwd)":/code || echo "Docker not configured, installed or running"
  )
}

# method to create new applications
createApplication()
{
  # create application and services folder
  if [ -d YourApplication/ ]; then
    echo -n "${BOLD}${WHITE}A folder called YourApplication already exists. Do you want to delete it and recreate? Yes [Y/y] or No [N/n] ${OFF}"
    read folder_answer
    if [ "$folder_answer" != "${folder_answer#[Yy]}" ] ;then
      sudo rm -r YourApplication
    else
      MSG="You can either rename the folder \"YourApplication\" to another name or add more services to
      the current application using the commands --create-service, --clone-markeplace"
      print_message "info" "$MSG"
      exit 0
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
  echo -n "${BOLD}${WHITE}Would you like to import a service from the marketplace? Yes [Y/y] or No [N/n] ${OFF}"
  read mktp_service_answer1
  if [ "$mktp_service_answer1" != "${mktp_service_answer1#[Yy]}" ] ;then
    # list marketplace services and clone selected ones
    for repo in $(listMktpServices);do
      echo -n "${BOLD}${WHITE}Would you like to clone and use ${OFF}${BOLD}${CYAN}"$repo"${OFF} ${BOLD}${WHITE}from the marketplace? Yes [Y/y] or No [N/n] ${OFF}"
      read mktp_service_answer2

      if [ "$mktp_service_answer2" != "${mktp_service_answer2#[Yy]}" ] ;then
        cloneMktpService "$repo"
      fi
    done;
  fi

  # loop for creation of multiple services from scratch
  while :
  do
    echo -n "${BOLD}${WHITE}Would you like to create a service from scratch? Yes [Y/y] or No [N/n] ${OFF}"
    read scratch_service_answer

    if [ "$scratch_service_answer" != "${scratch_service_answer#[Yy]}" ] ;then
      createDjangoService
    else
      break
    fi
  done

  echo -n "${BOLD}${WHITE}Would you like to connect Buildly Core and your services to docker or a minikube instance? Docker [docker] or Minikube [minikube] ${OFF}"
  read deployment_option

  if [ -n "$deployment_option" ] ;then
    deploy2Provider "$deployment_option"

    echo "Done!  Check your configuration and make sure Buildly Core and the services are running and start coding!"
    echo "Trouble? try the README files in the core or go to https://buildly-core.readthedocs.io/en/latest/"
  fi

  # deploy application to a cloud provider
  echo -n "${BOLD}${WHITE}Would you like to deploy to AWS? [Y/y] or No [N/n] ${OFF}"
  read provider_name_aws
  if [ "$provider_name_aws" != "${provider_name_aws#[Yy]}" ] ;then
    deploy2Provider "AWS"
  fi

  echo -n "${BOLD}${WHITE}Would you like to deploy to GCP (Google Cloud)? [Y/y] or No [N/n] ${OFF}"
  read provider_name_gcp
  if [ "$provider_name_gcp" != "${provider_name_gcp#[Yy]}" ] ;then
    deploy2Provider "GCP"
  fi

  echo -n "${BOLD}${WHITE}Would you like to deploy to Digital Ocean? [Y/y] or No [N/n] ${OFF}"
  read provider_name_do
  if [ "$provider_name_do" != "${provider_name_do#[Yy]}" ] ;then
    deploy2Provider "DO"
  fi
}

setupServices()
{
  # Check specific dependencies
  type docker >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker' installed.
  Check the documentation of how to install it: https://docs.docker.com/v17.12/install/"; exit 1; }

  eval $(minikube docker-env)
  if [[ -n "$1" && ("$1" == "buildly") ]] ;then
    # check if buildly core folder exists inside of application's folder
    if [ ! -d YourApplication/buildly-core ]; then
      MSG="The application folder \"YourApplication/buildly-core\" doesn't exist"
      print_message "error" "$MSG"
    fi

    # build buildly core
    (
    cd YourApplication/buildly-core || return
    docker build . -t "buildly-core:latest" || exit
    )
  else
    # check if service folder exists inside of application's folder
    if [ ! -d YourApplication/services ]; then
      MSG="The application folder \"YourApplication/services\" doesn't exist"
      print_message "error" "$MSG"
    fi

    (
    cd "YourApplication/services" || return
    # loop through all services and build their images
    ls | while IFS= read -r service
    do
      (
      cd $service || exit
      cleanedService=$(echo "$service" | tr "[:punct:]" -)
      # build a local image
      docker build . -t "${cleanedService}:latest" || exit
      )
    done
    )
  fi
}

##############################################################################
#
# Deploy functions
#
##############################################################################

deployServices()
{
  # Check specific dependencies
  type kubectl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'K8S CLI' installed.
  Check the documentation of how to install it: https://kubernetes.io/docs/tasks/tools/install-kubectl/"; exit 1; }

  # check if service folder exists inside of application's folder
  if [ ! -d YourApplication/services ]; then
    MSG="The application folder \"YourApplication/services\" doesn't exist"
    print_message "error" "$MSG"
  fi

  (
  cd "YourApplication/services" || return
  # loop through all services and build their images
  ls | while IFS= read -r service
  do
    # deploy to kubectl
    cleanedService=$(echo "$service" | tr "[:punct:]" -)
    kubectl run $cleanedService --image=$cleanedService --image-pull-policy=Never -n buildly
  done
  )
}

deployBuildlyCore()
{
  if [ ! -d helm-charts/ ]; then
    git clone $github_url/$buildly_helm_repo_path
  fi
  # create buildly namespace
  kubectl create namespace buildly || print_message "warn" "Namespace \"buildly\" already exists"
  echo "${BOLD}${WHITE}Configure your Buildly Core to connect to a Database...${OFF}"
  echo -n "Enter host name or IP: "
  read dbhost
  echo -n "Enter Database Port: "
  read dbport
  echo -n "Enter Database Username: "
  read dbuser
  echo -n "Enter Database Password: "
  read dbpass

  (
  setupHelm
  cd "helm-charts/buildly-core-chart" || return
  # install to minikube via helm
  if [[ -n "$1" && ("$1" == "GCP" || "$1" == "gcp") ]] ;then
    # TODO: Ask user if he/she is using CloudSQL for buildly core
    echo -n "${BOLD}${WHITE}What's the name of the CloudSQL instance? ${OFF}"
    read cloudsql_name

    echo -n "${BOLD}${WHITE}What's the port to access the CloudSQL database? ${OFF}"
    read cloudsql_port

    echo -n "${BOLD}${WHITE}What's the name of the project that the CloudSQL lives? ${OFF}"
    read cloudsql_project

    echo -n "${BOLD}${WHITE}What's the name of the region where the instance is deployed? ${OFF}"
    read cloudsql_region

    echo -n "${BOLD}${WHITE}What's the name of the secret that holds the CloudSQL credentials? ${OFF}"
    read cloudsql_secret

    helm install . --name buildly-core --namespace buildly \
    --set configmap.data.DATABASE_HOST="$dbhost" \
    --set configmap.data.DATABASE_PORT=\""$dbport"\" \
    --set secret.data.DATABASE_USER="$dbuser" \
    --set secret.data.DATABASE_PASSWORD="$dbpass" \
    --set gcp.enable="True" \
    --set gcp.cloudsql.name="$cloudsql_name" \
    --set gcp.cloudsql.port="$cloudsql_port" \
    --set gcp.cloudsql.project_id="$cloudsql_project" \
    --set gcp.cloudsql.region="$cloudsql_region" \
    --set gcp.cloudsql.secretName="$cloudsql_secret"
  elif [[ -n "$1" && ("$1" == "minikube" || "$1" == "Minikube") ]] ;then
    helm install buildly-core . --namespace buildly \
    --set configmap.data.DATABASE_HOST="$dbhost" \
    --set configmap.data.DATABASE_PORT=\""$dbport"\" \
    --set secret.data.DATABASE_USER="$dbuser" \
    --set secret.data.DATABASE_PASSWORD="$dbpass" \
    --set buildly.image.repository=buildly-core \
    --set buildly.image.version=latest \
    --set buildly.image.pullPolicy=IfNotPresent
  else
    helm install . --name buildly-core --namespace buildly \
    --set configmap.data.DATABASE_HOST="$dbhost" \
    --set configmap.data.DATABASE_PORT=\""$dbport"\" \
    --set secret.data.DATABASE_USER="$dbuser" \
    --set secret.data.DATABASE_PASSWORD="$dbpass"
  fi
  )
}

deploy2Minikube()
{
  # start mini kube if not already
  setupMinikube

  # deploy buildly using helm charts
  deployBuildlyCore

  # build local images for each service
  setupServices
}

deploy2Docker()
{
  # Check specific dependencies
  type docker >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker' installed.
  Check the documentation of how to install it: https://docs.docker.com/v17.12/install/"; exit 1; }
  type docker-compose >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker Compose' installed.
  Check the documentation of how to install it: https://docs.docker.com/compose/install/"; exit 1; }

  # build and start buildly core
  (
  cd YourApplication/buildly-core || return
  docker-compose build
  docker-compose up -d
  )

  # build service images
  (
  cd "YourApplication/services" || return
  ls | while IFS= read -r service
  do
    (
    cd $service || exit
    docker-compose build
    docker-compose up -d
    )
  done
  )

  # create a network for buildly if it doesn't exist
  docker_networks=$(docker network ls | tail -n +2 | awk '{print $2}')
  if [[ $docker_networks != *"buildly_test"* ]]; then
    docker network create buildly_test
  fi

  # add buildly core and all services to the created network
  container_ids=$(docker ps -a | tail -n +2 | awk '{print $1}')
  while read -r container_id; do
    docker network connect buildly_test "$container_id"
  done <<< "$container_ids"

}

deploy2AWS()
{
  echo "AWS ok....good luck with that!"
}

deploy2GCP()
{
  # Check specific dependencies
  type gcloud >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Google Cloud CLI' installed.
  Check the documentation of how to install it: https://cloud.google.com/sdk/install"; exit 1; }
  type kubectl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'K8S CLI' installed.
  Check the documentation of how to install it: https://kubernetes.io/docs/tasks/tools/install-kubectl/"; exit 1; }

  echo "Google Cloud hosted Kubernetes... ok let's go!"
  echo "Let's make sure you have your Google Cloud configs ready..."

  # init and auth to GCP
  project=$(gcloud config get-value project)
  if [ -z "$project" ]; then
    gcloud init
  else
    # check if the same project will be used
    echo -n "${BOLD}${WHITE}The project ${CYAN}\"$project\"${OFF} ${BOLD}${WHITE}will be used. Do you want to change it? [Y/y] or No [N/n] ${OFF}"
    read change_project

    # configure new project
    if [ "$change_project" != "${change_project#[Yy]}" ] ;then
      echo -n "${BOLD}${WHITE}Type the name of the project you want to use: ${OFF}"
      read project
    fi
  fi

  # define which kubernetes cluster will be used
  echo -n "${BOLD}${WHITE}Enter the name of your GCP Kubernetes cluster: ${OFF}"
  read k8s_cluster_name

  echo -n "${BOLD}${WHITE}Is it a zonal or regional cluster? [zone] or [region] ${OFF}"
  read cluster_type

  # validate zonal/regional cluster response
  if [ "$cluster_type" != "zone" ] && [ "$cluster_type" != "region" ]; then
    MSG="You need to specify if your cluster is zonal or regional. Options: [zone] or [region]"
    print_message "error" "$MSG"
  fi

  echo -n "${BOLD}${WHITE}Type the name of the zone(e.g, us-east1-b) or region(e.g, us-east1): ${OFF}"
  read zone_region

  # generate kubeconfig file and switch context of kubectl
  gcloud container clusters get-credentials "$k8s_cluster_name" "--$cluster_type" "$zone_region" --project "$project"
  contexts=$(kubectl config get-contexts)
  if [[ ! ( $contexts == *"$k8s_cluster_name"*) ]]; then
    MSG="Your cluster isn't available via \"kubectl\". Make sure your DO CLI and kubeconfig are well configured."
    print_message "error" "$MSG"
  fi

  # enable access to database instance from cloudsql
  echo -n "${BOLD}${WHITE}Is Buildly Core DB going to be a CloudSQL database? [Y/y] or No [N/n] ${OFF}"
  read use_cloudsql

  # deploy buildly using helm charts
  if [ "$use_cloudsql" != "${use_cloudsql#[Yy]}" ] ;then
    deployBuildlyCore "GCP"
  else
    deployBuildlyCore
  fi

  echo "Done! Your Buildly Core application is up and running in \"$k8s_cluster_name\"."
  MSG="Services need to have a container image available on internet via a registry to be deployed to Kubernetes.
      If you decide to have your own registry, check the following K8S tutorial of how to pull an image from a
      private registry: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/"
  print_message "info" "$MSG"
}

deploy2DO()
{
  # Check specific dependencies
  type doctl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'DO CLI' installed.
  Check the documentation of how to install it: https://github.com/digitalocean/doctl"; exit 1; }
  type kubectl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'K8S CLI' installed.
  Check the documentation of how to install it: https://kubernetes.io/docs/tasks/tools/install-kubectl/"; exit 1; }

  echo "Digital Ocean hosted Kubernetes... ok let's go!"
  echo "Let's make sure you have your DO configs ready..."
  # auth to DO
  doctl auth init
  echo -n "${BOLD}${WHITE}Enter the name of your DO Kubernetes cluster: ${OFF}"
  read k8s_cluster_name

  # get kubeconfig file and switch context of kubectl
  doctl kubernetes cluster kubeconfig save $k8s_cluster_name
  contexts=$(kubectl config get-contexts)
  if [[ ! ( $contexts == *"$k8s_cluster_name"*) ]]; then
    MSG="Your cluster isn't available via \"kubectl\". Make sure your DO CLI and kubeconfig are well configured."
    print_message "error" "$MSG"
  fi

  # deploy buildly using helm charts
  deployBuildlyCore

  echo "Done! Your Buildly Core application is up and running in \"$k8s_cluster_name\"."
  MSG="Services need to have a container image available on internet via a registry to be deployed to Kubernetes.
      If you decide to have your own registry, check the following K8S tutorial of how to pull an image from a
      private registry: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/"
  print_message "info" "$MSG"
}

deploy2Provider()
{
  case $1 in
    aws|AWS)
    deploy2AWS
    ;;
    do|DO)
    deploy2DO
    ;;
    gcp|GCP)
    deploy2GCP
    ;;
    minikube|Minikube)
    deploy2Minikube
    ;;
    docker|Docker)
    deploy2Docker
    ;;
    *)
    MSG="The specified provider \"$1\" wasn't implemented yet"
    print_message "error" "$MSG"
  esac
}

##############################################################################
#
# Print Messages
#
##############################################################################
print_message() {
  if [ "$1" == "info" ] ;then
    echo -e "${BLUE}INFO: $2${OFF}"
  elif [ "$1" == "warn" ]; then
    echo -e "${YELLOW}WARN: $2${OFF}"
  else
    echo -e "${RED}ERROR: $2${OFF}"
    exit 1
  fi
}

##############################################################################
#
# Print CLI version
#
##############################################################################
print_version() {
    echo ""
    echo -e "${BOLD}Buildly CLI 0.0.1${OFF}"
    echo ""
}

###############################################################################
#
# Print main help message
#
###############################################################################
print_help() {
cat <<EOF

${BOLD}${WHITE}Buildly CLI 0.0.1${OFF}

${BOLD}${WHITE}Usage${OFF}

  ${GREEN}${script_name}${OFF} [-h|--help] [-V|--version] [--about] [--create-application]
           [--list-marketplace] [--clone-markeplace ${RED}<service-name>${OFF}]
           [--create-service ${CYAN}<framework-name>${OFF}] [--deploy-minikube]
           [--deploy-provider ${MAGENTA}<provider-name>${OFF}] [-nc|--no-colors]

  - ${RED}<service-name>${OFF} - any service name from Buildly Marketplace can be give, e.g,
                    ${YELLOW}kpi_service${OFF}
  - ${CYAN}<framework-name>${OFF} - one of supported frameworks:
                   (Django, Express)
  - ${MAGENTA}<provider-name>${OFF} - either full provider name or one of supported abbreviations:
                   (AWS, DO<DigitalOcean>, GCP)

EOF
echo " " | column -t -s ';'
    echo ""
    echo -e "${BOLD}${WHITE}Options${OFF}"
    echo -e "  -h,--help\\t\\t\\t\\t\\tPrint this help"
    echo -e "  -V,--version\\t\\t\\t\\t\\tPrint CLI version"
    echo -e "  --about\\t\\t\\t\\t\\tPrint the information about the tool"

    echo -e "  -ca,--create-application\\t\\t\\tCreate, configure, and deploy a Buildly Core application with service"
    echo -e "  --list-marketplace\\t\\t\\t\\tList availables service in Buildly Marketplace"
    echo -e "  -cm,--clone-markeplace ${YELLOW}<service-name>${OFF}\\t\\tClone given service from Buildly Marketplace"
    echo -e "  -cs,--create-service ${YELLOW}<framework-name>${OFF}\\t\\tCreate a service from scratch based on given framework name"
    echo -e "  -d2m,--deploy-minikube\\t\\t\\tDeploy current Buildly Core to a Minikube instance"
    echo -e "  -d2p,--deploy-provider ${YELLOW}<provider-name>${OFF}\\tDeploy current Buildly Core to a given provider"
    echo -e "  -nc,--no-colors\\t\\t\\t\\tEnforce print without colors, otherwise autodected"
    echo ""
}

##############################################################################
#
# Print CLI description
#
##############################################################################
print_about() {
    echo ""
    echo -e "${BOLD}${WHITE}Buildly CLI 0.0.1${OFF}"
    echo ""
    echo -e "License: GPL-3.0"
    echo -e "Contact: team@buildly.io"
    echo -e "Website: https://buildly.io"
    echo ""
read -r -d '' appdescription <<EOF

Command line tool for creating and configuring your buildly application.
EOF
echo "$appdescription" | paste -sd' ' | fold -sw 80
}

##############################################################################
#
# Main
#
##############################################################################

# Check dependencies
type curl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'cURL' installed.
Check the documentation of how to install it: https://curl.haxx.se/download.html"; exit 1; }
type git >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Git' installed.
Check the documentation of how to install it: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git"; exit 1; }

#
# Process command line
#
# Pass all arguments before 'operation' to cURL except the ones we override
#
get_service=false
get_framework=false
get_provider=false

for key in "$@"; do
# get the value of -cm,--clone-markeplace argument
if [[ "$get_service" = true ]]; then
    service_name="$key"
    get_service=false
    continue
fi
# Take the value of -cs,--create-service argument
if [[ "$get_framework" = true ]]; then
    framework_name="$key"
    get_framework=false
    continue
fi
# Take the value of -d2p,--deploy-provider argument
if [[ "$get_provider" = true ]]; then
    provider_name="$key"
    get_provider=false
    continue
fi

# Execute workflows based on the action
case $key in
  -h|--help)
  print_help
  exit 0
  ;;
  -V|--version)
  print_version
  exit 0
  ;;
  --about)
  print_about
  exit 0
  ;;
  -ca|--create-application)
  action="createApplication"
  ;;
  --list-marketplace)
  action="listMktpServices"
  ;;
  -cm|--clone-markeplace)
  get_service=true
  action="cloneMktpService"
  ;;
  -cs|--create-service)
  get_framework=true
  action="createDjangoService"
  ;;
  -d2m|--deploy-minikube)
  action="deploy2Minikube"
  ;;
  -d2p|--deploy-provider)
  get_provider=true
  action="deploy2Provider"
  ;;
  -nc|--no-colors)
      RED=""
      GREEN=""
      YELLOW=""
      BLUE=""
      MAGENTA=""
      CYAN=""
      WHITE=""
      BOLD=""
      OFF=""
      result_color_table=( "" "" "" "" "" "" "" )
  ;;
esac
done

if [[ -z "$action" ]]; then
  MSG="No action specified!"
  print_message "error" "$MSG"
fi

# call function based on the action
case $action in
  createApplication)
  createApplication
  ;;
  listMktpServices)
  listMktpServices
  ;;
  cloneMktpService)
  if [[ -z "$service_name" ]]; then
    MSG="No service name specified!"
    print_message "error" "$MSG"
  fi
  cloneMktpService "$service_name"
  ;;
  createDjangoService)
  if [[ -z "$framework_name" ]]; then
    MSG="No framework name specified!"
    print_message "error" "$MSG"
  fi
  createDjangoService "$framework_name"
  ;;
  deploy2Minikube)
  deploy2Provider "Minikube"
  ;;
  deploy2Provider)
  if [[ -z "$provider_name" ]]; then
    MSG="No provider name specified!"
    print_message "error" "$MSG"
  fi
  deploy2Provider "$provider_name"
  ;;
  *)
  MSG="Unknown option: $key"
  print_message "error" "$MSG"
esac