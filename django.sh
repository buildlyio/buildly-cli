#!/bin/bash

# Ensure script runs in Bash
if [ -z "$BASH_VERSION" ]; then
  echo "This script requires Bash. Use 'bash init_django.sh' to run it."
  exit 1
fi

# Define Colors
if [ -t 1 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    CYAN="$(tput setaf 6)"
    BOLD="$(tput bold)"
    WHITE="$(tput setaf 7)"
    OFF="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    BOLD=""
    OFF=""
fi

# Script Metadata
script_name=$(basename "$0")
version="1.1.0"
github_template="https://github.com/Buildly-Marketplace/logic_service.git"
tiny_model="deepseek-coder-v2"

# Function: Display ASCII Art Header
display_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "    /\_/\   "
    echo "   ( o.o )  Buster the Buildly Rabbit's Django Module Assistant"
    echo "    > ^ <   "
    echo -e "${YELLOW}    Buildly.io - Build Smarter, Not Harder${OFF}"
    echo ""
}

# Function: Animated "Buster Chasing ..." Loader
loading_animation() {
    local message=$1
    delay=0.2
    frames=("🐇   " " .🐇  " "  ..🐇 " "   ...🐇" "  ..🐇" " .🐇  " "  .🐇.  ")
    end_time=$((SECONDS + ${2:-10})) # Default duration is 10 seconds if not provided
    while [ $SECONDS -lt $end_time ]; do
        for frame in "${frames[@]}"; do
            echo -ne "${CYAN}${frame}${YELLOW} $message ${OFF}\r"
            sleep "$delay"
        done
    done
    echo -ne "${OFF}\r" # Clear the line after animation ends
}

# Function: Check & Install Ollama with `tinyllama`
check_or_install_ollama() {
    if ! command -v ollama &>/dev/null; then
        echo -e "${YELLOW}Ollama is not installed.${OFF}"
        echo -e "Would you like to install Ollama? (Y/n)"
        read -r install_ollama

        if [[ "$install_ollama" == "Y" || "$install_ollama" == "y" ]]; then
            echo -e "${GREEN}Installing Ollama...${OFF}"
            if ! curl -fsSL https://ollama.ai/install.sh | sh; then
                echo -e "${RED}Failed to install Ollama. Exiting...${OFF}"
                exit 1
            fi
        else
            echo -e "${RED}Ollama is required to proceed. Exiting...${OFF}"
            exit 1
        fi
    fi

    # Check for existing models
    if ollama list | grep -q "$tiny_model"; then
        echo -e "${GREEN}Model '$tiny_model' is already installed.${OFF}"
        echo -e "Would you like to use this model? (Y/n)"
        read -r use_existing_model

        if [[ "$use_existing_model" != "Y" && "$use_existing_model" != "y" ]]; then
            echo -e "${YELLOW}Enter the name of a different model to use:${OFF}"
            read -r new_model
            tiny_model="$new_model"
        fi
    else
        echo -e "${YELLOW}Model '$tiny_model' is not installed.${OFF}"
        echo -e "Would you like to download it? (Y/n)"
        read -r download_model

        if [[ "$download_model" == "Y" || "$download_model" == "y" ]]; then
            echo -e "${YELLOW}Downloading model '$tiny_model'...${OFF}"
            if ! ollama pull "$tiny_model"; then
                echo -e "${RED}Failed to download model '$tiny_model'. Exiting...${OFF}"
                exit 1
            fi
        else
            echo -e "${YELLOW}Enter the name of a different model to use:${OFF}"
            read -r new_model
            tiny_model="$new_model"
            echo -e "${YELLOW}Downloading model '$tiny_model'...${OFF}"
            if ! ollama pull "$tiny_model"; then
                echo -e "${RED}Failed to download model '$tiny_model'. Exiting...${OFF}"
                exit 1
            fi
        fi
    fi
}

# Function: Set up Django Buildly Module
setup_django_module() {
    echo -e "${BOLD}${CYAN}Setting up a Django Buildly Module...${OFF}"

    echo -n "Enter the module name: "
    read -r module_name

    echo -n "Briefly describe the module you are building: "
    read -r module_description

    echo -e "${YELLOW}Would you like AI to generate the model names from your description? (Y/n)${OFF}"
    read -r generate_models

    if [[ "$generate_models" == "Y" || "$generate_models" == "y" ]]; then
        echo -e "${YELLOW}Generating model names from description...${OFF}"
        model_names=$(ollama run "$tiny_model" "Generate a comma-separated list of database model names using captial case Python syntax based on the following description: $module_description  do not generate or output anything but the comma seperated list in capital case.")
        echo -e "${GREEN}Generated model names: $model_names${OFF}"
    else
        echo -n "Enter the database model names (comma-separated, e.g., 'Customer,Invoice'): "
        read -r model_names
    fi

    # Ask for project location
    local default_folder="$HOME/Projects"
    local project_folder=""

    #Trim and clean model names
    model_names=$(echo "$model_names" | tr -d '[:space:]' | tr ',' ' ')
    model_names=$(echo "$model_names" | tr '[:upper:]' '[:lower:]')

    echo -e "${YELLOW}Where would you like to save this project?${OFF}"
    if [ -d "$default_folder" ]; then
        echo -e "Press Enter to use the default: ${GREEN}$default_folder${OFF}"
    fi
    read -r project_folder

    if [ -z "$project_folder" ]; then
        project_folder="$default_folder"
    fi

    # Create project folder
    mkdir -p "$project_folder"
    service_path="$project_folder/$module_name"
    mkdir -p "$service_path"
    cd "$project_folder" || exit

    git clone "$github_template" "$service_path" || { echo -e "${RED}Error: Failed to clone the Django template. Exiting...${OFF}"; exit 1; }

    cd "$service_path" || { echo -e "${RED}Error: Failed to navigate to the service directory. Exiting...${OFF}"; exit 1; }

    rm -rf .git || { echo -e "${RED}Error: Failed to remove existing .git history. Exiting...${OFF}"; exit 1; }

    # Find the Django app directory (assume it's the one containing `models.py`)
    app_folder=$(find . -type f -name "models.py" | head -n 1 | xargs dirname)

    if [ -z "$app_folder" ]; then
        echo -e "${RED}Error: Could not find a valid Django app directory.${OFF}"
        exit 1
    fi

    echo -e "${GREEN}Django app folder detected: ${app_folder}${OFF}"

    # Generate models using AI
    echo -e "${YELLOW}Generating models using AI...${OFF}"
    ai_prompt="You are an expert Django developer following Buildly best practices. Generate Django models based on the following description and model names. Ensure the models are well-structured, include appropriate fields, and follow Django conventions. Description: $module_description. Model names: $model_names.  Do not generate anything but the code."

    # Use the existing Ollama model to generate the models
    models_content=$(ollama run "$tiny_model" "$ai_prompt")

    if [ -z "$models_content" ]; then
        echo -e "${RED}Error: Failed to generate models using AI.${OFF}"
        exit 1
    fi

    # Remove unwanted "```python" and "```" from the models_content variable
    models_content=$(echo "$models_content" | sed 's/^```python//;s/^```//;s/```$//')

    # Write the cleaned models content to models.py
    echo "$models_content" > "$app_folder/models.py"
    echo -e "${GREEN}AI-generated models added to ${app_folder}/models.py${OFF}"

    # Generate serializers using AI
    echo -e "${YELLOW}Generating serializers using AI...${OFF}"
    ai_prompt_serializers="You are an expert Django developer. Generate Django REST framework serializers for the following models. Ensure each serializer includes filters for all fields. Models: $models_content.  Do not generate or output anything but code."

    serializers_content=$(ollama run "$tiny_model" "$ai_prompt_serializers")

    if [ -z "$serializers_content" ]; then
        echo -e "${RED}Error: Failed to generate serializers using AI.${OFF}"
        exit 1
    fi

    # Remove unwanted "```python" and "```" from the serializers_content variable
    serializers_content=$(echo "$serializers_content" | sed 's/^```python//;s/^```//;s/```$//')

    # Write the generated serializers to serializers.py
    echo "$serializers_content" > "$app_folder/serializers.py"
    echo -e "${GREEN}AI-generated serializers added to ${app_folder}/serializers.py${OFF}"

    # Generate views using AI
    echo -e "${YELLOW}Generating views using AI...${OFF}"
    ai_prompt_views="You are an expert Django developer. Generate Django REST framework views (viewsets) for the following models. Ensure each viewset is properly configured for CRUD operations and integrates with the serializers. Models: $models_content. Do not generate or output anything but code."

    views_content=$(ollama run "$tiny_model" "$ai_prompt_views")

    if [ -z "$views_content" ]; then
        echo -e "${RED}Error: Failed to generate views using AI.${OFF}"
        exit 1
    fi

    # Remove unwanted "```python" and "```" from the views_content variable
    views_content=$(echo "$views_content" | sed 's/^```python//;s/^```//;s/```$//') 

    # Write the generated views to views.py
    echo "$views_content" > "$app_folder/views.py"
    echo -e "${GREEN}AI-generated views added to ${app_folder}/views.py${OFF}"

    # Update logic_service/urls.py with the new views
    echo -e "${YELLOW}Updating logic_service/urls.py with the new views...${OFF}"
    urls_file="$app_folder/urls.py"

    # Generate URL patterns using AI
    ai_prompt_urls="You are an expert Django developer. Update the Django REST framework router in the following urls.py file to use the newly generated class-based views. Replace any existing router URLs with the new views. Models: $models_content. Do not generate or output anything but code."

    urls_content=$(ollama run "$tiny_model" "$ai_prompt_urls")

    if [ -z "$urls_content" ]; then
        echo -e "${RED}Error: Failed to generate URLs using AI.${OFF}"
        exit 1
    fi

    # Remove unwanted "```python" and "```" from the urls_content variable
    urls_content=$(echo "$urls_content" | sed 's/^```python//;s/^```//;s/```$//')

    # Use the AI to Update README.md with new app description and guide on how to add new models, views and serializers to the service and how to connect them to the Buildly Core
    readme_file="$service_path/README.md"
    readme_content=$(ollama run "$tiny_model" "Update the README.md file with the following description: $module_description. Include a guide on how to add new models, views, and serializers to the service and how to connect them to the Buildly Core.")
    if [ -z "$readme_content" ]; then
        echo -e "${RED}Error: Failed to generate README.md content using AI.${OFF}"
        exit 1
    fi
    # Remove unwanted "```python" and "```" from the readme_content variable
    readme_content=$(echo "$readme_content" | sed 's/^```python//;s/^```//;s/```$//')
    # Write the updated README.md content to the file
    echo "$readme_content" > "$readme_file"
    echo -e "${GREEN}Updated README.md with module description and guide on how to add new models, views, and serializers.${OFF}"

    # Write the updated URLs to urls.py
    echo "$urls_content" > "$urls_file"
    echo -e "${GREEN}Updated URLs added to ${urls_file}${OFF}"

    echo -e "${GREEN}Django module with API, Dockerfile, and run script created at: ${service_path}${OFF}"

    echo -e "${YELLOW}What would you like to do next?${OFF}"
    echo "1. Run the Django server"
    echo "2. View the code in Visual Studio Code"
    echo "3. Build another service"
    echo "4. Exit"

    while true; do
        read -r next_action

        case "$next_action" in
            1)
                echo -e "${GREEN}Running Django server...${OFF}"
                cd "$service_path" || exit
                docker-compose up -d
                loading_animation "Buster is starting the server..." 10
                echo -e "${GREEN}Django server is running!${OFF}"
                break
                ;;
            2)
                echo -e "${GREEN}Opening the code in Visual Studio Code...${OFF}"
                code "$service_path"
                break
                ;;
            3)
                echo -e "${GREEN}Restarting to build another service...${OFF}"
                setup_django_module
                break
                ;;
            4)
                echo -e "${RED}Exiting...${OFF}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice! Please select a valid option.${OFF}"
                ;;
        esac
    done
}

# **Main Script Execution**
display_header
check_or_install_ollama

echo -e "${BOLD}${CYAN}Welcome to the Buildly Django Module Assistant (v${version})${OFF}"
echo "1. Set up a Django Buildly Module"
echo "2. Exit"

while true; do
    read -r user_choice

    if [[ "$user_choice" == "1" ]]; then
        setup_django_module
        break
    elif [[ "$user_choice" == "2" ]]; then
        echo -e "${RED}Exiting...${OFF}"
        break
    else
        echo -e "${RED}Invalid choice! Please try again.${OFF}"
    fi
done
else
    echo -e "${RED}Invalid choice!${OFF}"
fi
