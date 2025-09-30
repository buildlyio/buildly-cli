#!/bin/bash

# Buildly CLI Tool
# This script helps set up and manage a development environment for Buildly applications.
# It provides options to set up Minikube, Helm, Buildly Core, Buildly Templates, and services.
# Additionally, it allows interaction with the Buildly Marketplace.

# method responsible for starting a minikube instance

# scirpt variables
github_url="https://github.com"
github_api_url="https://api.github.com"
buildly_core_repo_path="buildlyio/buildly-core"
buildly_react_template_repo_path="buildlyio/buildly-react-template"
buildly_mkt_path="buildly-marketplace"

setupMinikube()
{
  # Check specific dependencies
  # Check if kubectl is installed and up-to-date
  if ! type kubectl >/dev/null 2>&1; then
    echo >&2 "ERROR: You do not have 'K8S CLI' (kubectl) installed."
    echo "Would you like to install it now? [Y/y] or No [N/n]"
    read install_kubectl
    if [ "$install_kubectl" != "${install_kubectl#[Yy]}" ]; then
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      chmod +x kubectl
      sudo mv kubectl /usr/local/bin/
      echo "kubectl has been installed."
    else
      exit 1
    fi
    current_version=$(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')
  else
    echo "Checking if kubectl is up-to-date..."
    current_version=$(kubectl version --client --short | awk '{print $3}')
    latest_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    if [ "$current_version" != "$latest_version" ] && [ -n "$current_version" ]; then
      echo "Your kubectl version ($current_version) is outdated. Would you like to update it? [Y/y] or No [N/n]"
      read update_kubectl
      if [ "$update_kubectl" != "${update_kubectl#[Yy]}" ]; then
        curl -LO "https://dl.k8s.io/release/$latest_version/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
        echo "kubectl has been updated to version $latest_version."
      fi
    fi
  fi

  # Check if minikube is installed and up-to-date
  if ! type minikube >/dev/null 2>&1; then
    echo >&2 "ERROR: You do not have 'Minikube' installed."
    echo "Would you like to install it now? [Y/y] or No [N/n]"
    read install_minikube
    if [ "$install_minikube" != "${install_minikube#[Yy]}" ]; then
      curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
      chmod +x minikube-linux-amd64
      sudo mv minikube-linux-amd64 /usr/local/bin/minikube
      echo "Minikube has been installed."
    else
      exit 1
    fi
  else
    echo "Checking if Minikube is up-to-date..."
    current_version=$(minikube version --output=json | jq -r '.minikubeVersion')
    latest_version=$(curl -s https://api.github.com/repos/kubernetes/minikube/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [ "$current_version" != "$latest_version" ]; then
      echo "Your Minikube version ($current_version) is outdated. Would you like to update it? [Y/y] or No [N/n]"
      read update_minikube
      if [ "$update_minikube" != "${update_minikube#[Yy]}" ]; then
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        chmod +x minikube-linux-amd64
        sudo mv minikube-linux-amd64 /usr/local/bin/minikube
        echo "Minikube has been updated to version $latest_version."
      fi
    fi
  fi

  # Check if Docker is installed
  if ! type docker >/dev/null 2>&1; then
    echo >&2 "ERROR: You do not have 'Docker' installed."
    echo "Would you like to install it now? [Y/y] or No [N/n]"
    read install_docker
    if [ "$install_docker" != "${install_docker#[Yy]}" ]; then
      curl -fsSL https://get.docker.com -o get-docker.sh
      sudo sh get-docker.sh
      rm get-docker.sh
      echo "Docker has been installed."
    else
      exit 1
    fi
  fi

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
  if ! type helm >/dev/null 2>&1; then
    echo >&2 "ERROR: You do not have 'Helm' installed."
    echo "Would you like to install Helm now? [Y/y] or No [N/n]"
    read install_helm
    if [ "$install_helm" != "${install_helm#[Yy]}" ]; then
      curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      echo "Helm has been installed."
    else
      echo "If you are interested in exploring Kapstan, a Buildly Internal Developer Partner, you can sign up here:"
      echo "https://kapstan.io/signup?ref=buildly"
      exit 1
    fi
  fi

  status=$(helm version --short)
  if [[ $status == *"v3."* ]]; then
    echo "Helm v3 is already installed and configured."
  else
    echo >&2 "ERROR: Helm v3 is required. Please install or upgrade to Helm v3."
    exit 1
  fi
}

# method to clone Buildly Core into the application folder and configure it
setupBuildlyCore()
{
  echo -n "${BOLD}${WHITE}Buildly Core configuration tool. Would you like to use Buildly Core inside Minikube for testing [M/m] or run it separately in a Docker container [D/d]? ${OFF}"
  read deployment_choice

  if [ -d "buildly-core" ]; then
    echo "Buildly Core already exists. Updating the repository..."
    cd buildly-core || exit
    git fetch origin
    git pull origin $(git rev-parse --abbrev-ref HEAD)
    cd ..
  else
    echo "Cloning Buildly Core"
    git clone "$github_url/$buildly_core_repo_path" "buildly-core"
  fi

  if [ "$deployment_choice" != "${deployment_choice#[Mm]}" ]; then
    echo "Setting up Buildly Core in Minikube..."
    kubectl create namespace buildly-core || echo "Namespace buildly-core already exists."

    # Create deployment.yaml
    mkdir -p buildly-core/k8s
    cp docs/core-deployment.yaml buildly-core/k8s/deployment.yaml
    cp docs/core-service.yaml buildly-core/k8s/service.yaml

    kubectl apply -f buildly-core/k8s/deployment.yaml -n buildly-core
    kubectl apply -f buildly-core/k8s/service.yaml -n buildly-core
    echo "Buildly Core has been deployed to Minikube."
  elif [ "$deployment_choice" != "${deployment_choice#[Dd]}" ]; then
    echo "Setting up Buildly Core using Docker Compose..."
    if [ ! -f "buildly-core/docker-compose.yml" ]; then
      echo "ERROR: docker-compose.yml file not found in the buildly-core directory."
      return
    fi
    (
      cd buildly-core || exit
      if type docker-compose >/dev/null 2>&1; then
        docker-compose build
        docker-compose up -d
      elif type docker compose >/dev/null 2>&1; then
        docker compose build
        docker compose up -d
      else
        echo "ERROR: Neither 'docker-compose' nor 'docker compose' is installed or available in PATH."
        exit 1
      fi
    )
    echo "Buildly Core is running using Docker Compose and accessible at:"
    echo "http://localhost:8080 or http://127.0.0.1:8080"

  else
    echo "Invalid choice. Please select either [M/m] for Minikube or [D/d] for Docker."
    return
  fi

  echo "Buildly Core setup is complete."
}

# method to clone buidly template into the application folder
setupBuildlyTemplate()
{
  echo -n "${BOLD}${WHITE}Would you like to use Buildly React Template? Yes [Y/y] or No [N/n] ${OFF}"
  read answer

  if [ "$answer" != "${answer#[Yy]}" ]; then
    echo "Cloning Buildly Template"
    git clone "$github_url/$buildly_react_template_repo_path" "buildly-react-template"

    echo -n "${BOLD}${WHITE}Would you like to deploy the Buildly React Template to Minikube [M/m] or use Docker [D/d]? ${OFF}"
    read deployment_choice

    if [ "$deployment_choice" != "${deployment_choice#[Mm]}" ]; then
      echo "Setting up Buildly React Template in Minikube..."
      kubectl create namespace buildly-react-template || echo "Namespace buildly-react-template already exists."

      # Create deployment.yaml
      mkdir -p buildly-react-template/k8s
      cp docs/react-deployment.yaml buildly-react-template/k8s/deployment.yaml
      cp docs/react-service.yaml buildly-react-template/k8s/service.yaml

      kubectl apply -f buildly-react-template/k8s/deployment.yaml -n buildly-react-template
      kubectl apply -f buildly-react-template/k8s/service.yaml -n buildly-react-template
      echo "Buildly React Template has been deployed to Minikube."
    elif [ "$deployment_choice" != "${deployment_choice#[Dd]}" ]; then
      echo "Setting up Buildly React Template in a Docker container..."
      docker build -t buildly-react-template:latest buildly-react-template
      docker run -d --name buildly-react-template -p 3000:3000 buildly-react-template:latest
      echo "Buildly React Template is running in a Docker container on port 3000."
    else
      echo "Invalid choice. Please select either [M/m] for Minikube or [D/d] for Docker."
      return
    fi

    echo "Buildly React Template setup is complete."
  else
    echo "Skipping Buildly React Template setup."
  fi
}

# method to set up BabbleBeaver AI framework
setupBabbleBeaver()
{
  echo -n "${BOLD}${WHITE}Would you like to set up BabbleBeaver, our AI and LLM framework? Yes [Y/y] or No [N/n] ${OFF}"
  read setup_babblebeaver

  if [ "$setup_babblebeaver" != "${setup_babblebeaver#[Yy]}" ]; then
    echo "Cloning BabbleBeaver repository..."
    git clone "https://github.com/open-build/BabbleBeaver" "BabbleBeaver"

    echo -n "${BOLD}${WHITE}Would you like to configure BabbleBeaver with OpenAI [O/o] or Gemini [G/g]? ${OFF}"
    read ai_choice

    if [ "$ai_choice" != "${ai_choice#[Oo]}" ]; then
      echo "Configuring BabbleBeaver for OpenAI..."
      # Example configuration for OpenAI
      cp BabbleBeaver/config/openai.example.yaml BabbleBeaver/config/openai.yaml
      echo "Please add your OpenAI API key to BabbleBeaver/config/openai.yaml."
    elif [ "$ai_choice" != "${ai_choice#[Gg]}" ]; then
      echo "Configuring BabbleBeaver for Gemini..."
      # Example configuration for Gemini
      cp BabbleBeaver/config/gemini.example.yaml BabbleBeaver/config/gemini.yaml
      echo "Please add your Gemini API key to BabbleBeaver/config/gemini.yaml."
    else
      echo "Invalid choice. Skipping AI configuration."
    fi

    echo "Integrating BabbleBeaver with Buildly Core and microservices..."
    # Example integration instructions
    echo "To connect BabbleBeaver to your Buildly Core modules, follow these steps:"
    echo "1. Add BabbleBeaver's API endpoint to your Buildly Core configuration."
    echo "2. Use BabbleBeaver's SDK to implement AI logic in your services."
    echo "3. Refer to the BabbleBeaver documentation for advanced integration options."

    echo "BabbleBeaver setup is complete."
  else
    echo "Skipping BabbleBeaver setup."
  fi
}

# Modify the setupServices function to prompt for BabbleBeaver integration
setupServices()
{
  type docker >/dev/null 2>&1 || { echo >&2 "ERROR: You do not have 'Docker' installed.
  Check the documentation of how to install it: https://docs.docker.com/v17.12/install/"; exit 1; }

  eval $(minikube docker-env)
  if [ ! -d YourApplication/services ]; then
    MSG="The application folder \"YourApplication/services\" doesn't exist"
    print_message "error" "$MSG"
  fi

  (
  cd "YourApplication/services" || return
  find . -mindepth 1 -maxdepth 1 -type d | while IFS= read -r service
  do
    (
    cd $service || exit
    cleanedService=$(echo "$service" | tr "[:punct:]" -)
    docker build . -t "${cleanedService}:latest" || exit
    )
    echo -n "${BOLD}${WHITE}Would you like to integrate BabbleBeaver AI logic into the $service service? Yes [Y/y] or No [N/n] ${OFF}"
    read integrate_babblebeaver
    if [ "$integrate_babblebeaver" != "${integrate_babblebeaver#[Yy]}" ]; then
      echo "Integrating BabbleBeaver into $service..."
      # Example integration logic
      echo "Refer to BabbleBeaver's SDK documentation to implement AI logic in $service."
    fi
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

# setup or request the project directory from the user and set it as the working directory until the script ends then 
# change back to the original working directory
setupProjectDirectory()
{
  # Check if the project directory is set
  if [ -z "$project_directory" ]; then
    # Detect the current user's home directory and set the default project directory
    default_directory="$HOME/Projects"
    read -p "Enter the path to your project directory (or press Enter to use the default '$default_directory'): " project_directory
    project_directory=${project_directory:-$default_directory}
  fi

  # Check if the directory exists, if not, create it
  if [ ! -d "$project_directory" ]; then
    echo "The directory '$project_directory' does not exist. Creating it now..."
    mkdir -p "$project_directory"
  fi

  # Change to the project directory
  cd "$project_directory" || exit
  echo "Working directory set to: $project_directory"
}


# Display the menu
showMenu() {
  # Set the terminal colors
  BOLD=$(tput bold)
  WHITE=$(tput setaf 7)
  OFF=$(tput sgr0)
  if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
      clear
  else
      echo -e "${YELLOW}Script is sourced; skipping screen clear.${OFF}"
  fi
  echo -e "${BOLD}${CYAN}"
  echo "    /\_/\   "
  echo "   ( o.o )  Buildly Developer Helper"
  echo "    > ^ <   "
  echo -e "${YELLOW}    Buildly.io - Build Smarter, Not Harder${OFF}"
  echo ""
  echo "Welcome to the Buildly CLI Tool!"
  echo "Please select an option:"
  echo "1) Set up Minikube"
  echo "2) Set up Helm"
  echo "3) Set up Buildly Core"
  echo "4) Set up Buildly Template"
  echo "5) Set up Services"
  echo "6) List Buildly Marketplace Services"
  echo "7) Clone a Buildly Marketplace Service"
  echo "8) Set up BabbleBeaver AI Framework"
  echo "9) Exit"
}

# Main script logic
while true; do
  showMenu
  setupProjectDirectory
  read -p "Enter your choice: " choice
  case $choice in
    1)
      setupMinikube
      ;;
    2)
      setupHelm
      ;;
    3)
      setupBuildlyCore
      ;;
    4)
      setupBuildlyTemplate
      ;;
    5)
      setupServices
      ;;
    6)
      listMktpServices
      ;;
    7)
      read -p "Enter the name of the service to clone: " service_name
      cloneMktpService "$service_name"
      ;;
    8)
      setupBabbleBeaver
      ;;
    9)
      echo "Exiting the Buildly CLI Tool. Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done
