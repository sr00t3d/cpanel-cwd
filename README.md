# cPanel Change Working Directory (`cp-cwd.sh`)

![cPanel Change Working Directory Cover](./cpanel-cwd-cover.webp)

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](./cp-cwd.sh)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel%20%2F%20WHM-orange.svg)](#requirements)

> 🇧🇷 **[Leia em Português (README-ptbr.md)](./README-ptbr.md)**

**cPanel Change Working Directory** (`cp-cwd.sh` v2.0.0) is a fast Bash CLI navigation tool and shell wrapper for cPanel/WHM servers. It instantly resolves any account's DocumentRoot by domain or username (including addon domains, subdomains, and nested subpaths with fallback), eliminating manual lookups and navigation delays.

Inspired by the original Perl `cwd` utility created by Robert West at HostGator (2012).

---

## Features

- **Domain or Username Resolution:** Accepts cPanel username, primary domain, addon domain, or subdomain.
- **Smart Subpath Fallback:** Supports paths like `example.com/wp-content/themes` and gracefully falls back to the closest existing directory if the target subfolder does not exist.
- **Zero API Dependency:** Reads directly from cPanel local files (`/etc/userdatadomains`, `/var/cpanel/userdata/`, `/var/cpanel/users/`) — works even during API outages.
- **Opt-in Shell Wrapper (`-i, --install`):** Idempotently installs a clean `cwd` helper function to `~/.bashrc` so you can jump between accounts with `cwd domain.com`.
- **Server-Wide Domain Listing (`-l, --list`):** Scans and displays all hosted domains, owners, docroots, and folder health in aligned `table`, `json`, or `csv`.
- **Scriptable Modes:** Outputs raw path (`-p`), eval command (`-c`), or JSON (`-o json`) with semantic exit code `0` on resolution and `1` on missing targets.

---

## Requirements

- Linux with Bash 4.0+ and Python 3.6+
- cPanel & WHM server with read access to `/etc/userdatadomains` or `/var/cpanel/`

---

## Installation

```bash
git clone https://github.com/sr00t3d/cpanel-cwd.git
cd cpanel-cwd
chmod +x cp-cwd.sh

# Install the optional 'cwd' helper function to ~/.bashrc:
./cp-cwd.sh --install
source ~/.bashrc
```

---

## Usage

```bash
# Print document root directly:
./cp-cwd.sh example.com

# Change directory using command substitution:
cd "$(./cp-cwd.sh example.com)"

# Jump to subpath (with automatic closest-parent fallback):
cd "$(./cp-cwd.sh example.com/blog/uploads)"

# Jump by cPanel account username:
cd "$(./cp-cwd.sh cpaneluser)"

# List all hosted domains on the server:
./cp-cwd.sh -l

# Export all server domains and docroots to JSON:
./cp-cwd.sh -l -o json > server-docroots.json

# Shell wrapper usage (after --install):
cwd example.com
cwd mydomain.com/wp-admin
```

### CLI Options

| Flag | Description |
| :--- | :--- |
| `<target>` | Domain or username (with optional `/subpath`) |
| `-p, --print` | Print resolved path directly to stdout (default) |
| `-c, --cd-eval` | Output `cd "/path"` for shell evaluation |
| `-l, --list` | List all hosted domains and docroots on the server |
| `-i, --install` | Install `cwd` shell function to `~/.bashrc` |
| `--uninstall` | Remove `cwd` shell function from `~/.bashrc` |
| `-o, --output <fmt>` | Output format: `table` (default), `json`, `csv` |
| `-q, --quiet` | Suppress error messages and hints |
| `--no-color` | Disable ANSI colors |
| `-V, --version` | Show version and exit |
| `-h, --help` | Show help message and exit |

---

## Real Output Example

Captured on an AlmaLinux 8.10 / cPanel test container running domain listing (`-l`) and subpath lookups:

```text
==============================================================================================================
 CPANEL DOMAINS & DOCUMENT ROOTS | Total Hosted: 3
==============================================================================================================
DOMAIN                           | USER           | STATUS   | DOCUMENT ROOT
--------------------------------------------------------------------------------------------------------------
blog.mygator.com                 | gatoruser      | FOUND    | /home/gatoruser/public_html/blog
clientdemo.org                   | clientdemo     | FOUND    | /home/clientdemo/public_html
mygator.com                      | gatoruser      | FOUND    | /home/gatoruser/public_html
==============================================================================================================
 Total: 3 domain(s) indexed
==============================================================================================================

$ ./cp-cwd.sh mygator.com/blog
/home/gatoruser/public_html/blog

$ ./cp-cwd.sh -c clientdemo.org
cd "/home/clientdemo/public_html"
```

---

## License

Licensed under the [Apache-2.0 License](./LICENSE). Inspired by the original Perl `cwd` utility by Robert West (HostGator, 2012).
