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
    while true; do
        for frame in "${frames[@]}"; do
            echo -ne "${CYAN}${frame}${YELLOW} $message ${OFF}\r"
            sleep "$delay"
        done
    done
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

    PROMPT="
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
    PROMPT="$(cat buildly_ai_prompt.txt) You are a CLI assistant. Provide a list of Bash commands to automate file cleanup and organization for the given service. **Follow these rules strictly**:

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
