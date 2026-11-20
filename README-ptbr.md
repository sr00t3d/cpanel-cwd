# cPanel Change Working Directory (`cp-cwd.sh`)

![Capa do cPanel Change Working Directory](./cpanel-cwd-cover.webp)

[![Versão](https://img.shields.io/badge/version-2.0.0-blue.svg)](./cp-cwd.sh)
[![Licença](https://img.shields.io/badge/license-Apache--2.0-green.svg)](./LICENSE)
[![Plataforma](https://img.shields.io/badge/platform-Linux%20%7C%20cPanel%20%2F%20WHM-orange.svg)](#requisitos)

> 🇺🇸 **[Read in English (README.md)](./README.md)**

O **cPanel Change Working Directory** (`cp-cwd.sh` v2.0.0) é uma ferramenta CLI em Bash e wrapper de navegação SSH para servidores cPanel/WHM. Ele resolve instantaneamente o DocumentRoot de qualquer conta através do nome de domínio ou usuário (incluindo domínios adicionais, subdomínios e subdiretórios com fallback), eliminando buscas manuais e acelerando o dia a dia do SysAdmin.

Inspirado no utilitário original em Perl `cwd` desenvolvido por Robert West na HostGator (2012).

---

## Funcionalidades

- **Resolução por Domínio ou Usuário:** Aceita nome de usuário cPanel, domínio principal, domínio adicional ou subdomínio.
- **Fallback Inteligente de Subdiretórios:** Suporta caminhos como `example.com/wp-content/themes` e retorna o diretório pai mais próximo caso a subpasta não exista.
- **Zero Dependência de API:** Lê diretamente dos arquivos locais do cPanel (`/etc/userdatadomains`, `/var/cpanel/userdata/`, `/var/cpanel/users/`) — funciona mesmo durante incidentes ou paradas de serviço.
- **Instalador de Wrapper Opcional (`-i, --install`):** Instala a função auxiliar `cwd` de forma limpa e idempotente no `~/.bashrc`.
- **Listagem Global do Servidor (`-l, --list`):** Varre e exibe todos os domínios hospedados, usuários donos, docroots e integridade de pastas em `table`, `json` ou `csv`.
- **Pronto para Automação:** Modos de saída em caminho direto (`-p`), comando de shell (`-c`) ou JSON (`-o json`) com exit code semântico `0` em sucesso e `1` em falha.

---

## Requisitos

- Linux com Bash 4.0+ e Python 3.6+
- Servidor cPanel & WHM com acesso de leitura a `/etc/userdatadomains` ou `/var/cpanel/`

---

## Instalação

```bash
git clone https://github.com/sr00t3d/cpanel-cwd.git
cd cpanel-cwd
chmod +x cp-cwd.sh

# Instalar a função auxiliar 'cwd' no ~/.bashrc:
./cp-cwd.sh --install
source ~/.bashrc
```

---

## Como usar

```bash
# Imprimir o caminho direto do document root:
./cp-cwd.sh example.com

# Navegar usando substituição de comando:
cd "$(./cp-cwd.sh example.com)"

# Pular direto para um subdiretório (com fallback inteligente):
cd "$(./cp-cwd.sh example.com/blog/uploads)"

# Navegar pelo usuário cPanel:
cd "$(./cp-cwd.sh cpaneluser)"

# Listar todos os domínios hospedados no servidor:
./cp-cwd.sh -l

# Exportar todos os domínios e caminhos em JSON:
./cp-cwd.sh -l -o json > server-docroots.json

# Uso via wrapper (após --install):
cwd example.com
cwd meudominio.com.br/wp-admin
```

### Opções da CLI

| Opção | Descrição |
| :--- | :--- |
| `<alvo>` | Domínio ou usuário cPanel (com `/subcaminho` opcional) |
| `-p, --print` | Imprime o caminho resolvido diretamente na tela (padrão) |
| `-c, --cd-eval` | Emite `cd "/caminho"` para avaliação em shell |
| `-l, --list` | Lista todos os domínios hospedados no servidor |
| `-i, --install` | Instala a função `cwd` no `~/.bashrc` |
| `--uninstall` | Remove a função `cwd` do `~/.bashrc` |
| `-o, --output <fmt>` | Formato de saída: `table` (padrão), `json`, `csv` |
| `-q, --quiet` | Suprime mensagens de erro e dicas |
| `--no-color` | Desativa cores ANSI |
| `-V, --version` | Exibe a versão e encerra |
| `-h, --help` | Exibe a ajuda e encerra |

---

## Exemplo de Saída Real

Capturado em container AlmaLinux 8.10 / cPanel listando domínios (`-l`) e resolvendo subcaminhos:

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

## Licença

Distribuído sob a [Licença Apache-2.0](./LICENSE). Inspirado no utilitário original em Perl `cwd` de Robert West (HostGator, 2012).
