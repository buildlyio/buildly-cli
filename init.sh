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

# Global variables to be set during initialization
base_model=""
fine_tuned_model=""

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

    # Check if prompt file exists
    if [[ ! -f "$prompt_file" ]]; then
        echo -e "${YELLOW}Warning: Prompt file '$prompt_file' not found. Creating basic model without fine-tuning.${OFF}"
        return 1
    fi

    # Check if the fine-tuned model already exists
    if ! ollama list | grep -q "$fine_tuned_model"; then
        echo -e "${CYAN}Fine-tuning $model_name with Buildly guidelines...${OFF}"
        
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
        if ollama create "$fine_tuned_model" -f "${fine_tuned_model}.modelfile"; then
            echo -e "${GREEN}Fine-tuned model created: $fine_tuned_model${OFF}"
            rm -f "${fine_tuned_model}.modelfile"  # Clean up temporary file
        else
            echo -e "${RED}Failed to create fine-tuned model. Using base model instead.${OFF}"
            return 1
        fi
    else
        echo -e "${GREEN}Fine-tuned model already exists: $fine_tuned_model${OFF}"
    fi
    return 0
}

# Function: Check & Install Ollama with model options
check_or_install_ollama() {
    # Check if Ollama is installed
    if ! command -v ollama &>/dev/null; then
        echo -e "${YELLOW}Ollama is not installed.${OFF}"
        echo -e "Would you like to install Ollama and a lightweight code-specific model locally? (Y/n)"
        read -r install_ollama

        if [[ "$install_ollama" == "Y" || "$install_ollama" == "y" || -z "$install_ollama" ]]; then
            echo -e "${GREEN}Installing Ollama...${OFF}"
            if ! curl -fsSL https://ollama.ai/install.sh | sh; then
                echo -e "${RED}Failed to install Ollama. Please check your internet connection and try again.${OFF}"
                exit 1
            fi
            echo -e "${GREEN}Ollama installed successfully!${OFF}"
        else
            echo -e "${YELLOW}Skipping Ollama installation. AI features will not be available.${OFF}"
            return 1
        fi
    fi

    # Check if Ollama service is running
    if ! ollama list >/dev/null 2>&1; then
        echo -e "${YELLOW}Starting Ollama service...${OFF}"
        ollama serve &
        sleep 3
        if ! ollama list >/dev/null 2>&1; then
            echo -e "${RED}Failed to start Ollama service. Please start it manually with 'ollama serve'${OFF}"
            return 1
        fi
    fi

    # Get available models
    echo -e "${CYAN}Checking available models on your system...${OFF}"
    available_models=($(ollama list | awk 'NR>1 {print $1}' | head -10))  # Skip header, limit to 10
    
    if [[ ${#available_models[@]} -gt 0 ]]; then
        echo -e "${CYAN}Available models:${OFF}"
        for i in "${!available_models[@]}"; do
            echo "$((i + 1))) ${available_models[$i]}"
        done
        echo -e "\nWould you like to use an existing model? (Y/n)"
        read -r use_existing_model

        if [[ "$use_existing_model" == "Y" || "$use_existing_model" == "y" || -z "$use_existing_model" ]]; then
            echo -e "Enter the number corresponding to the model you want to use:"
            read -r model_choice

            if [[ "$model_choice" =~ ^[0-9]+$ ]] && ((model_choice >= 1 && model_choice <= ${#available_models[@]})); then
                base_model="${available_models[$((model_choice - 1))]}"
                echo -e "${GREEN}Selected model: $base_model${OFF}"
                return 0
            else
                echo -e "${YELLOW}Invalid choice. Will proceed with default options.${OFF}"
            fi
        fi
    fi

    # Offer default model options
    echo -e "\nWhich AI model would you like to use?"
    echo -e "1) ${GREEN}tinyllama${OFF} (fast, ~1GB, good for basic help)"
    echo -e "2) ${BLUE}deepseek-coder-v2${OFF} (better for coding, ~8GB, more capable)"
    echo -e "Enter your choice (1 or 2, default: 1): "
    read -r model_choice

    case "$model_choice" in
        2) base_model="$code_model" ;;
        *) base_model="$tiny_model" ;;  # Default to tinyllama
    esac

    # Download model if not available
    if ! ollama list | grep -q "^$base_model"; then
        echo -e "${YELLOW}Downloading model '$base_model'... This may take a while.${OFF}"
        if ! ollama pull "$base_model"; then
            echo -e "${RED}Failed to download model '$base_model'. Please check your internet connection.${OFF}"
            return 1
        fi
        echo -e "${GREEN}Model '$base_model' downloaded successfully!${OFF}"
    fi

    return 0
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

echo -e "${BOLD}${WHITE}Welcome to the Buildly Developer Helper (v${version})${OFF}"
echo -e "Setting up your AI assistant...\n"

# Initialize Ollama and models
if check_or_install_ollama; then
    # Set the fine-tuned model name
    fine_tuned_model="buildly-${base_model}"
    
    # Ensure the fine-tuned model exists
    if check_fine_tune_model "$base_model"; then
        echo -e "${GREEN}AI assistant ready with model: $fine_tuned_model${OFF}"
    else
        echo -e "${YELLOW}Using base model: $base_model${OFF}"
        fine_tuned_model="$base_model"
    fi
else
    echo -e "${YELLOW}AI features disabled. You can still use the build scripts.${OFF}"
    fine_tuned_model=""
fi

echo -e "\n${CYAN}=== Buildly Development Environment ===${OFF}"

# Function to send a message to Ollama and get the response
function ollama_chat {
    local message="$1"
    
    # Check if AI is available
    if [[ -z "$fine_tuned_model" ]]; then
        echo -e "${RED}AI assistant is not available. Please restart the script and set up Ollama.${OFF}"
        return 1
    fi

    # Start the loading animation in the background
    loading_animation "Thinking..." &
    local loading_pid=$!

    # Get the response from Ollama
    response=$(ollama run "$fine_tuned_model" "$message" 2>&1)
    local exit_code=$?

    # Kill the loading animation
    kill "$loading_pid" 2>/dev/null
    wait "$loading_pid" 2>/dev/null

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${RED}Error communicating with AI model: $response${OFF}"
        return 1
    fi

    echo "$response"
    return 0
}

# Function to display menu with descriptions
show_menu() {
    echo -e "\n${CYAN}=== What would you like to build today? ===${OFF}"
    echo -e "${BOLD}Choose an option:${OFF}\n"
    
    echo -e "${GREEN}1) Quick Start - Full Application${OFF}"
    echo -e "   ${CYAN}→${OFF} Complete app with Buildly-core backend + React frontend"
    echo -e "   ${CYAN}→${OFF} Best for: New projects, prototypes, full-stack development"
    echo -e "   ${CYAN}→${OFF} Runs: dev.sh script\n"
    
    echo -e "${GREEN}2) Backend Service - Django${OFF}"
    echo -e "   ${CYAN}→${OFF} Standalone Django microservice"
    echo -e "   ${CYAN}→${OFF} Best for: Adding new services, API development"
    echo -e "   ${CYAN}→${OFF} Runs: django.sh script\n"
    
    echo -e "${GREEN}3) Backend Service - FastAPI${OFF}"
    echo -e "   ${CYAN}→${OFF} Standalone FastAPI microservice"
    echo -e "   ${CYAN}→${OFF} Best for: High-performance APIs, async operations"
    echo -e "   ${CYAN}→${OFF} Runs: fastapi.sh script\n"
    
    echo -e "${GREEN}4) AI Assistant - Chat with Buster${OFF}"
    echo -e "   ${CYAN}→${OFF} Get help with existing code, debugging, architecture questions"
    echo -e "   ${CYAN}→${OFF} Best for: Problem-solving, code review, learning"
    if [[ -z "$fine_tuned_model" ]]; then
        echo -e "   ${RED}→ AI assistant not available${OFF}\n"
    else
        echo -e "   ${CYAN}→${OFF} Using model: $fine_tuned_model\n"
    fi
    
    echo -e "${YELLOW}Type 'exit' or 'quit' to leave${OFF}"
    echo -e "${CYAN}Choose an option (1-4):${OFF} "
}

# Function to validate script exists
check_script_exists() {
    local script_name="$1"
    if [[ ! -f "./$script_name" ]]; then
        echo -e "${RED}Error: $script_name script not found in current directory.${OFF}"
        echo -e "${YELLOW}Please make sure you're running this from the buildly-cli directory.${OFF}"
        return 1
    fi
    return 0
}

# Main loop for chatting
while true; do
    show_menu
    read -r user_input

    # Exit the loop if the user enters "exit" or "quit"
    if [[ "$user_input" == "exit" || "$user_input" == "quit" || "$user_input" == "q" ]]; then
        echo -e "${GREEN}Thanks for using Buildly! Happy coding! 🐇${OFF}"
        break
    fi

    case "$user_input" in
        1)
            echo -e "\n${GREEN}🚀 Building a complete application with Buildly-core and React frontend...${OFF}"
            if check_script_exists "dev.sh"; then
                echo -e "${CYAN}This will set up:${OFF}"
                echo -e "  • Buildly-core backend with JWT authentication"
                echo -e "  • React frontend with routing and state management"
                echo -e "  • Docker containers for easy deployment"
                echo -e "  • Database integration and API gateway"
                echo -e "\n${YELLOW}Starting setup...${OFF}"
                bash ./dev.sh -ca
            fi
            ;;
        2)
            echo -e "\n${GREEN}🔧 Building a Django microservice...${OFF}"
            if check_script_exists "django.sh"; then
                echo -e "${CYAN}This will create:${OFF}"
                echo -e "  • Django REST API service"
                echo -e "  • Docker configuration"
                echo -e "  • Database models and migrations"
                echo -e "  • API documentation with Swagger"
                echo -e "\n${YELLOW}Starting Django service setup...${OFF}"
                bash ./django.sh
            fi
            ;;
        3)
            echo -e "\n${GREEN}⚡ Building a FastAPI microservice...${OFF}"
            if check_script_exists "fastapi.sh"; then
                echo -e "${CYAN}This will create:${OFF}"
                echo -e "  • FastAPI async service"
                echo -e "  • Automatic API documentation"
                echo -e "  • High-performance async endpoints"
                echo -e "  • Docker containerization"
                echo -e "\n${YELLOW}Starting FastAPI service setup...${OFF}"
                bash ./fastapi.sh
            fi
            ;;
        4)
            if [[ -z "$fine_tuned_model" ]]; then
                echo -e "\n${RED}❌ AI assistant is not available.${OFF}"
                echo -e "${YELLOW}Please restart the script and set up Ollama to use this feature.${OFF}"
            else
                echo -e "\n${CYAN}💬 Chat with Buster - Your Buildly AI Assistant${OFF}"
                echo -e "${YELLOW}Ask me about:${OFF}"
                echo -e "  • Django/FastAPI development best practices"
                echo -e "  • Buildly architecture and patterns"
                echo -e "  • Debugging help and code review"
                echo -e "  • Microservices design questions"
                echo -e "\n${CYAN}Type your question (or 'back' to return to main menu):${OFF}"
                read -r user_question
                
                if [[ "$user_question" == "back" || "$user_question" == "menu" ]]; then
                    continue
                elif [[ -n "$user_question" ]]; then
                    echo -e "\n${GREEN}🤔 Buster is thinking...${OFF}"
                    if ollama_chat "$user_question"; then
                        echo -e "\n${CYAN}💡 Need more help? Ask another question or type 'back' for the main menu.${OFF}"
                    fi
                else
                    echo -e "${YELLOW}No question entered. Returning to main menu.${OFF}"
                fi
            fi
            ;;
        *)
            echo -e "\n${RED}❌ Invalid choice: '$user_input'${OFF}"
            echo -e "${YELLOW}Please select a number from 1-4, or type 'exit' to quit.${OFF}"
            ;;
    esac
    
    # Add a pause before showing menu again (except for chat option)
    if [[ "$user_input" != "4" ]]; then
        echo -e "\n${CYAN}Press Enter to continue...${OFF}"
        read -r
    fi
done

echo -e "${CYAN}Buildly session ended. See you next time! 🐇${OFF}"
