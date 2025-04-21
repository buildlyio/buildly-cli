#!/bin/bash

# Ensure the script runs with Bash
if [ -z "$BASH_VERSION" ]; then
  echo "This script must be run with Bash. Please use 'bash init.sh' to run this script."
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
version="3.2.0"
tiny_model="buildly-tinyllama"
code_model="buildly-deepseek-coder-v2"

# Function: Display ASCII Art Header
display_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "    /\_/\   "
    echo "   ( o.o )  Buster the Buildly Rabbit's Fast API Module Assistant"
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

# Function: Check & Install Ollama with model options
check_or_install_ollama() {
    if ! command -v ollama &>/dev/null; then
        echo -e "${YELLOW}Ollama is not installed.${OFF}"
        echo -e "Would you like to install Ollama and a lightweight code-specific model locally? (Y/n)"
        read -r install_ollama

        if [[ "$install_ollama" == "Y" || "$install_ollama" == "y" ]]; then
            echo -e "${GREEN}Installing Ollama...${OFF}"
            curl -fsSL https://ollama.ai/install.sh | sh
        else
            echo -e "${YELLOW}Skipping Ollama installation.${OFF}"
            return
        fi
    fi

    # Check for already installed models
    installed_models=$(ollama list | awk '{print $1}' | tail -n +2)
    if [[ -n "$installed_models" ]]; then
        echo -e "${YELLOW}The following models are already installed:${OFF}"
        echo "$installed_models"
        echo -e "Would you like to use one of these models? (Y/n)"
        read -r use_existing_model

        if [[ "$use_existing_model" == "Y" || "$use_existing_model" == "y" ]]; then
            echo -e "Enter the name of the model you want to use:"
            read -r selected_model
            if echo "$installed_models" | grep -q "^$selected_model$"; then
                ai_model="$selected_model"
                echo -e "${GREEN}Using existing model: $ai_model${OFF}"
                return
            else
                echo -e "${RED}Model '$selected_model' is not installed.${OFF}"
            fi
        fi
    fi

    # Let user choose AI model if no valid existing model is selected
    echo -e "Which AI model would you like to use? (1) ${GREEN}buildly-tinyllama${OFF} (fast) or (2) ${BLUE}buildly-deepseek-coder-v2${OFF} (better for coding)"
    read -r model_choice

    case "$model_choice" in
        1) ai_model="$tiny_model" ;;
        2) ai_model="$code_model" ;;
        *) ai_model="$tiny_model" ;; # Default to tinyllama
    esac

    # Ensure selected model is available
    if ! ollama list | grep -q "$ai_model"; then
        echo -e "${YELLOW}Downloading model '$ai_model'...${OFF}"
        ollama pull "$ai_model"
    fi
}

# Function: Set up FastAPI Module
setup_fastapi_module() {
    echo -e "${BOLD}${CYAN}Setting up a FastAPI Buildly Module with SQLAlchemy...${OFF}"

    echo -n "Enter the module name: "
    read -r module_name
    echo -n "Enter the database model names (comma-separated, e.g., 'User,Product'): "
    read -r model_names

    echo -e "${BOLD}${CYAN}Setting up your FastAPI module...${OFF}"
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

    project_folder=$(eval echo "$project_folder" | tr -d '\n' | xargs)
    mkdir -p "$project_folder"
    echo "$project_folder"

    service_path="$project_folder/$module_name"
    mkdir -p "$service_path"
    cd "$service_path" || exit

    # Create `main.py` with a basic FastAPI template
    cat > main.py <<EOF
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import Column, Integer, String, create_engine
from sqlalchemy.orm import sessionmaker, declarative_base, Session
from pydantic import BaseModel

DATABASE_URL = "sqlite:///./database.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

$(for model in $(echo "$model_names" | tr ',' ' '); do
cat <<MODEL
class ${model^}(Base):
    __tablename__ = "${model,,}s"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)

MODEL
done)

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Buildly API", version="1.0")
EOF

    # Create `requirements.txt`
    cat > requirements.txt <<EOF
fastapi
uvicorn
pydantic
sqlalchemy
EOF

    # Create `run.sh`
    cat > run.sh <<EOF
#!/bin/bash
echo "Starting FastAPI service..."
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
EOF
    chmod +x run.sh

    # Create `Dockerfile`
    cat > Dockerfile <<EOF
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["sh", "run.sh"]
EOF

    echo -e "${GREEN}FastAPI module created successfully in: ${service_path}${OFF}"
}

# Function: Add AI-Generated API Endpoints (Optional)
add_ai_generated_endpoints() {
    echo -e "${YELLOW}Would you like AI to generate API endpoints and improve your models? (Y/n)${OFF}"
    read -r use_ai

    if [[ "$use_ai" != "Y" && "$use_ai" != "y" ]]; then
        echo -e "${YELLOW}Skipping AI-generated API endpoints.${OFF}"
        return
    fi

    echo -e "${YELLOW}Buster is thinking... Generating AI-powered API endpoints...${OFF}"

    # Start animation in the background
    loading_animation "Generating endpoints..." &
    anim_pid=$!

    # Ask AI to generate the code based on existing code in the directory
    ollama run "$ai_model" "$(cat buildly_ai_prompt.txt) Write Python FastAPI CRUD endpoints for existing SQLAlchemy models in the directory '$service_path'. Ensure code is valid and formatted properly. No explanations, only code." > ai_output.tmp 2>&1 &
    local ai_pid=$!

    wait $ai_pid

    # Stop animation
    kill $anim_pid &>/dev/null
    wait $anim_pid 2>/dev/null

    # Debug: Print raw AI output before cleaning
    echo -e "${CYAN}Raw AI Output:${OFF}"
    cat ai_output.tmp

    # Sanitize AI output (remove ANSI escape codes & non-printable chars)
    sed -i 's/\x1B\[[0-9;]*[a-zA-Z]//g' ai_output.tmp
    tr -cd '\11\12\15\40-\176' < ai_output.tmp > ai_output_cleaned.tmp

    # Save clean output for debugging
    cat ai_output_cleaned.tmp > ai_output.log
    echo -e "${CYAN}AI output saved to ai_output.log for review.${OFF}"

    # Validate AI output (check if it contains Python functions or class definitions)
    if grep -q "def " ai_output_cleaned.tmp || grep -q "class " ai_output_cleaned.tmp; then
        echo -e "${GREEN}AI successfully generated the code! Appending to main.py...${OFF}"
        cat ai_output_cleaned.tmp | tee -a main.py
    else
        echo -e "${RED}AI output does not contain valid Python functions. Check ai_output.log.${OFF}"
    fi

    # Cleanup temp files
    rm -f ai_output.tmp ai_output_cleaned.tmp
}


# **Main Script Execution**
display_header
check_or_install_ollama

echo -e "${BOLD}${WHITE}Welcome to the Buildly Logic Module Assistant (v${version})${OFF}"
echo "1. Set up a FastAPI Buildly Logic Module"
echo "2. Exit"

read -r user_choice

if [[ "$user_choice" == "1" ]]; then
    setup_fastapi_module
    add_ai_generated_endpoints
elif [[ "$user_choice" == "2" ]]; then
    echo -e "${RED}Exiting...${OFF}"
else
    echo -e "${RED}Invalid choice!${OFF}"
fi
