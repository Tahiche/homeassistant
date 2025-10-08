#!/bin/bash

# GitHelper for Home Assistant D-Bus Bluetooth Tracker
# This script provides helper functions for git operations
# specific to the custom component development workflow.

# Set colors for better output readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Component directory
COMPONENT_DIR="custom_components/dbus_bt_tracker_v2"

# Function to check component status
check_component_status() {
    echo -e "${YELLOW}Checking component status...${NC}"
    
    if [ -d "$COMPONENT_DIR" ]; then
        echo -e "${GREEN}✓ Component directory exists${NC}"
    else
        echo -e "${RED}✗ Component directory not found${NC}"
        return 1
    fi
    
    # Check for required files
    for file in "device_tracker.py" "bluetooth_tracker.py" "manifest.json" "__init__.py"; do
        if [ -f "$COMPONENT_DIR/$file" ]; then
            echo -e "${GREEN}✓ $file exists${NC}"
        else
            echo -e "${RED}✗ $file missing${NC}"
            return 1
        fi
    done
    
    return 0
}

# Function to commit changes with standard format
commit_changes() {
    local message="$1"
    
    if [ -z "$message" ]; then
        echo -e "${RED}Error: Commit message is required${NC}"
        return 1
    fi
    
    git add "$COMPONENT_DIR"
    git commit -m "$message"
    echo -e "${GREEN}Changes committed: $message${NC}"
    return 0
}

# Function to create a development branch
create_dev_branch() {
    local branch_name="$1"
    
    if [ -z "$branch_name" ]; then
        echo -e "${RED}Error: Branch name is required${NC}"
        return 1
    fi
    
    git checkout -b "dev/$branch_name"
    echo -e "${GREEN}Created and switched to branch: dev/$branch_name${NC}"
    return 0
}

# Function to perform git push with automatic SSH setup
git_push() {
    local branch="${1:-main}"
    
    echo -e "${YELLOW}Preparing to push to origin/$branch...${NC}"
    
    # Always start SSH agent and add key before pushing
    echo -e "${YELLOW}Starting SSH agent...${NC}"
    eval $(ssh-agent -s)
    
    echo -e "${YELLOW}Adding SSH key...${NC}"
    ssh-add ~/.ssh/ha_id_rsa
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to add SSH key${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ SSH ready${NC}"
    
    # Perform git push
    echo -e "${YELLOW}Pushing to origin/$branch...${NC}"
    git push -u origin "$branch"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully pushed to origin/$branch${NC}"
    else
        echo -e "${RED}✗ Push failed${NC}"
        return 1
    fi
}

# Main menu function
show_menu() {
    echo -e "\n${YELLOW}=== D-Bus Bluetooth Tracker Git Helper ===${NC}"
    echo "1. Check component status"
    echo "2. Commit changes"
    echo "3. Create development branch"
    echo "4. Exit"
    
    read -p "Select an option (1-4): " choice
    
    case $choice in
        1) check_component_status ;;
        2) read -p "Enter commit message: " commit_msg
           commit_changes "$commit_msg" ;;
        3) read -p "Enter branch name (without dev/ prefix): " branch_name
           create_dev_branch "$branch_name" ;;
        4) echo "Exiting..." 
           exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}
# Function to initialize SSH for git operations
init_ssh() {
    echo -e "${YELLOW}Initializing SSH for git operations...${NC}"
    
    eval $(ssh-agent -s)
    echo -e "${GREEN}✓ SSH agent started${NC}"
    
    mkdir -p ~/.ssh
    echo -e "${GREEN}✓ SSH directory created${NC}"
    if [ ! -f "/data/.ssh/ha_id_rsa" ]; then
        echo -e "${RED}✗ SSH key not found at /data/.ssh/ha_id_rsa${NC}"
        return 1
    fi
    cp /data/.ssh/ha_id_rsa ~/.ssh/ha_id_rsa
    echo -e "${GREEN}✓ SSH key copied${NC}"
    
    chmod 600 ~/.ssh/ha_id_rsa
    echo -e "${GREEN}✓ SSH key permissions set${NC}"
    
    ssh-add ~/.ssh/ha_id_rsa
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ SSH key added to agent${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to add SSH key to agent${NC}"
        return 1
    fi
}

# Update menu function to include SSH initialization
show_menu() {
    echo -e "\n${YELLOW}=== D-Bus Bluetooth Tracker Git Helper ===${NC}"
    echo "1. Check component status"
    echo "2. Commit changes"
    echo "3. Create development branch"
    echo "4. Initialize SSH"
    echo "5. Git push (with automatic SSH setup)"
    echo "6. Exit"
    
    read -p "Select an option (1-6): " choice
    
    case $choice in
        1) check_component_status ;;
        2) read -p "Enter commit message: " commit_msg
           commit_changes "$commit_msg" ;;
        3) read -p "Enter branch name (without dev/ prefix): " branch_name
           create_dev_branch "$branch_name" ;;
        4) init_ssh ;;
        5) read -p "Enter branch name (default: main): " branch_name
           git_push "${branch_name:-main}" ;;
        6) echo "Exiting..." 
           exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}
# Execute menu if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_menu
fi
# Check if SSH key exists and initialize if needed
check_and_init_ssh() {
    if [ ! -f ~/.ssh/ha_id_rsa ]; then
        echo -e "${YELLOW}SSH key not found. Initializing SSH...${NC}"
        init_ssh
    fi
}

# Run SSH check at script start
check_and_init_ssh

# Create a simple function for command line use
gpush() {
    eval $(ssh-agent -s) && ssh-add ~/.ssh/ha_id_rsa && git push -u origin "${1:-main}"
}

# Export the function so it can be used in the shell
export -f gpush 2>/dev/null || true