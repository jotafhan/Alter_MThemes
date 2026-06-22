# Alter_MThemes

Customizador de tema para **EmulationStation** rodando em **DarkOS** no **R36S**, via interface `dialog`/ncurses (TUI) navegável 100% por D-pad, sem necessidade de teclado físico.

> Versão atual: `7.0.1`

---

## Sumário

- [Visão geral](#visão-geral)
- [Requisitos](#requisitos)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Arquitetura](#arquitetura)
- [Caminhos e diretórios usados](#caminhos-e-diretórios-usados)
- [Módulos](#módulos)
- [Fluxo de execução](#fluxo-de-execução)
- [Validação e segurança do XML](#validação-e-segurança-do-xml)
- [Convenções de retorno do dialog](#convenções-de-retorno-do-dialog)
- [Atualização remota](#atualização-remota)
- [Instalação](#instalação)
- [Convenções de contribuição](#convenções-de-contribuição)

---

## Visão geral

O Alter_MThemes edita diretamente o `theme.xml` do tema ativo do EmulationStation (fontes, cores, wallpaper, logos, etc.), mantém backups versionados com checagem de integridade, e oferece um editor de aparência para o próprio menu do aplicativo (cores ANSI, layout, fonte do console).

Todo o aplicativo é construído sobre `dialog` (ncurses), pensado para a tela pequena e o D-pad do R36S — não há campos de texto livre; tudo é navegação por listas e seletores de caractere.

## Requisitos

Pacotes/binários usados pelo projeto (devem estar disponíveis no sistema DarkOS):

| Binário | Uso |
|---|---|
| `dialog` | toda a interface (ncurses) |
| `wget` | download de packs de logos, overlays e atualizações |
| `unzip` / `zip` | extração de packs e backup completo do tema (.zip) |
| `convert` (ImageMagick) | geração de gradiente e blur de wallpaper |
| `git` | atualização de temas que sejam repositórios git |
| `md5sum` | checagem de integridade dos backups |
| `setfont` | alteração do tamanho da fonte do console (TTY) |
| `iconv` | validação de encoding do XML |
| `gptokeyb` | mapeamento do D-pad/botões para teclado (específico do ambiente ArkOS/ROCKNIX) |
| `systemctl` | reinício do serviço do EmulationStation |

Execução exige privilégio de root (o script se reexecuta via `sudo` automaticamente caso não esteja).

## Estrutura do projeto

```
Alter_MThemes/
├── Alter_MThemes.sh          # entry point — menu principal e loop
└── lib/
    ├── core.sh                # funções base (dialog wrappers, ESCDELAY, ExitAll)
    ├── init.sh                # detecção do tema ativo, backup automático ao abrir
    ├── validator.sh           # validação automática do XML antes de salvar
    ├── cat_1_font_studio.sh   # fontes (cor, tamanho, estilo, família, espaçamento)
    ├── cat_2_visual_studio.sh # wallpaper, scanlines, cores, opacidade, gradiente, blur, glow
    ├── cat_3_logo_center.sh   # logos por sistema (trocar, alinhar, packs online)
    ├── cat_4_theme_hub.sh     # temas prontos (paletas completas pré-definidas)
    ├── cat_5_backup_center.sh # backup/restore do theme.xml, histórico, agendamento
    ├── cat_6_interface_ui.sh  # aparência do próprio menu do Alter_MThemes
    ├── cat_7_atualizador.sh   # checagem e instalação de atualizações via GitHub
    ├── menu_aparencia.cfg     # config persistida do módulo 6 (cores/layout do menu)
    ├── menu_dialogrc          # DIALOGRC gerado a partir do menu_aparencia.cfg
    └── version.txt            # versão local, comparada com o repositório remoto
```

> **Nota de numeração:** o número no nome do arquivo (`cat_N_*.sh`) corresponde 1:1 à `CATEGORIA`/função interna (`categoria_N`). Isso é mantido propositalmente em sincronia — ao adicionar, remover ou reordenar módulos, todos os pontos abaixo precisam ser atualizados juntos:
> - array `MODULOS` em `Alter_MThemes.sh`
> - itens do `--menu` principal e o `case "$ITEM_SEL"` em `Alter_MThemes.sh`
> - nome da função `categoria_N()` e a checagem `if [ "$CATEGORIA" = "N" ]` dentro do próprio módulo (quando aplicável)
> - lista `ARQUIVOS_ATUALIZAVEIS` em `cat_7_atualizador.sh`

## Arquitetura

- **Bash puro**, sem dependências de linguagem externa.
- Cada módulo de categoria (`cat_N_*.sh`) é **`source`ado** no processo principal (`Alter_MThemes.sh`) e expõe uma função `categoria_N()` chamada pelo loop do menu.
- O XML do tema (`$XML_FILE`) é editado via `sed`/`awk` diretamente — sem parser XML. As edições são sempre escopadas a blocos específicos (`<background>`, `<carousel>`, `<textlist name="gamelist">`, `<menuText>`, etc.) para evitar que uma cor de texto, por exemplo, vaze para o background.
- Toda alteração visual oferece **reinício do EmulationStation** ao final (`PerguntarReiniciar`), nunca forçado.

## Caminhos e diretórios usados

| Variável | Caminho padrão | Conteúdo |
|---|---|---|
| `BACKUP_DIR` | `/home/ark/darkos_backups` | backups do `theme.xml`, histórico, flags de automação |
| `WALLPAPER_DIR` | `/home/ark/darkos_wallpapers` | imagens de fundo do usuário |
| `FONT_DIR` | `/home/ark/darkos_fonts` | fontes `.ttf`/`.otf` instaladas pelo usuário + favoritos |
| `LOGOS_DIR` | `/home/ark/darkos_logos` | logos de sistemas baixados/instalados |
| `LOGOS_BAK_DIR` | `/home/ark/darkos_backups/logos` | backups de logos e packs |
| `$XML_FILE` | detectado dinamicamente | `theme.xml` do tema ativo (ver `init.sh`) |

Detecção do tema ativo (`init.sh`): lê `ThemeSet` em `es_settings.cfg` (`/var/local/emulationstation/` ou `/home/ark/.emulationstation/`) e procura `theme.xml` em:
```
/etc/emulationstation/themes/<tema>
/home/ark/.emulationstation/themes/<tema>
/roms/themes/<tema>
/roms2/themes/<tema>
```

## Módulos

| # | Módulo | Arquivo | Resumo |
|---|---|---|---|
| 1 | Font Studio | `cat_1_font_studio.sh` | cor, tamanho, estilo, família, espaçamento entre linhas, favoritos, instalação via USB |
| 2 | Visual Studio | `cat_2_visual_studio.sh` | wallpaper, scanlines, cor de fundo/seleção, opacidade, gradiente, blur, glow, transparência de menus |
| 3 | Logo Center | `cat_3_logo_center.sh` | troca de logo por sistema, alinhamento, proporção, packs online, limpeza de cache |
| 4 | Theme Hub | `cat_4_theme_hub.sh` | aplicação de paletas completas pré-definidas (Dark, Neon, Retro, SNES, PS1, Arcade, Midnight, Game Boy) |
| 5 | Backup Center | `cat_5_backup_center.sh` | backup/restore do `theme.xml`, comparação, integridade MD5, agendamento, exportação |
| 6 | Interface do Usuário (UI) | `cat_6_interface_ui.sh` | aparência do próprio menu do Alter_MThemes (cores ANSI, layout, fonte do console) |
| 7 | Atualizador | `cat_7_atualizador.sh` | verificação e instalação de atualizações a partir de um repositório remoto |

Documentação detalhada de cada opção de menu e a tag/configuração que ela altera está disponível em separado (mapa de módulos).

## Fluxo de execução

1. `Alter_MThemes.sh` garante root (`sudo` se necessário) e prepara o terminal (`tty1`, `ESCDELAY`, etc.).
2. Cria diretórios de usuário se ausentes (`BACKUP_DIR`, `WALLPAPER_DIR`, `FONT_DIR`).
3. Inicia o mapeamento de D-pad via `gptokeyb`, se disponível.
4. `source` de todos os módulos listados em `MODULOS`.
5. `init.sh` detecta o tema ativo, define `$XML_FILE`, cria backup automático de abertura e processa agendamento de backup (`abertura`/`diário`/`semanal`).
6. Loop do menu principal:
   - A partir da segunda iteração, roda o **hook de validação automática** (estrutura, tags obrigatórias, valores numéricos, encoding, duplicatas) sobre `$XML_FILE`. Se houver problemas, oferece **IGNORAR**, **RESTAURAR** (último backup) ou **SAIR**.
   - Exibe status de backup (quantidade e data do mais recente).
   - Apresenta o menu numerado (1–8) e despacha para a função `categoria_N` correspondente.
7. Opção final do menu reinicia o EmulationStation e encerra o script.

## Validação e segurança do XML

`validator.sh` implementa verificações automáticas antes de qualquer gravação definitiva:

- **Estrutura**: tags raiz `<theme>`/`</theme>`, balanceamento de abertura/fechamento.
- **Tags obrigatórias**: presença de `<formatVersion>` e `<view>`.
- **Cores**: formato `RRGGBB`/`RRGGBBAA` válido em todas as tags de cor conhecidas.
- **Numéricos**: `opacity` entre `0.0–1.0`; `fontSize` em `0` (oculto), decimal `0.001–0.999` ou inteiro `4–500`.
- **Tamanho**: detecta truncamento (poucas linhas) ou redução suspeita (>60%) em relação ao original.
- **Encoding**: valida UTF-8 via `iconv`.
- **Duplicatas**: tags que devem ser únicas (`formatVersion`, `resolution`).

Em caso de problemas, o usuário decide entre salvar mesmo assim, cancelar a alteração ou sair do programa — nunca há sobrescrita silenciosa de um XML problemático.

Backups automáticos são criados:
- Ao abrir o script (`${XML_FILE}.bak` e uma cópia com timestamp).
- Conforme agendamento configurado no Backup Center (módulo 5).
- Manualmente, com nota opcional, pelo próprio Backup Center.

Todo backup recebe um arquivo `.md5` para checagem de integridade.

## Convenções de retorno do dialog

Os menus de seleção usam três botões padronizados (`core.sh` → `DIALOG_MENU`):

| Botão | Código bruto do dialog | Significado |
|---|---|---|
| OK | `0` | confirma a seleção |
| VOLTAR (`--extra-button`) | `3` | volta ao menu anterior |
| SAIR (`--cancel-label`) | `1` | encerra o programa (`ExitAll`) |
| ESC / botão B físico | `255` | normalizado para **VOLTAR** (`3`) via `NORM_RET`/`NORM_RET_MENU` |

`ESCDELAY=25` é definido em `core.sh` para eliminar o delay padrão de ~1s do ncurses ao detectar uma tecla ESC isolada — sem isso, o botão B do R36S responderia com atraso perceptível em qualquer caixa de diálogo do projeto.

Em caixas de confirmação simples (`DIALOG_MSG`), há apenas OK/SAIR. Em `--yesno`, o padrão é `0` (sim) / `1` (não).

> Regra de consistência: ESC nunca deve ser tratado como **SAIR** em nenhum ponto do projeto — ele sempre equivale a cancelar/voltar a ação atual, nunca a encerrar o programa sem confirmação explícita do usuário.

## Atualização remota

`cat_7_atualizador.sh` compara `lib/version.txt` local com a versão publicada em `UPDATE_BASE_URL` (por padrão, `raw.githubusercontent.com`, sem cache de CDN). Cada arquivo da lista `ARQUIVOS_ATUALIZAVEIS` é baixado, comparado via MD5 com a cópia local e, se diferente, substituído — com backup automático do arquivo anterior em `lib/backups_update_<timestamp>/`.

A URL do servidor pode ser customizada em `lib/update_url.cfg`.

## Instalação

1. Copie a pasta do projeto para o R36S, por exemplo em `/roms/tools/Alter_MThemes/` ou caminho equivalente usado pelo seu launcher de ferramentas do DarkOS.
2. Garanta que `Alter_MThemes.sh` tem permissão de execução:
   ```bash
   chmod +x Alter_MThemes.sh
   ```
3. Execute via launcher de ferramentas do sistema ou diretamente:
   ```bash
   ./Alter_MThemes.sh
   ```

## Convenções de contribuição

- Mudanças que adicionem, removam ou renumerem módulos devem atualizar **todos** os pontos listados na nota de numeração acima, na mesma alteração.
- Toda edição de `.sh` deve ser validada com `bash -n arquivo.sh` antes do commit.
- Edições no XML do tema devem sempre passar por `AplicarEmBloco`/blocos `awk` escopados — nunca um `sed` global sobre tags genéricas como `<color>`, que afetaria background, carousel e texto simultaneamente.
- Mensagens de interface e comentários do projeto estão em português; mantenha esse padrão em novos módulos.
