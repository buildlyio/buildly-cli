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
        model_names=$(ollama run "$tiny_model" "Generate a comma-separated list of database model names based on the following description: $module_description")
        echo -e "${GREEN}Generated model names: $model_names${OFF}"
    else
        echo -n "Enter the database model names (comma-separated, e.g., 'Customer,Invoice'): "
        read -r model_names
    fi

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

    # Validate model names
    if [ -z "$model_names" ]; then
        echo -e "${RED}Error: No model names provided. Please provide valid model names.${OFF}"
        exit 1
    fi

    if ! echo "$model_names" | grep -Eq '^[a-zA-Z0-9_,]+$'; then
        echo -e "${RED}Error: Model names contain invalid characters. Only alphanumeric characters and commas are allowed.${OFF}"
        exit 1
    fi

    # Generate models using AI
    echo -e "${YELLOW}Generating models using AI...${OFF}"
    ai_prompt="You are an expert Django developer following Buildly best practices. Generate Django models based on the following description and model names. Ensure the models are well-structured, include appropriate fields, and follow Django conventions. Description: $module_description. Model names: $model_names."

    # Use the existing Ollama model to generate the models
    models_content=$(ollama run "$tiny_model" "$ai_prompt")

    if [ -z "$models_content" ]; then
        echo -e "${RED}Error: Failed to generate models using AI.${OFF}"
        exit 1
    fi

    # Write the generated models to models.py
    echo "$models_content" > "$app_folder/models.py"
    echo -e "${GREEN}AI-generated models added to ${app_folder}/models.py${OFF}"

    # Generate serializers using AI
    echo -e "${YELLOW}Generating serializers using AI...${OFF}"
    ai_prompt_serializers="You are an expert Django developer. Generate Django REST framework serializers for the following models. Ensure each serializer includes filters for all fields. Models: $models_content."

    serializers_content=$(ollama run "$tiny_model" "$ai_prompt_serializers")

    if [ -z "$serializers_content" ]; then
        echo -e "${RED}Error: Failed to generate serializers using AI.${OFF}"
        exit 1
    fi

    # Write the generated serializers to serializers.py
    echo "$serializers_content" > "$app_folder/serializers.py"
    echo -e "${GREEN}AI-generated serializers added to ${app_folder}/serializers.py${OFF}"

    # Generate views using AI
    echo -e "${YELLOW}Generating views using AI...${OFF}"
    ai_prompt_views="You are an expert Django developer. Generate Django REST framework views (viewsets) for the following models. Ensure each viewset is properly configured for CRUD operations and integrates with the serializers. Models: $models_content."

    views_content=$(ollama run "$tiny_model" "$ai_prompt_views")

    if [ -z "$views_content" ]; then
        echo -e "${RED}Error: Failed to generate views using AI.${OFF}"
        exit 1
    fi

    # Write the generated views to views.py
    echo "$views_content" > "$app_folder/views.py"
    echo -e "${GREEN}AI-generated views added to ${app_folder}/views.py${OFF}"

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

    PROMPT="$(cat buildly_ai_prompt.txt) 
    You are an experienced Linux engineer with expertise in all Linux 
    commands and their 
    functionality across different Linux systems.  As well as a Django and Python engineer with experience in building RESTful APIs.

    Your task is to generate Django REST framework viewsets and serializers for
    models in $app_folder/models.py and make sure to remove any models or code
    not related to $model_names models. Make sure to only output code and
    nothing else.  Clean up any directories or Python files that isn't related
    to $model_names in the current directory and subfolders by renaming those
    files and directories. Ensure the folder structure and requirements.txt
    file are up to date and work for generating an OpenAPI Swagger documented
    set of endpoints for each model.

    Output only the command as a single line of plain text, with no 
    quotes, formatting, or additional commentary. Do not use markdown or any 
    other formatting. Do not include the command into a code block.
    Don't include the shell itself (bash, zsh, etc.) in the command.
    "

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

    (cd "$service_path" && ollama run "$tiny_model" "$PROMPT Generate Django REST framework viewsets and serializers for models in $app_folder/models.py and make sure to remove any models or code not related to $model_names models. Make sure to only output code and nothing else." > ai_output.tmp 2>&1) &

    # Wait for the first AI task to complete
    local ai_pid=$!
    wait $ai_pid

    #CLEANUP DIRS
        echo -e "🧹 ${CYAN}Generating AI-powered cleanup commands...${OFF}"

    # AI prompt
    PROMPT="You are a CLI assistant. Provide a list of Bash commands to automate file cleanup and organization for the given service. **Follow these rules strictly**:

    1. **Only output valid shell commands** – no explanations or markdown, just the commands.
    2. **One command per line** – each line should be a complete Bash command ready to run.
    3. **No placeholders or ambiguous syntax** – use actual file names/paths (based on context) instead of example or generic terms.
    4. **Ensure proper safety** – use flags or patterns that prevent unintended deletions (e.g., avoid rm -rf without specific paths; include confirmations or restrictions as needed).
    5. **Confine to the service directory** – operate only within the provided service’s folder (do not touch files outside the given directory structure).
    6. **Use precise patterns** – if using glob or regex, make them specific to target only intended files.

    _Remember:_ The output should contain nothing except the shell commands, each on its own line and be able to run in a Bash shell.
    "

    # Run Ollama in the background
    ollama run "$tiny_model" "$PROMPT" > ai_commands.bash 2>&1 &
    ai_pid=$!

    # Show loading animation
    loading_animation "Buster is organizing files..." &
    anim_pid=$!

    # Wait for Ollama to finish
    wait $ai_pid

    # Stop animation
    kill $anim_pid &>/dev/null
    wait $anim_pid 2>/dev/null

    echo -e "${GREEN}✅ AI-generated cleanup commands ready for execution.${OFF}"

    echo -e ai_commands.bash

    echo -e "${GREEN}🎉 AI-driven cleanup completed!${OFF}"

    # Clean up temporary files
    rm -f ai_commands.tmp ai_commands_cleaned.tmp ai_commands_filtered.tmp
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
        add_ai_generated_endpoints
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
