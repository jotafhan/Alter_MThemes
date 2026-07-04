# Alter_MThemes

Theme customizer for **EmulationStation** running on **DarkOS** on the **R36S**, via a `dialog`/ncurses TUI that is 100% navigable by D-pad — no physical keyboard required.

> Current version: `7.0.4`

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Paths and Directories](#paths-and-directories)
- [Modules](#modules)
- [Execution Flow](#execution-flow)
- [XML Validation and Safety](#xml-validation-and-safety)
- [Dialog Return Conventions](#dialog-return-conventions)
- [Remote Updates](#remote-updates)
- [Installation](#installation)
- [Contribution Conventions](#contribution-conventions)

---

## Overview

Alter_MThemes directly edits the `theme.xml` of the active EmulationStation theme (fonts, colors, wallpaper, logos, etc.), maintains versioned backups with integrity checking, and provides an appearance editor for the application's own menu (ANSI colors, layout, console font).

The entire application is built on `dialog` (ncurses), designed for the small screen and D-pad of the R36S — there are no free-text fields; everything is list navigation and character selectors.

## Requirements

Packages/binaries used by the project (must be available on the DarkOS system):

| Binary | Purpose |
|---|---|
| `dialog` | entire interface (ncurses) |
| `wget` | downloading logo packs, overlays, and updates |
| `unzip` / `zip` | extracting packs and full theme backup (.zip) |
| `convert` (ImageMagick) | gradient and wallpaper blur generation |
| `git` | updating themes that are git repositories |
| `md5sum` | backup integrity checking |
| `setfont` | changing console font size (TTY) |
| `iconv` | XML encoding validation |
| `gptokeyb` | D-pad/button to keyboard mapping (ArkOS/ROCKNIX environment specific) |
| `systemctl` | restarting the EmulationStation service |

Execution requires root privileges (the script re-executes itself via `sudo` automatically if not already root).

## Project Structure

```
Alter_MThemes/
├── Alter_MThemes.sh          # entry point — main menu and loop
└── lib/
    ├── core.sh                # base functions (dialog wrappers, ESCDELAY, ExitAll)
    ├── init.sh                # active theme detection, automatic backup on open
    ├── validator.sh           # automatic XML validation before saving
    ├── cat_1_font_studio.sh   # fonts (color, size, style, family, line spacing)
    ├── cat_2_visual_studio.sh # wallpaper, scanlines, colors, opacity, gradient, blur, glow
    ├── cat_3_logo_center.sh   # per-system logos (swap, align, online packs)
    ├── cat_4_theme_hub.sh     # preset themes (predefined full palettes)
    ├── cat_5_backup_center.sh # theme.xml backup/restore, history, scheduling
    ├── cat_6_interface_ui.sh  # Alter_MThemes menu appearance (ANSI colors, layout, console font)
    ├── cat_7_atualizador.sh   # update checking and installation via GitHub
    ├── menu_aparencia.cfg     # persistent config for module 6 (menu colors/layout)
    ├── menu_dialogrc          # DIALOGRC generated from menu_aparencia.cfg
    └── version.txt            # local version, compared against the remote repository
```

> **Numbering note:** the number in the filename (`cat_N_*.sh`) maps 1:1 to the internal `CATEGORY`/function (`categoria_N`). This is intentionally kept in sync — when adding, removing, or reordering modules, all of the following must be updated together:
> - the `MODULOS` array in `Alter_MThemes.sh`
> - the main `--menu` items and the `case "$ITEM_SEL"` in `Alter_MThemes.sh`
> - the function name `categoria_N()` and the `if [ "$CATEGORIA" = "N" ]` check inside the module itself (where applicable)
> - the `ARQUIVOS_ATUALIZAVEIS` list in `cat_7_atualizador.sh`

## Architecture

- **Pure Bash**, no external language dependencies.
- Each category module (`cat_N_*.sh`) is **`source`d** into the main process (`Alter_MThemes.sh`) and exposes a `categoria_N()` function called by the menu loop.
- The theme XML (`$XML_FILE`) is edited via `sed`/`awk` directly — no XML parser. Edits are always scoped to specific blocks (`<background>`, `<carousel>`, `<textlist name="gamelist">`, `<menuText>`, etc.) to prevent a text color change, for example, from leaking into the background.
- Every visual change offers an **EmulationStation restart** at the end (`PerguntarReiniciar`), never forced.

## Paths and Directories

| Variable | Default Path | Contents |
|---|---|---|
| `BACKUP_DIR` | `/home/ark/darkos_backups` | `theme.xml` backups, history, automation flags |
| `WALLPAPER_DIR` | `/home/ark/darkos_wallpapers` | user background images |
| `FONT_DIR` | `/home/ark/darkos_fonts` | user-installed `.ttf`/`.otf` fonts + favorites |
| `LOGOS_DIR` | `/home/ark/darkos_logos` | downloaded/installed system logos |
| `LOGOS_BAK_DIR` | `/home/ark/darkos_backups/logos` | logo and pack backups |
| `$XML_FILE` | dynamically detected | `theme.xml` of the active theme (see `init.sh`) |

Active theme detection (`init.sh`): reads `ThemeSet` from `es_settings.cfg` (`/var/local/emulationstation/` or `/home/ark/.emulationstation/`) and searches for `theme.xml` in:
```
/etc/emulationstation/themes/<theme>
/home/ark/.emulationstation/themes/<theme>
/roms/themes/<theme>
/roms2/themes/<theme>
```

## Modules

| # | Module | File | Summary |
|---|---|---|---|
| 1 | Font Studio | `cat_1_font_studio.sh` | color, size, style, family, line spacing, favorites, USB installation |
| 2 | Visual Studio | `cat_2_visual_studio.sh` | wallpaper, scanlines, background/selection color, opacity, gradient, blur, glow, menu transparency |
| 3 | Logo Center | `cat_3_logo_center.sh` | per-system logo swap, alignment, aspect ratio, online packs, cache cleanup |
| 4 | Theme Hub | `cat_4_theme_hub.sh` | apply predefined full palettes (Dark, Neon, Retro, SNES, PS1, Arcade, Midnight, Game Boy) |
| 5 | Backup Center | `cat_5_backup_center.sh` | `theme.xml` backup/restore, comparison, MD5 integrity, scheduling, export |
| 6 | User Interface (UI) | `cat_6_interface_ui.sh` | Alter_MThemes menu appearance (ANSI colors, layout, console font) |
| 7 | Updater | `cat_7_atualizador.sh` | check and install updates from a remote repository |

Detailed documentation for each menu option and the tag/setting it modifies is available separately (module map).

## Execution Flow

1. `Alter_MThemes.sh` ensures root (`sudo` if needed) and prepares the terminal (`tty1`, `ESCDELAY`, etc.).
2. Creates user directories if absent (`BACKUP_DIR`, `WALLPAPER_DIR`, `FONT_DIR`).
3. Starts D-pad mapping via `gptokeyb`, if available.
4. `source`s all modules listed in `MODULOS`.
5. `init.sh` detects the active theme, sets `$XML_FILE`, creates an automatic open-time backup, and processes the backup schedule (`on-open` / `daily` / `weekly`).
6. Main menu loop:
   - From the second iteration onward, runs the **automatic validation hook** (structure, required tags, numeric values, encoding, duplicates) on `$XML_FILE`. If issues are found, offers **IGNORE**, **RESTORE** (last backup), or **EXIT**.
   - Displays backup status (count and date of the most recent backup).
   - Presents the numbered menu (1–8) and dispatches to the corresponding `categoria_N` function.
7. The final menu option restarts EmulationStation and exits the script.

## XML Validation and Safety

`validator.sh` implements automatic checks before any definitive write:

- **Structure**: root tags `<theme>`/`</theme>`, open/close balancing.
- **Required tags**: presence of `<formatVersion>` and `<view>`.
- **Colors**: valid `RRGGBB`/`RRGGBBAA` format in all known color tags.
- **Numerics**: `opacity` between `0.0–1.0`; `fontSize` as `0` (hidden), decimal `0.001–0.999`, or integer `4–500`.
- **Size**: detects truncation (too few lines) or suspicious shrinkage (>60%) relative to the original.
- **Encoding**: validates UTF-8 via `iconv`.
- **Duplicates**: tags that must be unique (`formatVersion`, `resolution`).

When issues are found, the user decides whether to save anyway, cancel the change, or exit — a problematic XML is never silently overwritten.

Automatic backups are created:
- When the script opens (`${XML_FILE}.bak` and a timestamped copy).
- According to the schedule configured in the Backup Center (module 5).
- Manually, with an optional note, from the Backup Center itself.

Every backup receives an `.md5` file for integrity checking.

## Dialog Return Conventions

Selection menus use three standardized buttons (`core.sh` → `DIALOG_MENU`):

| Button | Raw dialog code | Meaning |
|---|---|---|
| OK | `0` | confirms the selection |
| BACK (`--extra-button`) | `3` | returns to the previous menu |
| EXIT (`--cancel-label`) | `1` | terminates the program (`ExitAll`) |
| ESC / physical B button | `255` | normalized to **BACK** (`3`) via `NORM_RET`/`NORM_RET_MENU` |

`ESCDELAY=25` is set in `core.sh` to eliminate the default ~1s ncurses delay when detecting a standalone ESC key — without this, the R36S B button would respond with a noticeable lag in every dialog in the project.

In simple confirmation boxes (`DIALOG_MSG`), only OK/EXIT are present. In `--yesno`, the default is `0` (yes) / `1` (no).

> Consistency rule: ESC must never be treated as **EXIT** anywhere in the project — it always means cancel/return from the current action, never terminate the program without explicit user confirmation.

## Remote Updates

`cat_7_atualizador.sh` compares the local `lib/version.txt` against the version published at `UPDATE_BASE_URL` (by default, `raw.githubusercontent.com`, no CDN cache). Each file in the `ARQUIVOS_ATUALIZAVEIS` list is downloaded, compared via MD5 to the local copy, and replaced if different — with an automatic backup of the previous file in `lib/backups_update_<timestamp>/`.

The server URL can be customized in `lib/update_url.cfg`.

## Installation

1. Copy the project folder to the R36S, for example to `/roms/tools/Alter_MThemes/` or the equivalent path used by your DarkOS tools launcher.
2. Make sure `Alter_MThemes.sh` has execute permission:
   ```bash
   chmod +x Alter_MThemes.sh
   ```
3. Run it via the system tools launcher or directly:
   ```bash
   ./Alter_MThemes.sh
   ```

## Contribution Conventions

- Changes that add, remove, or renumber modules must update **all** the points listed in the numbering note above, in the same commit.
- Every `.sh` edit must be validated with `bash -n file.sh` before committing.
- Theme XML edits must always go through `AplicarEmBloco`/scoped `awk` blocks — never a global `sed` on generic tags like `<color>`, which would affect background, carousel, and text simultaneously.
- Interface messages and project comments are in Portuguese; maintain that standard in new modules.
