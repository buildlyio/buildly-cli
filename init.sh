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
tiny_model="tinyllama"
code_model="deepseek-coder-v2"
prompt_file="buildly_ai_prompt.txt"

# Function: Display ASCII Art Header
display_header() {
    # Skip clear if the script is sourced
    if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
        clear
    else
        echo -e "${YELLOW}Script is sourced; skipping screen clear.${OFF}"
    fi
    echo -e "${BOLD}${CYAN}"
    echo "    /\_/\   "
    echo "   ( o.o )  Buster the Buildly Rabbit Helper and Helper AI"
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

# Function to fine-tune models dynamically
fine_tune_model() {
    local model_name="$1"
    local fine_tuned_model="buildly-${model_name}"

    # Check if the fine-tuned model already exists
    if ! ollama list | grep -q "$fine_tuned_model"; then
        echo -e "Fine-tuning $model_name with Buildly guidelines..."
        
        # Generate a modelfile dynamically
        cat > "${fine_tuned_model}.modelfile" <<EOF
FROM $model_name
PARAMETER temperature 0.8
PARAMETER num_ctx 4096
SYSTEM """
$(cat "$prompt_file")
"""
EOF

        # Fine-tune the model
        ollama create "$fine_tuned_model" -f "${fine_tuned_model}.modelfile"
        echo -e "${GREEN}Fine-tuned model created: $fine_tuned_model${OFF}"
    else
        echo -e "${GREEN}Fine-tuned model already exists: $fine_tuned_model${OFF}"
    fi
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

    # List available models
    echo -e "${CYAN}Available models on your system:${OFF}"
    available_models=($(ollama list | awk '{print $1}'))
    for i in "${!available_models[@]}"; do
        echo "$((i + 1))) ${available_models[$i]}"
    done

    echo -e "Would you like to use an existing model? (Y/n)"
    read -r use_existing_model

    if [[ "$use_existing_model" == "Y" || "$use_existing_model" == "y" ]]; then
        echo -e "Enter the number corresponding to the model you want to use:"
        read -r model_choice

        if [[ "$model_choice" =~ ^[0-9]+$ ]] && ((model_choice >= 1 && model_choice <= ${#available_models[@]})); then
            base_model="${available_models[$((model_choice - 1))]}"
        else
            echo -e "${RED}Invalid choice. Exiting.${OFF}"
            exit 1
        fi
    else
        # Let user choose one of our models
        echo -e "Which AI model would you like to use? (1) ${GREEN}tinyllama${OFF} (fast) or (2) ${BLUE}deepseek-coder-v2${OFF} (better for coding)"
        read -r model_choice

        case "$model_choice" in
            1) base_model="$tiny_model" ;;
            2) base_model="$code_model" ;;
            *) base_model="$tiny_model" ;; # Default to tinyllama
        esac

        # Ensure selected model is available
        if ! ollama list | grep -q "$base_model"; then
            echo -e "${YELLOW}Downloading model '$base_model'...${OFF}"
            if ! ollama pull "$base_model"; then
                echo -e "${RED}Failed to download model '$base_model'. Please check your internet connection.${OFF}"
                exit 1
            fi
        fi
    fi

    # Set the fine-tuned model name
    fine_tuned_model="buildly-${base_model}"
}

# Function: Check & Fine-Tune if necessary
check_fine_tune_model() {
    local model_name="$1"
    local fine_tuned_model="buildly-${model_name}"

    # Ensure the fine-tuned model exists
    if ! ollama list | grep -q "$fine_tuned_model"; then
        echo -e "${YELLOW}Fine-tuned model does not exist. Fine-tuning now...${OFF}"
        fine_tune_model "$model_name"
    fi
}   

# **Main Script Execution**
display_header
check_or_install_ollama

# Ensure the fine-tuned model exists
check_fine_tune_model "$base_model"

echo -e "${BOLD}${WHITE}Welcome to the Buildly Developer Helper (v${version})${OFF}\n We will fine tune an Ollama model to help you get started.\n"

# Function to send a message to Ollama and get the response
function ollama_chat {
    local message="$1"
    local prompt="$message"

    # Start the loading animation in the background
    loading_animation "Thinking..." &
    local loading_pid=$!

    # Get the response from Ollama
    response=$(ollama run "$fine_tuned_model" "$prompt" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: an error was encountered while running the model: $response${OFF}"
        kill "$loading_pid"
        wait "$loading_pid" 2>/dev/null
        continue
    fi

    # Kill the loading animation
    kill "$loading_pid"
    wait "$loading_pid" 2>/dev/null

    echo "$response"
}

# Main loop for chatting
while true; do
    echo -e "\nWhat would you like to do?"
    echo "1) Build a new service with Django and run django.sh script"
    echo "2) Build an app with FastAPI and run fastapi.sh script"
    echo "3) Build a new app including the Buildly-core and frontend template running dev.sh"
    echo "4) Ask Buster for help on an existing service or problem in the chat"
    echo "Type 'exit' to quit."

    # Prompt the user for input
    read -p "Enter your choice (1/2/3/4): " user_input

    # Exit the loop if the user enters "exit"
    if [[ "$user_input" == "exit" ]]; then
        echo "Exiting. Goodbye!"
        break
    fi

    case "$user_input" in
        1)
            echo -e "${GREEN}Building a new service with Django...${OFF}"
            if [[ -f "./django.sh" ]]; then
                bash ./django.sh
            else
                echo -e "${RED}Error: django.sh script not found.${OFF}"
            fi
            ;;
        2)
            echo -e "${GREEN}Building an app with FastAPI...${OFF}"
            if [[ -f "./fastapi.sh" ]]; then
                bash ./fastapi.sh
            else
                echo -e "${RED}Error: fastapi.sh script not found.${OFF}"
            fi
            ;;
        3)
            echo -e "${GREEN}Building a new app with Buildly-core and frontend template...${OFF}"
            if [[ -f "./dev.sh" ]]; then
                bash ./dev.sh -ca
            else
                echo -e "${RED}Error: dev.sh script not found.${OFF}"
            fi
            ;;
        4)
            echo -e "${CYAN}You can now ask Buster for help. Type your question below:${OFF}"
            read -p "Your question: " user_question
            if [[ -n "$user_question" ]]; then
                echo -e "${GREEN}Sending your question to Buster...${OFF}"
                response=$(ollama_chat "$user_question")
                echo -e "${CYAN}Buster's response:${OFF}\n$response"
            else
                echo -e "${YELLOW}No question entered. Returning to the main menu.${OFF}"
            fi
            ;;
        *)
            echo -e "${YELLOW}Invalid choice. Please select 1, 2, 3, or 4.${OFF}"
            ;;
    esac
done

echo "Chat ended."
