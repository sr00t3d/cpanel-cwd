#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                                                                           ║
# ║   cPanel Change Working Directory (cp-cwd.sh) v2.0.0                      ║
# ║                                                                           ║
# ╠═══════════════════════════════════════════════════════════════════════════╣
# ║   Autor:   Percio Castelo                                                 ║
# ║   Contato: percio@evolya.com.br | contato@perciocastelo.com.br            ║
# ║   Web:     https://perciocastelo.com.br                                   ║
# ║                                                                           ║
# ║   Função:  Smart SSH navigation wrapper for cPanel/WHM servers. Instantly ║
# ║            resolves document roots by domain or username with subpath     ║
# ║            fallback, shell wrapper installer, and table/json/csv listing. ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

set -uo pipefail
export LC_ALL=C

readonly VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# =============================================================================
# Defaults
# =============================================================================
TARGET=""
MODE="print"            # print | eval | list | install | uninstall
OUTPUT_FORMAT="table"   # table | json | csv
QUIET=false
NO_COLOR=false

# =============================================================================
# Colors
# =============================================================================
C_RESET=""
C_RED=""
C_GREEN=""
C_YELLOW=""
C_CYAN=""
C_DIM=""

init_colors() {
    if [[ "$NO_COLOR" == false && "$OUTPUT_FORMAT" == "table" && -t 1 ]]; then
        C_RESET=$'\033[0m'
        C_DIM=$'\033[2m'
        C_RED=$'\033[0;31m'
        C_GREEN=$'\033[0;32m'
        C_YELLOW=$'\033[0;33m'
        C_CYAN=$'\033[0;36m'
    fi
}

log_info() { [[ "$QUIET" == false ]] && echo -e "${C_CYAN}[→]${C_RESET} $*" >&2; }
log_ok()   { [[ "$QUIET" == false ]] && echo -e "${C_GREEN}[+]${C_RESET} $*" >&2; }
log_warn() { [[ "$QUIET" == false ]] && echo -e "${C_YELLOW}[!]${C_RESET} $*" >&2; }
log_err()  { echo -e "${C_RED}[x] Error:${C_RESET} $*" >&2; }

# =============================================================================
# Help
# =============================================================================
show_help() {
    cat <<EOF
cPanel Change Working Directory (cp-cwd.sh) v${VERSION}
Fast SSH navigation wrapper to jump directly to any cPanel account's DocumentRoot.

Usage:
  ${SCRIPT_NAME} [OPTIONS] <username|domain[/subdir]>
  cwd <username|domain[/subdir]>  (when shell wrapper is installed)

Navigation Options:
  -p, --print              Print the resolved path directly to stdout (default)
  -c, --cd-eval            Output 'cd "/path"' for shell evaluation
  -l, --list               List all domains and their document roots on the server
  -i, --install            Install the 'cwd' helper function to ~/.bashrc
      --uninstall          Remove the 'cwd' helper function from ~/.bashrc

Output & Behavior Options:
  -o, --output <fmt>       Output format: table (default), json, csv (for --list or lookup)
  -q, --quiet              Suppress error messages and hints
      --no-color           Disable ANSI colors
  -V, --version            Show version and exit
  -h, --help               Show this help message and exit

Exit Codes:
  0  Target resolved and directory exists
  1  Target not found, directory missing, or usage error

Examples:
  # Print document root of a domain:
  ${SCRIPT_NAME} example.com

  # Change directory using command substitution:
  cd "\$(${SCRIPT_NAME} example.com)"

  # Jump to a subpath (falls back to closest existing parent directory):
  cd "\$(${SCRIPT_NAME} example.com/wp-content/themes)"

  # Jump by cPanel username:
  cd "\$(${SCRIPT_NAME} cpaneluser)"

  # List all hosted domains and docroots in JSON:
  ${SCRIPT_NAME} -l -o json

  # Install the shell wrapper so you can simply type 'cwd domain.com':
  ${SCRIPT_NAME} --install
EOF
}

# =============================================================================
# Shell Wrapper Management
# =============================================================================
install_wrapper() {
    local script_abs
    script_abs="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    local rc_file="${HOME}/.bashrc"
    local marker="# CWD AUTO-WRAPPER"

    if [[ -f "$rc_file" ]] && grep -q "$marker" "$rc_file" 2>/dev/null; then
        sed -i "/${marker}/,/# END CWD WRAPPER/d" "$rc_file"
    fi

    cat >> "$rc_file" <<EOF

${marker} - Managed by cp-cwd.sh
cwd() {
    local dest
    dest="\$("${script_abs}" -p "\$@" 2>/dev/null)"
    local ec=\$?
    if [[ \$ec -eq 0 && -n "\$dest" && -d "\$dest" ]]; then
        cd "\$dest" || return 1
        echo "[cwd] -> \$dest"
    else
        "${script_abs}" "\$@"
    fi
}
# END CWD WRAPPER
EOF

    log_ok "Shell wrapper installed in: ${rc_file}"
    log_info "Run 'source ~/.bashrc' or open a new terminal to start using the 'cwd' command."
    exit 0
}

uninstall_wrapper() {
    local rc_file="${HOME}/.bashrc"
    local marker="# CWD AUTO-WRAPPER"

    if [[ -f "$rc_file" ]] && grep -q "$marker" "$rc_file" 2>/dev/null; then
        sed -i "/${marker}/,/# END CWD WRAPPER/d" "$rc_file"
        log_ok "Shell wrapper removed from: ${rc_file}"
    else
        log_warn "Shell wrapper not found in: ${rc_file}"
    fi
    exit 0
}

# =============================================================================
# Argument Parser
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--print)            MODE="print"; shift ;;
            -c|--cd-eval)          MODE="eval"; shift ;;
            -l|--list)             MODE="list"; shift ;;
            -i|--install)          MODE="install"; shift ;;
            --uninstall)           MODE="uninstall"; shift ;;
            -o|--output)
                [[ $# -lt 2 ]] && { log_err "$1 requires a format"; exit 1; }
                OUTPUT_FORMAT="$2"; shift 2 ;;
            -q|--quiet)            QUIET=true; shift ;;
            --no-color)            NO_COLOR=true; shift ;;
            -V|--version)          echo "cPanel Change Working Directory v${VERSION}"; exit 0 ;;
            -h|--help)             show_help; exit 0 ;;
            -*)                    log_err "Unknown option: $1 (use --help)"; exit 1 ;;
            *)                     TARGET="$1"; shift ;;
        esac
    done

    case "$OUTPUT_FORMAT" in
        table|json|csv) ;;
        *) log_err "--output must be table, json, or csv"; exit 1 ;;
    esac

    if [[ "$MODE" == "install" ]]; then
        install_wrapper
    elif [[ "$MODE" == "uninstall" ]]; then
        uninstall_wrapper
    fi

    if [[ "$MODE" != "list" && -z "$TARGET" ]]; then
        log_err "Target domain or username is required (use --help for options)."
        exit 1
    fi
}

# =============================================================================
# URL & Path Normalizer
# =============================================================================
split_target() {
    local raw="$1"
    raw="${raw#http://}"
    raw="${raw#https://}"
    raw="${raw#ftp://}"

    local domain=""
    local subpath=""

    if [[ "$raw" == *"/"* ]]; then
        domain="${raw%%/*}"
        subpath="/${raw#*/}"
        subpath="${subpath%/}"
    else
        domain="$raw"
        subpath=""
    fi

    domain="${domain#www.}"
    domain="$(echo "$domain" | tr '[:upper:]' '[:lower:]')"

    echo "$domain"
    echo "$subpath"
}

resolve_closest_dir() {
    local base="$1"
    local sub="$2"

    if [[ -z "$sub" ]]; then
        echo "$base"
        return 0
    fi

    local candidate="${base}${sub}"
    local count=0

    while [[ ! -d "$candidate" && $count -lt 10 && "$candidate" != "$base" && -n "$sub" ]]; do
        sub="${sub%/*}"
        candidate="${base}${sub}"
        ((count++))
    done

    if [[ -d "$candidate" ]]; then
        echo "$candidate"
    else
        echo "$base"
    fi
}

# =============================================================================
# Smart Docroot Resolution
# =============================================================================
resolve_docroot() {
    local input="$1"
    local docroot=""
    local owner=""

    # 1. Direct match in /etc/userdatadomains (fastest lookup on cPanel)
    if [[ -f /etc/userdatadomains ]]; then
        local line
        line=$(awk -F': ' -v d="$input" 'tolower($1) == tolower(d) {print $2; exit}' /etc/userdatadomains 2>/dev/null)
        if [[ -n "$line" ]]; then
            owner=$(echo "$line" | grep -oP '^[a-zA-Z0-9_-]+' || echo "")
            docroot=$(echo "$line" | grep -oP 'path==\K[^=]+' || echo "")
            if [[ -n "$docroot" ]]; then
                echo "${owner}:${docroot}"
                return 0
            fi
        fi
    fi

    # 2. Check /var/cpanel/userdata/<user>/<domain>
    if [[ -d /var/cpanel/userdata ]]; then
        # If input matches an existing cPanel user directory
        if [[ -d "/var/cpanel/userdata/${input}" ]]; then
            owner="$input"
            # Try to get main domain from /var/cpanel/users/$user
            local main_dom=""
            if [[ -f "/var/cpanel/users/${owner}" ]]; then
                main_dom=$(grep -m1 '^DNS=' "/var/cpanel/users/${owner}" 2>/dev/null | cut -d= -f2 | tr -d '[:space:]')
            fi
            if [[ -n "$main_dom" && -f "/var/cpanel/userdata/${owner}/${main_dom}" ]]; then
                docroot=$(grep -m1 '^documentroot:' "/var/cpanel/userdata/${owner}/${main_dom}" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
            fi
            if [[ -z "$docroot" && -d "/home/${owner}/public_html" ]]; then
                docroot="/home/${owner}/public_html"
            fi
            if [[ -n "$docroot" ]]; then
                echo "${owner}:${docroot}"
                return 0
            fi
        fi

        # Iterate user directories looking for the domain file
        for udir in /var/cpanel/userdata/*/; do
            [[ -d "$udir" ]] || continue
            local u
            u=$(basename "$udir")
            [[ "$u" == "nobody" ]] && continue

            local dfile="${udir}${input}"
            if [[ -f "$dfile" ]]; then
                docroot=$(grep -m1 '^documentroot:' "$dfile" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
                if [[ -n "$docroot" ]]; then
                    echo "${u}:${docroot}"
                    return 0
                fi
            fi
        done
    fi

    # 3. Check /var/cpanel/users/* for DNS or XDNS match
    if [[ -d /var/cpanel/users ]]; then
        for ufile in /var/cpanel/users/*; do
            [[ -f "$ufile" ]] || continue
            local u
            u=$(basename "$ufile")
            [[ "$u" == "nobody" ]] && continue

            if grep -qE "^(DNS|XDNS).*=${input}$" "$ufile" 2>/dev/null; then
                owner="$u"
                if [[ -d "/home/${owner}/public_html/${input}" ]]; then
                    echo "${owner}:/home/${owner}/public_html/${input}"
                    return 0
                elif [[ -d "/home/${owner}/public_html" ]]; then
                    echo "${owner}:/home/${owner}/public_html"
                    return 0
                fi
            fi
        done
    fi

    return 1
}

# =============================================================================
# Server-Wide Domain Listing Mode (-l)
# =============================================================================
list_all_domains() {
    python3 - "$OUTPUT_FORMAT" "$NO_COLOR" "$C_RESET" "$C_GREEN" "$C_YELLOW" "$C_RED" <<'PYEOF'
import csv
import json
import os
import re
import sys

fmt, no_col_s, c_rst, c_grn, c_yel, c_red = sys.argv[1:7]
no_col = no_col_s == "true"

results = []

# Source 1: /etc/userdatadomains
if os.path.isfile("/etc/userdatadomains"):
    try:
        with open("/etc/userdatadomains", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line or ":" not in line:
                    continue
                dom, rest = line.split(":", 1)
                dom = dom.strip()
                parts = rest.strip().split("==")
                user = parts[0] if len(parts) > 0 else "-"
                docroot = "-"
                for i in range(len(parts)-1):
                    if parts[i] == "path":
                        docroot = parts[i+1]
                        break
                exists = os.path.isdir(docroot) if docroot != "-" else False
                results.append({
                    "domain": dom,
                    "user": user,
                    "docroot": docroot,
                    "exists": exists
                })
    except Exception:
        pass

# Source 2: /var/cpanel/userdata/*
if not results and os.path.isdir("/var/cpanel/userdata"):
    for u in os.listdir("/var/cpanel/userdata"):
        upath = os.path.join("/var/cpanel/userdata", u)
        if not os.path.isdir(upath) or u == "nobody":
            continue
        for df in os.listdir(upath):
            if df.endswith("_SSL") or df == "main":
                continue
            fpath = os.path.join(upath, df)
            if not os.path.isfile(fpath):
                continue
            docroot = "-"
            try:
                with open(fpath, encoding="utf-8", errors="replace") as fh:
                    for ln in fh:
                        if ln.startswith("documentroot:"):
                            docroot = ln.split(":", 1)[1].strip()
                            break
            except Exception:
                pass
            exists = os.path.isdir(docroot) if docroot != "-" else False
            results.append({
                "domain": df,
                "user": u,
                "docroot": docroot,
                "exists": exists
            })

results.sort(key=lambda x: x["domain"])

if fmt == "json":
    print(json.dumps({"total": len(results), "domains": results}, indent=2))
elif fmt == "csv":
    w = csv.writer(sys.stdout)
    w.writerow(["domain", "user", "docroot", "exists"])
    for r in results:
        w.writerow([r["domain"], r["user"], r["docroot"], r["exists"]])
else:
    print("=" * 110)
    print(f" CPANEL DOMAINS & DOCUMENT ROOTS | Total Hosted: {len(results)}")
    print("=" * 110)
    print(f"{'DOMAIN':<32} | {'USER':<14} | {'STATUS':<8} | {'DOCUMENT ROOT'}")
    print("-" * 110)
    for r in results:
        st = "FOUND" if r["exists"] else "MISSING"
        col = c_grn if r["exists"] else c_red
        print(f"{r['domain'][:32]:<32} | {r['user'][:14]:<14} | {col}{st:<8}{c_rst} | {r['docroot']}")
    print("=" * 110)
    print(f" Total: {len(results)} domain(s) indexed")
    print("=" * 110)
PYEOF
}

# =============================================================================
# Execution Engine
# =============================================================================
execute_lookup() {
    local parts
    parts=$(split_target "$TARGET")
    local domain subpath
    domain=$(echo "$parts" | sed -n '1p')
    subpath=$(echo "$parts" | sed -n '2p')

    local resolved
    if ! resolved=$(resolve_docroot "$domain"); then
        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            echo "{\"target\":\"${TARGET}\",\"status\":\"NOT_FOUND\",\"error\":\"Could not resolve document root for '${domain}'\"}"
        elif [[ "$QUIET" == false ]]; then
            log_err "Could not find document root for '${TARGET}' (tried username, domain, and userdata)."
        fi
        exit 1
    fi

    local owner docroot final_path
    owner="${resolved%%:*}"
    docroot="${resolved#*:}"
    final_path=$(resolve_closest_dir "$docroot" "$subpath")

    if [[ ! -d "$final_path" ]]; then
        if [[ "$OUTPUT_FORMAT" == "json" ]]; then
            echo "{\"target\":\"${TARGET}\",\"user\":\"${owner}\",\"docroot\":\"${final_path}\",\"status\":\"DIR_MISSING\",\"exists\":false}"
        elif [[ "$QUIET" == false ]]; then
            log_err "Resolved document root directory does not exist: ${final_path}"
        fi
        exit 1
    fi

    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        cat <<EOF
{
  "target": "${TARGET}",
  "user": "${owner}",
  "domain": "${domain}",
  "subpath": "${subpath}",
  "docroot": "${final_path}",
  "exists": true,
  "status": "OK"
}
EOF
    elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        echo "target,user,domain,docroot,exists"
        echo "${TARGET},${owner},${domain},${final_path},true"
    elif [[ "$MODE" == "eval" ]]; then
        echo "cd \"${final_path}\""
    else
        echo "$final_path"
    fi

    exit 0
}

# =============================================================================
# Main
# =============================================================================
main() {
    parse_args "$@"
    init_colors

    if [[ "$MODE" == "list" ]]; then
        list_all_domains
        exit 0
    fi

    execute_lookup
}

main "$@"
