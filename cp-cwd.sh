#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   cPanel Change Working Directory v1.0.0                                  ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Author:   Percio Castelo                                                ║
# ║   Contact:  percio@evolya.com.br | contato@perciocastelo.com.br           ║
# ║   Web:      https://perciocastelo.com.br                                  ║
# ║                                                                           ║
# ║   Function: Change to DocumentRoot - accepts username OR domain           ║
# ║                                                                           ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

# Detects if it is being executed directly
if [[ "$0" != "bash" && "$0" != "-bash" && "$0" != *"cwd" ]]; then
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    
    check_and_install_wrapper() {
        local bashrc="$HOME/.bashrc"
        local wrapper_marker="# CWD AUTO-WRAPPER"
        
        if grep -q "$wrapper_marker" "$bashrc" 2>/dev/null && grep -q "$SCRIPT_PATH" "$bashrc" 2>/dev/null; then
            return 0
        fi
        
        if grep -q "$wrapper_marker" "$bashrc" 2>/dev/null; then
            sed -i "/$wrapper_marker/,/# END CWD WRAPPER/d" "$bashrc" 2>/dev/null
        fi
        
        cat >> "$bashrc" << EOF

# CWD AUTO-WRAPPER - DO NOT MODIFY
cwd() {
    local output
    output=\$($SCRIPT_PATH "\$@" 2>&1)
    local exit_code=\$?
    if [[ \$exit_code -eq 0 ]]; then
        eval "\$output"
    else
        echo "\$output" | sed 's/^echo "//; s/"\$//'
    fi
}
# END CWD WRAPPER
EOF
        
        echo "CWD wrapper installed in .bashrc"
        echo "Run 'source ~/.bashrc' or log in again to use the 'cwd' command"
        echo ""
    }
    
    check_and_install_wrapper
fi

# ========== MAIN SCRIPT ==========

QUIET_MODE=0
VERBOSE=0
URL=""
ERROR_OCCURRED=0
ERROR_MESSAGE=""

set_error() {
    ERROR_MESSAGE="$1"
    ERROR_OCCURRED=1
    return 1
}

print_error_and_exit() {
    local msg="$1"
    msg=$(echo "$msg" | sed 's/"/\\"/g')
    echo "echo \"$msg\""
    exit 1
}

print_quiet_exit() {
    echo "echo -n"
    exit 1
}

# Parse arguments
while getopts "qv" opt; do
    case $opt in
        q) QUIET_MODE=1 ;;
        v) VERBOSE=1 ;;
        *) 
            echo "echo \"USAGE: cwd [-q] [-v] username|domain.com/subdir\""
            exit 0
            ;;
    esac
done

shift $((OPTIND-1))

URL="$1"

[[ -z "$URL" ]] && { echo "echo \"USAGE: cwd [-q] [-v] username|domain.com/subdir\""; exit 0; }

# Checks if it is an IP
if [[ "$URL" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    if [[ $QUIET_MODE -eq 0 ]]; then
        echo "echo Cannot look up document root by IP -- must provide domain name or URL."
    else
        echo "echo -n"
    fi
    exit 0
fi

split_url() {
    local url="$1"
    local domain=""
    local uri=""
    
    if [[ "$url" == *"/"* ]]; then
        if [[ ! "$url" =~ ^(ftp|https?):// ]]; then
            if [[ "$url" =~ :// ]]; then
                set_error "Malformed URL. Only ftp, http, and https protocols are accepted"
                return 1
            fi
            url="http://$url"
        fi
        
        local temp="${url#*://}"
        
        if [[ "$temp" == *"/"* ]]; then
            domain="${temp%%/*}"
            uri="/${temp#*/}"
        else
            domain="$temp"
            uri=""
        fi
        
        [[ "$uri" == "/" ]] && uri=""
    else
        domain="$url"
        uri=""
    fi
    
    echo "$domain"
    echo "$uri"
    return 0
}

get_closest_directory() {
    local docroot="$1"
    local uri="$2"
    local count=0
    
    while [[ ! -d "$docroot$uri" && $count -lt 10 && -n "$uri" ]]; do
        uri="${uri%/}"
        uri="${uri%/*}"
        ((count++))
    done
    
    if [[ -d "$docroot$uri" && -n "$uri" ]]; then
        echo "$docroot$uri"
    else
        echo "$docroot"
    fi
}

# NEW FUNCTION: Gets DocumentRoot by username OR domain
get_docroot_smart() {
    local input="$1"
    local docroot=""
    local user=""
    
    # Attempt 1: If input is a valid cPanel user
    if [[ -d "/var/cpanel/userdata/$input" ]]; then
        user="$input"
        
        # Gets the user's main domain
        local main_domain=""
        if [[ -f "/var/cpanel/users/$user" ]]; then
            main_domain=$(grep "^DNS=" "/var/cpanel/users/$user" | head -1 | cut -d= -f2)
        fi
        
        # Attempts documentroot of the main domain
        if [[ -n "$main_domain" && -f "/var/cpanel/userdata/$user/$main_domain" ]]; then
            docroot=$(grep "^documentroot:" "/var/cpanel/userdata/$user/$main_domain" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
        fi
        
        # If not found, tries /home/$user/public_html
        if [[ -z "$docroot" && -d "/home/$user/public_html" ]]; then
            docroot="/home/$user/public_html"
        fi
        
        if [[ -n "$docroot" ]]; then
            echo "$docroot"
            return 0
        fi
    fi
    
    # Attempt 2: Input is a domain (removes www.)
    local domain="${input#www.}"
    
    # Searches in /var/cpanel/userdata/*/
    for user_dir in /var/cpanel/userdata/*/; do
        [[ -d "$user_dir" ]] || continue
        
        user=$(basename "$user_dir")
        
        # Checks each domain file
        for domain_file in "$user_dir"*; do
            [[ -f "$domain_file" ]] || continue
            [[ "$domain_file" == *"_SSL" ]] && continue
            
            local basename_file=$(basename "$domain_file")
            
            # Checks if the file matches the domain
            if [[ "$basename_file" == "$domain" ]]; then
                docroot=$(grep "^documentroot:" "$domain_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                if [[ -n "$docroot" ]]; then
                    echo "$docroot"
                    return 0
                fi
            fi
            
            # Or if servername/serveralias matches
            if grep -qE "^servername: $domain$|^serveralias:.* $domain( |$)" "$domain_file" 2>/dev/null; then
                docroot=$(grep "^documentroot:" "$domain_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                if [[ -n "$docroot" ]]; then
                    echo "$docroot"
                    return 0
                fi
            fi
        done
    done
    
    # Attempt 3: Searches in /etc/userdatadomains
    if [[ -f "/etc/userdatadomains" ]]; then
        local line=$(grep "^$domain:" "/etc/userdatadomains" 2>/dev/null | head -1)
        if [[ -n "$line" ]]; then
            docroot=$(echo "$line" | grep -o 'path=[^[:space:]]*' | cut -d= -f2)
            if [[ -n "$docroot" && -d "$docroot" ]]; then
                echo "$docroot"
                return 0
            fi
        fi
    fi
    
    # Attempt 4: Searches in /var/cpanel/users/ for the domain
    for user_file in /var/cpanel/users/*; do
        [[ -f "$user_file" ]] || continue
        [[ "$(basename "$user_file")" == "nobody" ]] && continue
        
        if grep -qE "^DNS.*=$domain$|^XDNS.*=$domain$" "$user_file" 2>/dev/null; then
            user=$(basename "$user_file")
            
            if [[ -d "/home/$user/public_html/$domain" ]]; then
                echo "/home/$user/public_html/$domain"
                return 0
            elif [[ -d "/home/$user/public_html" ]]; then
                echo "/home/$user/public_html"
                return 0
            fi
        fi
    done
    
    set_error "Could not find document root for '$input' (tried as username and domain)"
    return 1
}

# ========== MAIN EXECUTION ==========

SPLIT_OUTPUT=$(split_url "$URL")
if [[ $? -ne 0 ]]; then
    if [[ $QUIET_MODE -eq 0 ]]; then
        print_error_and_exit "$ERROR_MESSAGE"
    else
        print_quiet_exit
    fi
fi

INPUT=$(echo "$SPLIT_OUTPUT" | sed -n '1p')
URI=$(echo "$SPLIT_OUTPUT" | sed -n '2p')

INPUT=$(echo "$INPUT" | tr '[:upper:]' '[:lower:]')

# Uses the smart function
DOCROOT=$(get_docroot_smart "$INPUT")

if [[ $ERROR_OCCURRED -eq 1 ]]; then
    if [[ $QUIET_MODE -eq 0 ]]; then
        print_error_and_exit "$ERROR_MESSAGE"
    else
        print_quiet_exit
    fi
fi

if [[ -z "$DOCROOT" ]]; then
    if [[ $QUIET_MODE -eq 0 ]]; then
        print_error_and_exit "Could not determine document root"
    else
        print_quiet_exit
    fi
fi

if [[ ! -d "$DOCROOT" ]]; then
    if [[ $QUIET_MODE -eq 0 ]]; then
        print_error_and_exit "Cannot change directory: $DOCROOT does not exist"
    else
        print_quiet_exit
    fi
fi

FINAL_DIR=""

if [[ -n "$URI" && -d "$DOCROOT$URI" ]]; then
    FINAL_DIR="$DOCROOT$URI"
elif [[ -z "$URI" ]]; then
    FINAL_DIR="$DOCROOT"
else
    FINAL_DIR=$(get_closest_directory "$DOCROOT" "$URI")
fi

echo "cd $FINAL_DIR"
exit 0