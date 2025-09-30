#!/bin/bash

# Buildly CLI Tool
# This script helps you set up a testing frameowrk for the Buildly Core and Buildly React Template
# we will use the Robot Framework to set up the testing framework
# and the Buildly Marketplace to set up the testing framework for the Buildly Core and Buildly React Template

# scirpt variables
github_url="https://github.com"
github_api_url="https://api.github.com"
buildly_core_repo_path="buildlyio/buildly-core"
buildly_react_template_repo_path="buildlyio/buildly-react-template"
buildly_mkt_path="buildly-marketplace"

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

setupRobotFramework()
{
  # Check if Robot Framework is installed
  # pip install robotframework
  # pip install robotframework-requests

  # got to project directory
  if [ -z "$project_directory" ]; then
    echo "Project directory is not set. Please set it first."
    setupProjectDirectory
  fi

  # instal virtualenv if not already installed
  if ! command -v virtualenv &> /dev/null; then
    echo "Virtualenv is not installed. Installing it now..."
    pip install virtualenv
  fi

  # Check if the virtual environment exists and install it if not
  if [ ! -d "$project_directory/venv" ]; then
    echo "Virtual environment not found. Creating it now..."
    python3 -m venv "$project_directory/venv"
  fi

  # Check if the virtual environment is activated
  if [ -z "$VIRTUAL_ENV" ]; then
    echo "Virtual environment is not activated. Activating it now..."
    # Activate the virtual environment
    source venv/bin/activate
  fi

  # install robot framework and setup the testing framework and virtual envrionment
  if ! command -v robot &> /dev/null; then
    echo "Robot Framework is not installed. Installing it now..."
    pip install robotframework
    pip install robotframework-requests
  fi

  # Check if the tests directory exists
  if [ ! -d "$project_directory/tests" ]; then
    echo "The directory '$project_directory/robot-tests' does not exist. Creating it."
    
    mkdir -p "$project_directory/tests"
    mkdir -p "$project_directory/tests/suite"
  fi

  # Create tests for Buildly Core api swagger
  echo "Creating tests for Buildly Core API..."
  mkdir -p "$project_directory/tests/buildly-core"
  touch "$project_directory/tests/buildly-core/test_suite.robot"
  
  # create and set variabes for the test suite
  # Prompt the user to set the variables if not already set
  if [ -z "$BASE_URL" ]; then
    read -p "Enter the BASE_URL (default: https://labs-api.buildly.io): " BASE_URL
    BASE_URL=${BASE_URL:-https://labs-api.buildly.io}
  fi

  if [ -z "$AUTH_ENDPOINT" ]; then
    read -p "Enter the AUTH_ENDPOINT (default: /auth/token): " AUTH_ENDPOINT
    AUTH_ENDPOINT=${AUTH_ENDPOINT:-/auth/token}
  fi

  if [ -z "$USER_ME" ]; then
    read -p "Enter the USER_ME endpoint (default: /users/me): " USER_ME
    USER_ME=${USER_ME:-/users/me}
  fi

  if [ -z "$USERNAME" ]; then
    read -p "Enter the USERNAME (your test email): " USERNAME
  fi

  if [ -z "$PASSWORD" ]; then
    read -p "Enter the PASSWORD (your test password): " PASSWORD
  fi

  # Save the variables to a .env file in the test suite directory
  env_file="$project_directory/tests/.env"
  echo "Saving variables to $env_file..."
  {
    echo "BASE_URL=$BASE_URL"
    echo "AUTH_ENDPOINT=$AUTH_ENDPOINT"
    echo "USER_ME=$USER_ME"
    echo "USERNAME=$USERNAME"
    echo "PASSWORD=$PASSWORD"
  } > "$env_file"

  echo "Variables saved to $env_file."

  #generate theapt_tests.robot file
  # Generate the api_tests.robot file
  echo "Generating api_tests.robot file..."
  api_tests_file="$project_directory/tests/api_tests.robot"
  {
    echo "*** Settings ***"
    echo "Library           RequestsLibrary"
    echo "Resource          ../resources/variables.robot"
    echo ""
    echo "*** Test Cases ***"
    echo "Get Access Token"
    echo "    Create Session    buildly    \${BASE_URL}"
    echo "    \${data}=    Create Dictionary    username=\${USERNAME}    password=\${PASSWORD}"
    echo "    \${resp}=    POST On Session    buildly    \${AUTH_ENDPOINT}    data=\${data}"
    echo "    Should Be Equal As Strings    \${resp.status_code}    200"
    echo "    \${token}=    Set Variable    \${resp.json()['access_token']}"
    echo "    Set Suite Variable    \${TOKEN}    \${token}"
    echo ""
    echo "Get Authenticated User Info"
    echo "    [Setup]    Get Access Token"
    echo "    Create Session    buildly    \${BASE_URL}    headers=Authorization=Bearer \${TOKEN}"
    echo "    \${resp}=    GET On Session    buildly    \${USER_ME}"
    echo "    Should Be Equal As Strings    \${resp.status_code}    200"
    echo "    Log    \${resp.json()}"
  } > "$api_tests_file"

  echo "api_tests.robot file generated at '$api_tests_file'."
}

configureRobotFramework()
{
  # Check Project Directory
  if [ -z "$project_directory" ]; then
    echo "Project directory is not set. Please set it first."
    setupProjectDirectory
  fi
  # Check if the tests directory exists
  if [ ! -d "$project_directory/tests" ]; then
    echo "The directory '$project_directory/tests' does not exist. Please create it first."
    exit 1
  fi
  # Create robot framework test suite
  echo "Creating Robot Framework test suite..."
  mkdir -p "$project_directory/tests/suite"
  touch "$project_directory/tests/suite/test_suite.robot"
  echo "*** Settings ***" >> "$project_directory/tests/suite/test_suite.robot"
  echo "Library    SeleniumLibrary" >> "$project_directory/tests/suite/test_suite.robot"
  echo "*** Test Cases ***" >> "$project_directory/tests/suite/test_suite.robot"
  echo "Test Case 1" >> "$project_directory/tests/suite/test_suite.robot"
  echo "    [Documentation]    This is a test case" >> "$project_directory/tests/suite/test_suite.robot"
  echo "    Open Browser    https://example.com    chrome" >> "$project_directory/tests/suite/test_suite.robot"
  echo "    Close Browser" >> "$project_directory/tests/suite/test_suite.robot"
  echo "Robot Framework test suite created at '$project_directory/tests/suite/test_suite.robot'"
  # Create robot framework test suite for github
  mkdir -p "$project_directory/tests/github"
  touch "$project_directory/tests/github/test_suite.robot"
}

runRobotFrameworkTests()
{
  # Check if the Robot Framework is installed
  if ! command -v robot &> /dev/null; then
    echo "Robot Framework is not installed. Please install it first."
    exit 1
  fi

  # Run the Robot Framework tests
  echo "Running Robot Framework tests..."
  robot robot tests/api_tests.robot --outputdir results --loglevel DEBUG tests/
}

checkForUnitTests()
{
  if [ -z "$project_directory" ]; then
    echo "Project directory is not set. Please set it first."
    setupProjectDirectory
  fi

  checkTestsDirectories
  checkModelsAndViews
  checkCoverageFiles
}

checkTestsDirectories()
{
  for dir in "$project_directory"/*/; do
    if [ -d "$dir/tests" ]; then
      echo "Found tests directory in $dir"
      if [ "$(ls -A "$dir/tests")" ]; then
        echo "Found test files in $dir/tests"
        for file in "$dir/tests"/*; do
          if [[ "$file" == *"test_*.py" || "$file" == *"_test.py" ]]; then
            echo "Found test file: $file"
          fi
        done
      else
        echo "No test files found in $dir/tests"
      fi
    else
      echo "No tests directory found in $dir"
    fi
  done
}

checkModelsAndViews()
{
  for dir in "$project_directory"/*/; do
    checkModels "$dir"
    checkViews "$dir"
  done
}

checkModels()
{
  local dir=$1
  if [ -f "$dir/models.py" ]; then
    echo "Found models.py file in $dir"
    if grep -q "django.db.models" "$dir/models.py"; then
      echo "Found django models in $dir/models.py"
      checkTestFile "$dir/tests/test_models.py"
    elif grep -qE "from fastapi|import fastapi" "$dir/models.py"; then
      echo "Found FastAPI models in $dir/models.py"
      checkTestFile "$dir/tests/test_models.py"
    else
      echo "No django or fastapi models found in $dir/models.py"
    fi
  else
    echo "No models.py file found in $dir"
  fi
}

checkViews()
{
  local dir=$1
  if [ -f "$dir/views.py" ]; then
    echo "Found views.py file in $dir"
    if grep -qE "^\s*from\s+django\.views|^\s*import\s+django\.views" "$dir/views.py"; then
      echo "Found django views in $dir/views.py"
      checkTestFile "$dir/tests/test_views.py"
    elif grep -qE "from fastapi|import FastAPI" "$dir/views.py"; then
      echo "Found FastAPI views in $dir/views.py"
      checkTestFile "$dir/tests/test_views.py"
    else
      echo "No django or fastapi views found in $dir/views.py"
    fi
  else
    echo "No views.py file found in $dir"
  fi
}

checkTestFile()
{
  local test_file=$1
  if [ -f "$test_file" ]; then
    echo "Found test file: $test_file"
    if grep -q "coverage" "$test_file"; then
      echo "Found coverage in $test_file"
    else
      echo "No coverage found in $test_file"
    fi
  else
    echo "No test file found: $test_file"
  fi
}

checkCoverageFiles()
{
  for dir in "$project_directory"/*/; do
    if [ -d "$dir/tests" ]; then
      echo "Found tests directory in $dir"
      if [ -f "$dir/tests/coverage.py" ]; then
        echo "Found coverage.py file in $dir/tests"
        if grep -q "coverage" "$dir/tests/coverage.py"; then
          echo "Found coverage in $dir/tests/coverage.py"
        else
          echo "No coverage found in $dir/tests/coverage.py"
        fi
      else
        echo "No coverage.py file found in $dir/tests"
      fi
    else
      echo "No tests directory found in $dir"
    fi
  done
}


# setup or request the project directory from the user and set it as the working directory until the script ends then 
# change back to the original working directory
setupProjectDirectory()
{
  # Check if the project directory is set
  if [ -z "$project_directory" ]; then
    # Detect the current user's home directory and set the default project directory
    default_directory="$HOME/Projects"
    read -p "Enter the path to the project directory you want to test (or press Enter to use the default '$default_directory'): " project_directory
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
showMenu() 
{
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
  echo "   ( o.o )  Buildly QA/Test Helper"
  echo "    > ^ <   "
  echo -e "${YELLOW}    Buildly.io - Build Smarter, Not Harder${OFF}"
  echo ""
  echo "Welcome to the Buildly CLI Tool!"
  echo "Please select an option:"
  echo "1) Set up Robot Framework"
  echo "2) Run Robot Framework Tests"
  echo "3) Check for Unit Tests in Modules"
  echo "4) Exit"
}

# Main script logic
while true; do
  showMenu
  setupProjectDirectory
  read -p "Enter your choice: " choice
  case $choice in
    1)
      setupRobotFramework
      ;;
    2)
      runRobotFrameworkTests
      ;;
    3)
      checkForUnitTests
      ;;
    4)
      echo "Exiting the Buildly CLI Tool. Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done