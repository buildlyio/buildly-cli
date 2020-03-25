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
version="0.8.0"

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
#buildly_angular_template_repo_path="buildlyio/buildly-angular-template.git"
buildly_react_template_repo_path="buildlyio/buildly-react-template.git"
buildly_helm_repo_path="buildlyio/helm-charts.git"
buildly_mkt_path="Buildly-Marketplace"

###############################################################################
#
# Create Service Functions
#
###############################################################################

# method to create django services from scratch using django wizard
createDjangoService()
{
  # Check specific dependencies
  type docker-compose >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker Compose' installed.
  Check the documentation of how to install it: https://docs.docker.com/compose/install/"; exit 1; }

  # check if folder exists
  if [ ! -d django-service-wizard ]; then
    MSG="The Django service wizard \"django-service-wizard\" wasn't found"
    print_message "error" "$MSG"
  fi

  # check if sub-module was pulled
  if [ ! "$(ls -A "django-service-wizard")" ]; then
    MSG="The Django service wizard \"django-service-wizard\" wasn't found.\nPlease pull sub-modules using the following git command: 'git pull --recurse-submodules'"
    print_message "error" "$MSG"
  fi

  (
  cd "django-service-wizard" || return
  # create a new service use django-service-wizard for now
  docker-compose run --rm django_service_wizard -u "$(id -u):$(id -g)" -v "$(pwd)":/code || echo "Docker not configured, installed or running"
  )
}

# method to create django services from scratch using django wizard
createExpressService()
{
  # Check specific dependencies
  type docker-compose >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker Compose' installed.
  Check the documentation of how to install it: https://docs.docker.com/compose/install/"; exit 1; }

  # check if folder exists
  if [ ! -d express-service-wizard ]; then
    MSG="The Express service wizard \"express-service-wizard\" wasn't found"
    print_message "error" "$MSG"
  fi

  # check if sub-module was pulled
  if [ ! "$(ls -A "express-service-wizard")" ]; then
    MSG="The Django service wizard \"django-service-wizard\" wasn't found.\nPlease pull sub-modules using the following git command: 'git pull --recurse-submodules'"
    print_message "error" "$MSG"
  fi

  (
  cd "express-service-wizard" || return
  # create a new service use express-service-wizard for now
  docker-compose run --rm express_service_wizard || echo "Docker not configured, installed or running"
  )
}

###############################################################################
#
# SetUp Functions
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

    echo -n "${BOLD}${WHITE}Would you like to use Templates to manage reusable workflows with Buildly? Yes [Y/y] or No [N/n] ${OFF}"
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

# method to clone buidly template into the application folder
setupBuildlyTemplate()
{
  echo -n "${BOLD}${WHITE}Would you like to use Buildly React Template? Yes [Y/y] or No [N/n] ${OFF}"
  read answer

  if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Cloning Buildly Template"
    git clone "$github_url/$buildly_react_template_repo_path" "buildly-react-template"
  fi
}

setupServices()
{
  # Check specific dependencies
  type docker >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker' installed.
  Check the documentation of how to install it: https://docs.docker.com/v17.12/install/"; exit 1; }

  eval $(minikube docker-env)
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
}

###############################################################################
#
# Command Option Functions
#
###############################################################################

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
  setupBuildlyTemplate
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
      echo -n "${BOLD}${WHITE}Which framework would you like to use? Django or Express ${OFF}"
      read framework_name
      createService "$framework_name"
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

# method to create service with specified framework
createService()
{
  case $1 in
    django|Django)
    createDjangoService
    ;;
    express|Express)
    createExpressService
    ;;
    *)
    MSG="The specified framework \"$1\" isn't implemented yet"
    print_message "error" "$MSG"
  esac
}

# method to create deploy app to specified provider
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
    MSG="The specified provider \"$1\" isn't implemented yet"
    print_message "error" "$MSG"
  esac
}

##############################################################################
#
# Connect to Buildly Core Functions
#
##############################################################################

connectService2Buildly()
{
  # Check specific dependencies
  type kubectl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'K8S CLI' installed.
  Check the documentation of how to install it: https://kubernetes.io/docs/tasks/tools/install-kubectl/"; exit 1; }

  # define attributes of logic module
  service_uuid=$(uuidgen)
  service_name=$(echo "$1" | tr -d "[:punct:]")
  endpoint="http://$1.buildly.svc.cluster.local:$2"
  endpoint_name=$(cut -d'-' -f1 <<<"$1")

  # create db insert query and perform it
  insert_query="INSERT INTO core_logicmodule (module_uuid, name, endpoint, endpoint_name) VALUES ('$service_uuid', '$service_name', '$endpoint', '$endpoint_name');"

  kubectl run db-buildly-postgresql-client --rm --tty -i --restart='Never' --namespace buildly \
  --image docker.io/bitnami/postgresql:11.7.0-debian-10-r0 --env="PGPASSWORD=root" --command -- \
  psql --host db-buildly-postgresql -U postgres -d buildly -p 5432 -c "$insert_query"
}

##############################################################################
#
# Deploy Functions
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
  # loop through all services and deploy them
  services=(*)
  for service in "${services[@]}"
  do
    # do not loop for empty folder
    if [ "$service" == "*" ]; then
        break
    fi
    # clean the service name
    cleanedService=$(echo "$service" | tr "[:punct:]" -)

    echo -n "${BOLD}${WHITE}Does the service ${OFF}${BOLD}${CYAN}\"$service\"${OFF}${BOLD}${WHITE} need a PostgreSQL DB? Yes [Y/y] or No [N/n] ${OFF}"
    read use_database
    if [ "$use_database" != "${use_database#[Yy]}" ] ;then
      if [[ -n "$1" && ("$1" == "minikube" || "$1" == "Minikube") ]] ;then
        # create a database for the service
        cleanDBName=$(echo "$service" | tr "[:punct:]" _)

        kubectl run db-buildly-postgresql-client --rm --tty -i --restart='Never' --namespace buildly \
        --image docker.io/bitnami/postgresql:11.7.0-debian-10-r0 --env="PGPASSWORD=root" --command -- \
        psql --host db-buildly-postgresql -U postgres -d buildly -p 5432 -c "CREATE DATABASE $cleanDBName;"

        dbname=$cleanDBName
        dbhost=db-buildly-postgresql.buildly.svc.cluster.local
        dbport=5432
        dbuser=postgres
        dbpass=root
      else
        echo "${BOLD}${WHITE}Configure your Service to connect to a Database...${OFF}"
        echo -n "Enter host name or IP: "
        read dbhost
        echo -n "Enter Database Port: "
        read dbport
        echo -n "Enter Database Name: "
        read dbname
        echo -n "Enter Database Username: "
        read dbuser
        echo -n "Enter Database Password: "
        read dbpass
      fi

      echo -n "${BOLD}${WHITE}Is this service using the default database environment variables (DATABASE_HOST, DATABASE_PORT, DATABASE_NAME, DATABASE_USER, DATABASE_PASSWORD)? Yes [Y/y] or No [N/n] ${OFF}"
      read default_env_vars
      if [ "$default_env_vars" != "${default_env_vars#[Yy]}" ] ;then
        dbhost_env_var=DATABASE_HOST
        dbport_env_var=DATABASE_PORT
        dbname_env_var=DATABASE_NAME
        dbuser_env_var=DATABASE_USER
        dbpass_env_var=DATABASE_PASSWORD
      else
        # ask for the database env var names
        echo -n "Enter the name of the DB Host environment variable: "
        read dbhost_env_var
        echo -n "Enter the name of the DB Port environment variable: "
        read dbport_env_var
        echo -n "Enter the name of the DB Name environment variable: "
        read dbname_env_var
        echo -n "Enter the name of the DB User environment variable: "
        read dbuser_env_var
        echo -n "Enter the name of the DB Password environment variable: "
        read dbpass_env_var
      fi
    fi

    echo -e "${BOLD}${WHITE}Deploying Service \"$service\"...${OFF}"
    kubectl run $cleanedService --image=$cleanedService --image-pull-policy=Never \
    --env="ALLOWED_HOSTS=*" \
    --env="CORS_ORIGIN_WHITELIST=*" \
    --env="DATABASE_ENGINE=postgresql" \
    --env="$dbhost_env_var=$dbhost" \
    --env="$dbport_env_var=$dbport" \
    --env="$dbname_env_var=$dbname" \
    --env="$dbuser_env_var=$dbuser" \
    --env="$dbpass_env_var=$dbpass" \
    --env="SECRET_KEY=test" \
    --namespace buildly

    echo -e "${BOLD}${WHITE}Let's expose the service internally, so Buildly Core can connect to it!${OFF}"
    echo -n "Enter the service inbound port: "
    read inbount_port
    echo -n "Enter the service outbound port: "
    read outbount_port
    kubectl expose deploy "$cleanedService" --port="$outbount_port" --target-port="$inbount_port" --namespace buildly

    connectService2Buildly "$cleanedService" "$outbount_port"
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

  if [[ -n "$1" && ("$1" == "minikube" || "$1" == "Minikube") ]] ;then
    helm repo add bitnami	https://charts.bitnami.com/bitnami
    helm install db-buildly \
    --set postgresqlPassword=root,postgresqlDatabase=buildly,servicePort=5432 \
      bitnami/postgresql --namespace buildly

    # set database configuration up
    dbhost=db-buildly-postgresql.buildly.svc.cluster.local
    dbport=5432
    dbuser=$(echo -n "postgres" | base64)
    dbpass=$(echo -n "root" | base64)
  else
    echo "${BOLD}${WHITE}Configure your Buildly Core to connect to a Database...${OFF}"
    echo -n "Enter host name or IP: "
    read dbhost
    echo -n "Enter Database Port: "
    read dbport
    echo -n "Enter Database Username: "
    read dbuser
    dbuser=$(echo "$dbuser" | base64)
    echo -n "Enter Database Password: "
    read dbpass
    dbpass=$(echo "$dbpass" | base64)
  fi

  if [[ -z "$dbhost" && -z "$dbport" && -z "$dbuser" && -z "$dbpass" ]]; then
    MSG="A database connection info (Hostname/IP, Port, Username, and Password) has to be provided."
    print_message "error" "$MSG"
  fi

  (
  setupHelm
  cd "helm-charts/buildly-core-chart" || return
  # install to minikube via helm
  if [[ -n "$1" && ("$1" == "CloudSQL" || "$1" == "cloudsql") ]] ;then
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

    echo -e "${BOLD}${WHITE}Deploying Buildly Core...${OFF}"
    helm install buildly-core . --namespace buildly \
    --set configmap.data.DATABASE_HOST="$dbhost" \
    --set-string configmap.data.DATABASE_PORT="$dbport" \
    --set secret.data.DATABASE_USER="$dbuser" \
    --set secret.data.DATABASE_PASSWORD="$dbpass" \
    --set gcp.enable="True" \
    --set gcp.cloudsql.name="$cloudsql_name" \
    --set gcp.cloudsql.port="$cloudsql_port" \
    --set gcp.cloudsql.project_id="$cloudsql_project" \
    --set gcp.cloudsql.region="$cloudsql_region" \
    --set gcp.cloudsql.secretName="$cloudsql_secret"
  else
    echo -e "${BOLD}${WHITE}Deploying Buildly Core...${OFF}"
    helm install buildly-core . --namespace buildly \
    --set configmap.data.DATABASE_HOST="$dbhost" \
    --set-string configmap.data.DATABASE_PORT="$dbport" \
    --set secret.data.DATABASE_USER="$dbuser" \
    --set secret.data.DATABASE_PASSWORD="$dbpass"
  fi
  )
}

deployBuildlyTemplate()
{
  if [ ! -d helm-charts/ ]; then
    git clone $github_url/$buildly_helm_repo_path
  fi

  (
  setupHelm
  cd "helm-charts/buildly-template-chart" || return
  echo -e "${BOLD}${WHITE}Deploying Buildly Template...${OFF}"
  helm install buildly-template . --namespace buildly \
  --set-string configmap.data.API_URL="http://localhost:8080/" \
  --set-string configmap.data.OAUTH_TOKEN_URL="http://localhost:8080/oauth/token/" \
  --set-string configmap.data.PRODUCTION="true"
  )
}

deploy2Minikube()
{
  # start mini kube if not already
  setupMinikube

  # build images for each service and buildly core
  setupServices

  # deploy buildly and services to a minikube instance
  deployBuildlyCore "minikube"
  deployServices "minikube"
  deployBuildlyTemplate

  # information about how to access Buildly from minikube
  cat <<EOF
${BOLD}${BLUE}To access your Buildly Core run the following command: ${OFF}

'''
kubectl port-forward service/buildly-core-service 8080:8080 --namespace buildly
'''

${BOLD}${BLUE}and then open your browser with URL${OFF} 'http://127.0.0.1:8080'

${BOLD}${BLUE}To access your Buildly Template, first you need to run the command above and
then in another tab of your terminal the following command:${OFF}

'''
kubectl port-forward service/buildly-template-service 9000:9000 --namespace buildly
'''

${BOLD}${BLUE}and then open your browser with URL${OFF} 'http://127.0.0.1:9000'

EOF
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

  # information about how to access Buildly from Docker
  echo -n "${BOLD}${WHITE}To access your Buildly Core, open the browser with the URL${OFF} 'http://127.0.0.1:8080'"
}

deploy2AWS()
{
  # Check specific dependencies
  type aws >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'AWS CLI' installed.
  Check the documentation of how to install it: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html"; exit 1; }
  type kubectl >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'K8S CLI' installed.
  Check the documentation of how to install it: https://kubernetes.io/docs/tasks/tools/install-kubectl/"; exit 1; }

  echo "AWS hosted Kubernetes... ok let's go!"
  echo "Let's make sure you have your AWS configs ready..."
  # init and auth to AWS
  if [ -f  ~/.aws/credentials ] && [ -f ~/.aws/config ]; then
    echo "You must configure your AWS CLI first."
    aws configure
  fi

  # define which kubernetes cluster will be used
  echo -n "${BOLD}${WHITE}Enter the name of your AWS Kubernetes cluster: ${OFF}"
  read k8s_cluster_name

  echo -n "${BOLD}${WHITE}Type the name of the region(e.g, us-east): ${OFF}"
  read region_name

  # generate kubeconfig file and switch context of kubectl
  aws eks --region "$region_name" update-kubeconfig --name "$k8s_cluster_name"
  contexts=$(kubectl config get-contexts)
  if [[ ! ( $contexts == *"$k8s_cluster_name"*) ]]; then
    MSG="Your cluster isn't available via \"kubectl\". Make sure your AWS CLI and kubeconfig are well configured."
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
    MSG="Your cluster isn't available via \"kubectl\". Make sure your GCP CLI and kubeconfig are well configured."
    print_message "error" "$MSG"
  fi

  # enable access to database instance from cloudsql
  echo -n "${BOLD}${WHITE}Is Buildly Core DB going to be a CloudSQL database? [Y/y] or No [N/n] ${OFF}"
  read use_cloudsql

  # deploy buildly using helm charts
  if [ "$use_cloudsql" != "${use_cloudsql#[Yy]}" ] ;then
    deployBuildlyCore "CloudSQL"
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
  elif [ "$1" == "error" ]; then
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
    echo -e "${BOLD}Buildly CLI ${version}${OFF}"
    echo ""
}

###############################################################################
#
# Print main help message
#
###############################################################################
print_help() {
cat <<EOF

${BOLD}${WHITE}Buildly CLI ${version}${OFF}

If it's your first time using this tool, you probably want to create an application,
so you can just execute this script with the option --create-application or -ca, e.g,

'''
$script_name --create-application
'''

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
    echo -e "${BOLD}${WHITE}Buildly CLI ${version}${OFF}"
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
  action="createService"
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
  MSG="Usage: $script_name [OPTION]\nTry '$script_name --help' for more information."
  echo -e "$MSG"
  exit 0
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
  createService)
  if [[ -z "$framework_name" ]]; then
    MSG="No framework name specified!"
    print_message "error" "$MSG"
  fi
  createService "$framework_name"
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
