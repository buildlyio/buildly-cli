#!/bin/bash

# Ensure script runs in Bash
if [ -z "$BASH_VERSION" ]; then
  echo "This script must be run with Bash. Please use 'bash init_django.sh' to run this script."
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
github_template="https://github.com/Buildly-Marketplace/crm_service.git"
tiny_model="tinyllama"

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

# Function: Check & Install Ollama with `tinyllama`
check_or_install_ollama() {
    if ! command -v ollama &>/dev/null; then
        echo -e "${YELLOW}Ollama is not installed.${OFF}"
        echo -e "Would you like to install Ollama? (Y/n)"
        read -r install_ollama

        if [[ "$install_ollama" == "Y" || "$install_ollama" == "y" ]]; then
            echo -e "${GREEN}Installing Ollama...${OFF}"
            curl -fsSL https://ollama.ai/install.sh | sh
        else
            echo -e "${YELLOW}Skipping Ollama installation.${OFF}"
            return
        fi
    fi

    # Ensure `tinyllama` is available
    if ! ollama list | grep -q "$tiny_model"; then
        echo -e "${YELLOW}Downloading model '$tiny_model'...${OFF}"
        ollama pull "$tiny_model"
    fi
}

# Function: Set up Django Buildly Module
setup_django_module() {
    echo -e "${BOLD}${CYAN}Setting up a Django Buildly Module...${OFF}"

    echo -n "Enter the module name: "
    read -r module_name
    echo -n "Enter the database model names (comma-separated, e.g., 'Customer,Invoice'): "
    read -r model_names

    # Ask for project location
    local default_folder="$HOME/Projects"
    local project_folder=""

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

    echo -e "${YELLOW}Cloning Django template from $github_template...${OFF}"
    git clone "$github_template" "$service_path"

    # Navigate to service directory
    cd "$service_path" || exit

    # Remove existing `.git` history
    rm -rf .git

    # Find the Django app directory (assume it's the one containing `models.py`)
    app_folder=$(find . -type f -name "models.py" | head -n 1 | xargs dirname)

    if [ -z "$app_folder" ]; then
        echo -e "${RED}Error: Could not find a valid Django app directory.${OFF}"
        exit 1
    fi

    echo -e "${GREEN}Django app folder detected: ${app_folder}${OFF}"

    # Generate models
    echo -e "${YELLOW}Generating models...${OFF}"
    for model in $(echo "$model_names" | tr ',' ' '); do
        cat >> "$app_folder/models.py" <<MODEL

class ${model^}(models.Model):
    name = models.CharField(max_length=255)

    def __str__(self):
        return self.name

MODEL
    done

    echo -e "${GREEN}Models added to ${app_folder}/models.py${OFF}"

    # Generate requirements.txt
    echo -e "${YELLOW}Creating requirements.txt...${OFF}"
    cat > requirements.txt <<EOF
Django
djangorestframework
drf-yasg
EOF

    # Create `run.sh`
    cat > run.sh <<EOF
#!/bin/bash
echo "Starting Django service..."
python manage.py runserver 0.0.0.0:8000
EOF
    chmod +x run.sh

    # Create Dockerfile
    cat > Dockerfile <<EOF
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["sh", "run.sh"]
EOF

    echo -e "${GREEN}Django module with API, Dockerfile, and run script created at: ${service_path}${OFF}"
}

# Function: Add AI-Generated API Endpoints (Optional)
add_ai_generated_endpoints() {
    echo -e "${YELLOW}Would you like AI to generate API endpoints? (Y/n)${OFF}"
    read -r use_ai

    if [[ "$use_ai" != "Y" && "$use_ai" != "y" ]]; then
        echo -e "${YELLOW}Skipping AI-generated API endpoints.${OFF}"
        return
    fi

    echo -e "${YELLOW}Generating AI-powered API endpoints...${OFF}"

    # Locate Django app directory again
    app_folder=$(find . -type f -name "models.py" | head -n 1 | xargs dirname)

    if [ -z "$app_folder" ]; then
        echo -e "${RED}Error: Could not find a valid Django app directory.${OFF}"
        exit 1
    fi

    ollama run "$tiny_model" "Generate Django REST framework viewsets and serializers for models in $app_folder/models.py." > ai_output.tmp 2>&1 &

    local ai_pid=$!
    wait $ai_pid

    echo -e "${CYAN}AI Output:${OFF}"
    cat ai_output.tmp

    # Save clean output
    sed -i 's/\x1B\[[0-9;]*[a-zA-Z]//g' ai_output.tmp
    tr -cd '\11\12\15\40-\176' < ai_output.tmp > ai_output_cleaned.tmp
    cat ai_output_cleaned.tmp > ai_output.log

    # Append valid AI output
    if grep -q "class " ai_output_cleaned.tmp || grep -q "def " ai_output_cleaned.tmp; then
        echo -e "${GREEN}Appending AI-generated API to views.py...${OFF}"
        cat ai_output_cleaned.tmp >> "$app_folder/views.py"
    else
        echo -e "${RED}AI output is invalid. Check ai_output.log.${OFF}"
    fi

    rm -f ai_output.tmp ai_output_cleaned.tmp
}

# **Main Script Execution**
display_header
check_or_install_ollama

echo -e "${BOLD}${WHITE}Welcome to the Buildly Django Module Assistant (v${version})${OFF}"
echo "1. Set up a Django Buildly Module"
echo "2. Exit"

read -r user_choice

if [[ "$user_choice" == "1" ]]; then
    setup_django_module
    add_ai_generated_endpoints
elif [[ "$user_choice" == "2" ]]; then
    echo -e "${RED}Exiting...${OFF}"
else
    echo -e "${RED}Invalid choice!${OFF}"
fi
