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
version="3.1.0"
tiny_model="tinyllama"

# Function: Display ASCII Art Header
display_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "    /\_/\   "
    echo "   ( o.o )  Buster the Buildly Rabbit's Module Assistant"
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

    # Ensure `tinyllama` is available
    if ! ollama list | grep -q "$tiny_model"; then
        echo -e "${YELLOW}Downloading model '$tiny_model'...${OFF}"
        ollama pull "$tiny_model"
    fi
}

# Function: Set up FastAPI Module (Basic Version)
setup_fastapi_module() {
    echo -e "${BOLD}${CYAN}Setting up a FastAPI Buildly Module with SQLAlchemy...${OFF}"

    echo -n "Enter the module name: "
    read -r module_name
    echo -n "Enter the database model names (comma-separated, e.g., 'User,Product'): "
    read -r model_names
    echo -e "ok setting up ${module_name}\n"

    echo -e "${BOLD}${CYAN}Setting up a FastAPI Buildly Module with SQLAlchemy...${OFF}"
    local default_folder="$HOME/Projects"
    local project_folder=""

    echo -e "${YELLOW}Where would you like to save this project?${OFF}"
    if [ -d "$default_folder" ]; then
        echo -e "Press Enter to use the default: ${GREEN}$default_folder${OFF}"
    fi
    read -r project_folder

    # Use default if empty
    if [ -z "$project_folder" ]; then
        project_folder="$default_folder"
    fi

    # Debug: Print the project folder
    echo -e "${CYAN}Project folder before sanitization: '$project_folder'${OFF}"

    # Sanitize input and create folder
    project_folder=$(eval echo "$project_folder" | tr -d '\n' | xargs)
    echo -e "${CYAN}Project folder after sanitization: '$project_folder'${OFF}"
    mkdir -p "$project_folder"
    echo "$project_folder"
    if [ -z "$project_folder" ]; then
        echo -e "${RED}Project location not provided. Exiting...${OFF}"
        exit 1
    fi
    if [ -z "$project_folder" ]; then
        echo -e "${RED}Project location not provided. Exiting...${OFF}"
        exit 1
    fi

    # Create service directory
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

def get_db():
    db = SessionLocal()
    try {
        yield db
    } finally {
        db.close()
    }
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

    echo -e "${GREEN}FastAPI module created in: ${service_path}${OFF}"
}

# Function: Add AI-Generated API Endpoints (Optional)
add_ai_generated_endpoints() {
    echo -e "${YELLOW}Would you like AI to generate API endpoints and improve your models? (Y/n)${OFF}"
    read -r use_ai

    if [[ "$use_ai" != "Y" && "$use_ai" != "y" ]]; then
        echo -e "${YELLOW}Skipping AI-generated API endpoints.${OFF}"
        return
    fi

    echo -e "${YELLOW}Fetching AI-generated API endpoints...${OFF}"

    # Start AI generation in the background
    loading_animation "Buster is writing the code..." &
    anim_pid=$!

    ollama run "$tiny_model" "Improve the existing FastAPI service by adding CRUD API endpoints for all models." > ai_output.tmp 2>&1 &
    local ai_pid=$!

    wait $ai_pid

    # Stop animation
    kill $anim_pid &>/dev/null
    wait $anim_pid 2>/dev/null

    # Output AI response in real-time for debugging
    if [[ -s "ai_output.tmp" ]]; then
        echo -e "${GREEN}AI successfully generated the code! Appending to main.py...${OFF}"
        cat ai_output.tmp | tee -a main.py
    else
        echo -e "${RED}AI failed to generate code. Check ai_output.tmp for details.${OFF}"
    fi

    rm -f ai_output.tmp
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
