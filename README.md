# cPanel Change Working Directory

Readme: [BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/cpanel-cwd) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" src="cpanel-cwd-cover.webp" />

> **Bash rewrite of the original Perl cwd utility by Robert West (HostGator)**

A smart Bash script to quickly change to the document root of cPanel accounts. Accepts both **usernames** and **domain names**, with auto-installation of shell wrapper.

## About

This project is a **Bash rewrite** of the original Perl script `cwd` created by **Robert West** at HostGator. The original script used cPanel's XML API to fetch document roots, but required authentication and running cPanel services.

### Why a Bash Rewrite?

- **No API dependency** - Reads directly from cPanel files
- **Works offline** - No need for cPanel services to be running
- **Smarter matching** - Accepts username OR domain name
- **Auto-installation** - Installs shell wrapper automatically
- **No Perl modules** - Pure Bash, no dependencies

## Original Reference

```perl
#!/usr/bin/perl
#
# SCRIPT NAME: cwd (Change Working Directory / Change to Web DocumentRoot / Cobras Work Diligently)
#
# DESCRIPTION:
#	On cPanel servers, cwd will change the console's working directory into the
#	DocumentRoot of the domain specified.
#
# USAGE:
#	[root@gator1337 ~]# cwd gator.com
#	[root@gator1337 /home/gator/public_html/]# 
#
# URL TO WIKI: /Admin/CWD 
# URL TO GIT: /cwd
# MAINTAINER: Robert West
#
# (C) 2012 - HostGator.com, LLC
```

**Original Author**: Robert West (HostGator)  
**Original Date**: 2012  
**Original Version**: 0.3.4  
**Original Purpose**: Quick navigation to cPanel account document roots

## Features

| Feature | Description | Original | This Version |
|---------|-------------|----------|--------------|
| Change to docroot | Navigate to account public_html | ✅ | ✅ |
| Username support | Accept cPanel username | ❌ | ✅ |
| Domain support | Accept domain name | ✅ | ✅ |
| Subdirectory support | Navigate to subdirs if exist | ✅ | ✅ |
| Auto-install wrapper | Install function in .bashrc | ❌ | ✅ |
| No API required | Read files directly | ❌ | ✅ |
| Works offline | No cPanel services needed | ❌ | ✅ |
| Quiet mode | Suppress error messages | ✅ | ✅ |
| Verbose mode | Detailed error messages | ✅ | ✅ |

## Requirements

- **Bash** 4.0+
- **cPanel/WHM** server (reads `/var/cpanel/userdata/`)
- Root or sudo access
- Standard Unix tools: `grep`, `sed`, `cut`

## Installation

### Automatic (Recommended)

Simply run the script once - it will auto-install the wrapper:

```bash
# Download and make executable
curl -O https://raw.githubusercontent.com/sr00t3d/cpanel-cwd/refs/heads/main/cwd.sh
chmod +x cwd.sh

# Run once to install wrapper
./cwd.sh any-domain.com

# Output:
# CWD wrapper installed in .bashrc
# Run 'source ~/.bashrc' or login again to use 'cwd' command
```

### Manual Function

Add to your `~/.bashrc`:

```bash
cwd() {
    local output
    output=$("/path/to/cwd.sh" "$@" 2>&1)
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        eval "$output"
    else
        echo "$output" | sed 's/^echo "//; s/"$//'
    fi
}
```

Then reload:
```bash
source ~/.bashrc
```

## Usage

```bash
cwd [OPTIONS] username|domain[/subdir]
```

### Arguments

| Argument | Description | Examples |
|----------|-------------|----------|
| `username` | cPanel account username, example | `linux`, `domain123` |
| `domain` | Domain name (with or without www), example | `linux.com`, `www.example.com` |
| `/subdir` | Optional subdirectory path, example | `/blog`, `/wp-admin` |

### Options

| Option | Description |
|--------|-------------|
| `-q` | Quiet mode - suppress error messages |
| `-v` | Verbose mode - show detailed errors |
| `-h` | Show help |

## Examples

### By Username

```bash
[root@vps ~]# cwd linux
[root@vps public_html]# pwd
/home/linux/public_html
```

### By Domain Name

```bash
[root@vps ~]# cwd linux.com
[root@vps public_html]# pwd
/home/linux/public_html
```

### With Subdirectory

```bash
[root@vps ~]# cwd linux.com/blog
[root@vps blog]# pwd
/home/linux/public_html/blog
```

### With Subdomain

```bash
[root@vps ~]# cwd forum.linux.com
[root@vps blog]# pwd
/home/linux/public_html/blog

### Subdirectory Fallback

If subdirectory doesn't exist, goes to closest parent:

```bash
[root@vps ~]# cwd linux.com/nonexistent/deep/path
[root@vps public_html]# pwd
/home/linux/public_html
```

### Quiet Mode (for scripts)

```bash
[root@vps ~]# cwd -q nonexistentuser
[root@vps ~]#  # No error message shown
```

### Verbose Mode (debugging)

```bash
[root@vps ~]# cwd -v wrongdomain.com
Could not find document root for 'wrongdomain.com' (tried as username and domain)
```

## How It Works

### Search Order

The script tries to find the document root in this order:

1. **Username match** - Checks if input is a cPanel user in `/var/cpanel/userdata/`
2. **Domain file match** - Looks for exact domain file in userdata
3. **ServerName/Alias match** - Searches servername and serveralias fields
4. **userdata domains index** - Checks `/etc/userdatadomains`
5. **DNS field match** - Searches `/var/cpanel/users/` for domain association

### File Locations Read

| File/Directory | Purpose |
|----------------|---------|
| `/var/cpanel/userdata/$user/$domain` | Per-domain configuration |
| `/var/cpanel/users/$user` | User account info (DNS= fields) |
| `/etc/userdatadomains` | Domain-to-path index |
| `/home/$user/public_html` | Default document root fallback |

### The Wrapper Trick

The script uses a bash trick to change the **current shell's** directory:

```bash
# Script outputs:
cd /home/user/public_html

# Wrapper evaluates:
eval "$(cwd.sh domain.com)"
```

Without this, `cd` would only change the directory in a subshell.

## Comparison with Original

| Aspect | Perl Original | Bash Version |
|--------|---------------|--------------|
| API used | cPanel XML-API (port 2086) | Direct file reading |
| Authentication | WHM access hash required | No authentication |
| Dependencies | LWP::UserAgent, XML::Simple, HTTP::Request | Standard Unix tools |
| Username input | No | Yes |
| Offline operation | No | Yes |
| cPanel services | Must be running | Not required |
| Speed | Slower (HTTP request) | Instant (file read) |

## Troubleshooting

### "cwd: command not found"

```bash
# Wrapper not loaded, source it:
source ~/.bashrc

# Or run directly once to install:
./cwd.sh any-domain.com
```

### "Could not determine document root"

- Domain doesn't exist on server
- Username doesn't exist
- cPanel files are corrupted or missing

Debug with:
```bash
# Check if user exists
ls /var/cpanel/userdata/username

# Check domain files
ls /var/cpanel/userdata/username/domain.com

# Check documentroot in file
grep documentroot /var/cpanel/userdata/username/domain.com
```

### Wrapper keeps reinstalling

Check if multiple installations exist:
```bash
grep -n "CWD AUTO-WRAPPER" ~/.bashrc
```

Clean and reinstall:
```bash
sed -i '/# CWD AUTO-WRAPPER/,/# END CWD WRAPPER/d' ~/.bashrc
./cwd.sh domain.com  # Reinstalls once
source ~/.bashrc
```

**Tip**: Add `alias c='cwd'` to your `.bashrc` for even faster navigation!

## Important Notes

1. **Requires root** - Must read `/var/cpanel/` files
2. **Bash only** - Does not work in `sh` or `zsh` without modification
3. **cPanel specific** - Designed for cPanel/WHM servers
4. **First run** - Installs wrapper, may need `source ~/.bashrc` after

## Credits

- **Original Author**: Robert West (HostGator)
- **Original Date**: 2012
- **Original Version**: 0.3.4
- **Bash Rewrite**: 2026
- **Purpose**: System administration tool for cPanel/WHM servers

## 🔗 Links

- Original HostGator Wiki: `https://gatorwiki.hostgator.com/Admin/CWD`
- Original Repository: `http://git.toolbox.hostgator.com/cwd`

## Legal Notice

> [!WARNING]
> This software is provided "as is." Always ensure you have explicit permission before executing it. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

## Detailed Tutorial

For a complete, step-by-step guide, check out my full article:

👉 [**Fast navigation directy cPanel**](https://perciocastelo.com.br/blog/fast-navigation-directory-cpanel.html)

## License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for more details.

---

**Note**: This is an unofficial rewrite and not supported/sponsored by HostGator.