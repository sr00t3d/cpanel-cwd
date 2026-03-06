# cPanel Change Working Directory

Leia-me: [EN](README.md)

![Licença](https://img.shields.io/github/license/sr00t3d/cpanel-cwd) ![Script Shell](https://img.shields.io/badge/language-Bash-green.svg)

<img width="700" src="cpanel-cwd-cover.webp" />

> **Reescrita em Bash do utilitário cwd original em Perl por Robert West (HostGator)**

Um script inteligente em Bash para mudar rapidamente para o document root de contas cPanel. Aceita tanto **nomes de usuário** quanto **nomes de domínio**, com instalação automática do wrapper de shell.

## Sobre

Este projeto é uma **reescrita em Bash** do script original em Perl `cwd` criado por **Robert West** na HostGator. O script original usava a API XML do cPanel para buscar os document roots, mas exigia autenticação e serviços do cPanel em execução.

### Por que uma Reescrita em Bash?

- **Sem dependência de API** - Lê diretamente dos arquivos do cPanel
- **Funciona offline** - Não precisa que os serviços do cPanel estejam em execução
- **Correspondência mais inteligente** - Aceita nome de usuário OU nome de domínio
- **Instalação automática** - Instala o wrapper de shell automaticamente
- **Sem módulos Perl** - Bash puro, sem dependências

## Referência Original

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

**Autor Original**: Robert West (HostGator)  
**Data Original**: 2012  
**Versão Original**: 0.3.4  
**Propósito Original**: Navegação rápida para document roots de contas cPanel

## Recursos

| Recurso | Descrição | Original | Esta Versão |
|---------|-----------|----------|-------------|
| Ir para docroot | Navegar para public_html da conta | ✅ | ✅ |
| Suporte a usuário | Aceita usuário do cPanel | ❌ | ✅ |
| Suporte a domínio | Aceita nome de domínio | ✅ | ✅ |
| Suporte a subdiretório | Navega para subdirs se existirem | ✅ | ✅ |
| Auto-instalar wrapper | Instala função no .bashrc | ❌ | ✅ |
| Sem API necessária | Lê arquivos diretamente | ❌ | ✅ |
| Funciona offline | Sem necessidade de serviços do cPanel | ❌ | ✅ |
| Modo silencioso | Suprime mensagens de erro | ✅ | ✅ |
| Modo verboso | Mensagens de erro detalhadas | ✅ | ✅ |

## Requisitos

- **Bash** 4.0+
- Servidor **cPanel/WHM** (lê `/var/cpanel/userdata/`)
- Acesso root ou sudo
- Ferramentas Unix padrão: `grep`, `sed`, `cut`

## Instalação

### Automática (Recomendada)

Basta executar o script uma vez - ele instalará automaticamente o wrapper:

```bash
# Baixar e tornar executável
curl -O https://raw.githubusercontent.com/sr00t3d/cpanel-cwd/refs/heads/main/cp-cwd.sh
chmod +x cp-cwd.sh

# Executar uma vez para instalar o wrapper
./cp-cwd.sh any-domain.com

# Saída:
# CWD wrapper instalado no .bashrc
# Execute 'source ~/.bashrc' ou faça login novamente para usar o comando 'cwd'
```

### Função Manual

Adicione ao seu `~/.bashrc`:

```bash
cwd() {
    local output
    output=$("/path/to/cp-cwd.sh" "$@" 2>&1)
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        eval "$output"
    else
        echo "$output" | sed 's/^echo "//; s/"$//'
    fi
}
```

Depois recarregue:
```bash
source ~/.bashrc
```

## Uso

```bash
cwd [OPÇÕES] usuario|dominio[/subdir]
```

### Argumentos

| Argumento | Descrição | Exemplos |
|-----------|-----------|----------|
| `username` | Nome de usuário da conta cPanel, exemplo | `linux`, `domain123` |
| `domain` | Nome de domínio (com ou sem www), exemplo | `linux.com`, `www.example.com` |
| `/subdir` | Caminho opcional de subdiretório, exemplo | `/blog`, `/wp-admin` |

### Opções

| Opção | Descrição |
|-------|-----------|
| `-q` | Modo silencioso - suprime mensagens de erro |
| `-v` | Modo verboso - mostra erros detalhados |
| `-h` | Mostrar ajuda |

## Exemplos

### Por Nome de Usuário

```bash
[root@vps ~]# cwd linux
[root@vps public_html]# pwd
/home/linux/public_html
```

### Por Nome de Domínio

```bash
[root@vps ~]# cwd linux.com
[root@vps public_html]# pwd
/home/linux/public_html
```

### Com Subdiretório

```bash
[root@vps ~]# cwd linux.com/blog
[root@vps blog]# pwd
/home/linux/public_html/blog
```

### Com Subdomínio

```bash
[root@vps ~]# cwd forum.linux.com
[root@vps blog]# pwd
/home/linux/public_html/blog
```

### Fallback de Subdiretório

Se o subdiretório não existir, vai para o pai mais próximo:

```bash
[root@vps ~]# cwd linux.com/nonexistent/deep/path
[root@vps public_html]# pwd
/home/linux/public_html
```

### Modo Silencioso (para scripts)

```bash
[root@vps ~]# cwd -q nonexistentuser
[root@vps ~]#  # Nenhuma mensagem de erro exibida
```

### Modo Verboso (depuração)

```bash
[root@vps ~]# cwd -v wrongdomain.com
Não foi possível encontrar o document root para 'wrongdomain.com' (tentado como usuário e domínio)
```

## Como Funciona

### Ordem de Busca

O script tenta encontrar o document root nesta ordem:

1. **Correspondência por usuário** - Verifica se a entrada é um usuário cPanel em `/var/cpanel/userdata/`
2. **Correspondência de arquivo de domínio** - Procura arquivo de domínio exato em userdata
3. **Correspondência ServerName/Alias** - Pesquisa nos campos servername e serveralias
4. **Índice userdata domains** - Verifica `/etc/userdatadomains`
5. **Correspondência de campo DNS** - Pesquisa em `/var/cpanel/users/` por associação de domínio

### Locais de Arquivos Lidos

| Arquivo/Diretório | Finalidade |
|-------------------|------------|
| `/var/cpanel/userdata/$user/$domain` | Configuração por domínio |
| `/var/cpanel/users/$user` | Informações da conta do usuário (campos DNS=) |
| `/etc/userdatadomains` | Índice domínio-para-caminho |
| `/home/$user/public_html` | Fallback padrão de document root |

### O Truque do Wrapper

O script usa um truque do bash para alterar o diretório do **shell atual**:

```bash
# O script gera:
cd /home/user/public_html

# O wrapper avalia:
eval "$(cp-cwd.sh domain.com)"
```

Sem isso, `cd` mudaria apenas o diretório em um subshell.

## Comparação com o Original

| Aspecto | Original em Perl | Versão em Bash |
|---------|------------------|----------------|
| API usada | cPanel XML-API (porta 2086) | Leitura direta de arquivos |
| Autenticação | Access hash do WHM necessário | Sem autenticação |
| Dependências | LWP::UserAgent, XML::Simple, HTTP::Request | Ferramentas Unix padrão |
| Entrada de usuário | Não | Sim |
| Operação offline | Não | Sim |
| Serviços cPanel | Devem estar em execução | Não necessário |
| Velocidade | Mais lento (requisição HTTP) | Instantâneo (leitura de arquivo) |

## Solução de Problemas

### "cwd: comando não encontrado"

```bash
# Wrapper não carregado, execute:
source ~/.bashrc

# Ou execute diretamente uma vez para instalar:
./cp-cwd.sh any-domain.com
```

### "Não foi possível determinar o document root"

- O domínio não existe no servidor
- O usuário não existe
- Arquivos do cPanel estão corrompidos ou ausentes

Depure com:
```bash
# Verifique se o usuário existe
ls /var/cpanel/userdata/username

# Verifique arquivos do domínio
ls /var/cpanel/userdata/username/domain.com

# Verifique documentroot no arquivo
grep documentroot /var/cpanel/userdata/username/domain.com
```

### O wrapper continua reinstalando

Verifique se existem múltiplas instalações:
```bash
grep -n "CWD AUTO-WRAPPER" ~/.bashrc
```

Limpe e reinstale:
```bash
sed -i '/# CWD AUTO-WRAPPER/,/# END CWD WRAPPER/d' ~/.bashrc
./cp-cwd.sh domain.com  # Reinstala uma vez
source ~/.bashrc
```

**Dica**: Adicione `alias c='cwd'` ao seu `.bashrc` para navegação ainda mais rápida!

## Notas Importantes

1. **Requer root** - Precisa ler arquivos em `/var/cpanel/`
2. **Apenas Bash** - Não funciona em `sh` ou `zsh` sem modificação
3. **Específico para cPanel** - Projetado para servidores cPanel/WHM
4. **Primeira execução** - Instala o wrapper, pode exigir `source ~/.bashrc` depois

## Créditos

- **Autor Original**: Robert West (HostGator)
- **Data Original**: 2012
- **Versão Original**: 0.3.4
- **Reescrita em Bash**: 2026
- **Propósito**: Ferramenta de administração de sistemas para servidores cPanel/WHM

## Links

- Wiki Original da HostGator: `https://gatorwiki.hostgator.com/Admin/CWD`
- Repositório Original: `http://git.toolbox.hostgator.com/cwd`

## Aviso Legal

> [!WARNING]
> Este software é fornecido "como está". Sempre garanta que você tem permissão explícita antes de executá-lo. O autor não é responsável por qualquer uso indevido, consequências legais ou impacto em dados causado por esta ferramenta.

## Tutorial Detalhado

Para um guia completo passo a passo, confira meu artigo completo:

👉 [**Navegação rápida direta no cPanel**](https://perciocastelo.com.br/blog/fast-navigation-directory-cpanel.html)

## Licença

Este projeto está licenciado sob a **GNU General Public License v3.0**. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Nota**: Esta é uma reescrita não oficial e não suportada/patrocinada pela HostGator.