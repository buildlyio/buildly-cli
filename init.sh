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
    clear
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

    # Let user choose AI model
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
  # Prompt the user for input
  read -p "How can I help?: " user_input

  # Exit the loop if the user enters "exit"
  if [[ "$user_input" == "exit" ]]; then
    break
  fi

  # Send the user input to Ollama and print the response
  ollama_chat "$user_input"
done

echo "Chat ended."
