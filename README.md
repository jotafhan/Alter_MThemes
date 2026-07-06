# Alter_MThemes v7.0.3

A modular bash-based theme manager for **EmulationStation** on the **R36S** handheld gaming console running **ArkOS**. Alter_MThemes provides a fully controller-navigable TUI (terminal user interface) powered by `dialog`, allowing you to customize fonts, colors, logos, themes, backups, boot images, and the interface itself — all without touching any XML file manually.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [File Structure](#file-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Modules](#modules)
  - [1. Font Studio](#1-font-studio)
  - [2. Visual Studio](#2-visual-studio)
  - [3. Logo Center](#3-logo-center)
  - [4. Theme Hub](#4-theme-hub)
  - [5. Backup Center](#5-backup-center)
  - [6. Interface UI](#6-interface-ui)
  - [7. Boot Center](#7-boot-center)
  - [8. Update Alter_MThemes](#8-update-alter_mthemes)
- [Core Architecture](#core-architecture)
- [XML Validation Engine](#xml-validation-engine)
- [Controller Mapping](#controller-mapping)
- [User Data Folders](#user-data-folders)
- [Known Limitations](#known-limitations)
- [Contributing](#contributing)

---

## Features

- Fully controller-navigable — no physical keyboard required
- Modular architecture: each feature is an independent bash module
- Live XML editing with block-scoped tag targeting via `awk`
- Automatic XML backup on every session open
- XML validation engine with 7 independent checks before any save
- Auto-update system pulling directly from GitHub
- Boot logo and loading screen management
- Interface appearance customization (colors, fonts, window size)
- Logo pack downloader with 6 curated online packs
- Font favorites system with persistent storage

---

## Requirements

| Requirement | Details |
|---|---|
| Device | R36S handheld console |
| OS | ArkOS |
| Frontend | EmulationStation |
| Shell | bash |
| TUI | `dialog` |
| Controller bridge | `gptokeyb` (at `/opt/inttools/gptokeyb`) |
| Network | Wi-Fi required for logo packs and updates |
| ImageMagick | Optional — required only for boot logo BMP conversion |

---

## File Structure

```
Alter_MThemes/
├── Alter_MThemes.sh          # Main dispatcher and menu loop
└── lib/
    ├── core.sh               # Base functions, dialog wrappers, AplicarEmBloco
    ├── init.sh               # Theme detection, XML_FILE resolution, backup on open
    ├── validator.sh          # XML validation engine
    ├── cat_1_font_studio.sh  # Module 1 — Font Studio
    ├── cat_2_visual_studio.sh# Module 2 — Visual Studio
    ├── cat_3_logo_center.sh  # Module 3 — Logo Center
    ├── cat_4_theme_hub.sh    # Module 4 — Theme Hub
    ├── cat_5_backup_center.sh# Module 5 — Backup Center
    ├── cat_6_interface_ui.sh # Module 6 — Interface UI
    ├── cat_8_boot_image.sh   # Module 7 — Boot Center
    ├── cat_7_atualizador.sh  # Module 8 — Update Alter_MThemes
    ├── menu_aparencia.cfg    # Saved UI appearance settings
    ├── menu_dialogrc         # Generated dialogrc for custom colors
    ├── keys_alter_mthemes.gptk # Runtime-generated controller map
    └── version.txt           # Current version string
```

**User data folders** (created automatically, accessible via SD card):

```
/home/ark/
├── darkos_backups/       # XML backups (Backup Center)
├── darkos_wallpapers/    # Wallpaper images (Visual Studio)
├── darkos_fonts/         # Custom fonts (.ttf/.otf)
└── darkos_logos/         # Downloaded logo packs

/roms/
├── boot_images/          # Boot logo images (Boot Center)
└── launchimages/         # Loading screen files (Boot Center)
```

---

## Installation

1. Copy the entire `Alter_MThemes` folder to your R36S (via SD card or SSH).
2. Make the main script executable:
   ```bash
   chmod +x Alter_MThemes.sh
   ```
3. Run it:
   ```bash
   sudo ./Alter_MThemes.sh
   ```
   The script requests `sudo` automatically if not already root.

> **Note:** The script auto-detects the active EmulationStation theme by reading `es_settings.cfg`. It searches for `theme.xml` in `/etc/emulationstation/themes/`, `/home/ark/.emulationstation/themes/`, `/roms/themes/`, and `/roms2/themes/`.

---

## Usage

Navigate with the **D-pad**, confirm with **A**, and go back with **B**. Every menu has three buttons:

| Button | Action |
|---|---|
| **A / Start** | Confirm / OK |
| **B / Select** | Back / Cancel current action |
| **Menu (cancel)** | Exit the program |

---

## Modules

### 1. Font Studio

Controls all text appearance in the active EmulationStation theme.

| Option | Description |
|---|---|
| 1. Font Color | Choose from 9 color groups (Classic, Warm, Cool, Natural, Special, Pastel, Dark Neon) or enter a custom HEX code digit by digit |
| 2. Font Size | 6 presets from 0.022 (Tiny) to 0.070 (Giant) |
| 3. Font Style | Normal, Bold, Italic, Bold+Italic |
| 4. Font Family | System fonts (10 DejaVu variants), theme fonts, or your own installed fonts |
| 5. Line Spacing | 6 presets (1.0–1.8) or custom decimal value |
| 6. Font Favorites | Save, load, and remove favorite fonts |
| 7. Install Font via USB | Copy .ttf/.otf files from a USB drive to the fonts folder |
| 8. Delete Font | Remove installed fonts from the fonts folder |

**Apply targets** — all font/color changes can be applied to:
- All blocks (global)
- Game list only (`gamelist`)
- Main menu carousel (`systemcarousel`)
- System info text (`systemInfo`)
- ES options menu (`menuText`)

**Color persistence:** the last applied color is saved to `.ultima_cor` and can be reused without re-selecting.

---

### 2. Visual Studio

Controls the visual appearance of the theme beyond text.

| Option | Description |
|---|---|
| 1. Theme Wallpaper | Apply a `.jpg` or `.png` from `/home/ark/darkos_wallpapers/` as background |
| 2. Scanlines | Enable retro CRT scanline effect (Light / Medium / Heavy / Arcade) or disable |
| 3. Background Color | Choose background color from 6 groups or custom HEX |
| 4. Selected Item Color | Set highlight color for the selected menu item |
| 5. Element Opacity | Adjust transparency of all elements, background, or images/logos |
| 6. Blur / Defocus | Apply blur effect to the background (requires ImageMagick) |
| 7. Accent Color | Set a single accent/highlight color |
| 8. Menu Transparency | Set the ES options menu background alpha (100% / 85% / 70% / 50%) |
| 9. Reset Visual | Restore the theme XML to the state it was in when the script was opened |

> **Note:** Background and carousel colors are never modified by font/text color operations, by design.

---

### 3. Logo Center

Manages system logos displayed in EmulationStation.

| Option | Description |
|---|---|
| 1. Replace System Logo | Install a logo from `/home/ark/darkos_logos/` into the active theme |
| 2. Backup Current Logos | Copy all theme logos to a timestamped backup folder |
| 3. Restore Original Logo | Restore a previously backed-up logo |
| 4. Adjust Logo Alignment | Set position/origin (Center, Left, Right, Top, Bottom) |
| 5. Adjust Logo Scale | Set size via `maxSize` (Small / Medium / Large) |
| 6. Clear Image Cache | Remove EmulationStation downloaded image cache |
| 7. Download Logo Pack | Download a curated logo pack from GitHub |
| 8. List Theme Logos | Display all logos currently in the active theme |
| 9. Delete Logo Pack | Remove an entire downloaded pack by folder |
| 10. Delete Specific Logo | Remove a single logo file from the logos folder |

**Available logo packs (option 7):**

| # | Pack | Source |
|---|---|---|
| 1 | Monochrome SVG+PNG | HVR88/Monochrome-Gaming-Logos |
| 2 | Carbon (RetroPie) | RetroPie/es-theme-carbon |
| 3 | Art Book | anthonycaccese/es-theme-art-book |
| 4 | Alekfull NX | fagnerpc/Alekfull-NX |
| 5 | Switch (lilbud) | lilbud/es-theme-switch |
| 6 | Monochrome SVG only | HVR88/Monochrome-Gaming-Logos |

Each pack is saved in its own named subfolder inside `/home/ark/darkos_logos/` for clean management.

---

### 4. Theme Hub

Applies complete preset themes in a single operation, setting font color, background color, selected item color, font size, and font family simultaneously.

| Preset | Font | Background | Highlight |
|---|---|---|---|
| Dark | White `#FFFFFF` | Near-black `#1A1A1A` | Blue `#00AAFF` |
| Neon | Green `#00FF00` | Black `#000000` | Cyan `#00FFFF` |
| Retro | Orange `#FF9933` | Dark brown `#1A0800` | Gold `#FFD700` |
| SNES | White `#FFFFFF` | Deep purple `#2D0050` | Lilac `#CC99FF` |
| PS1 | Light blue `#CCCCFF` | Navy `#0D1B2A` | Blue `#0066FF` |
| Arcade | Yellow `#FFFF00` | Dark red `#1A0000` | Red `#FF0000` |
| Midnight | Ice blue `#E0E8FF` | Dark navy `#000D1A` | Blue `#00AAFF` |
| Game Boy | Dark green `#0F380F` | Lime `#9BBC0F` | Forest `#306230` |

A confirmation dialog shows all values before applying. Each preset also copies the matching DejaVu font variant to the theme's `_art/` folder.

---

### 5. Backup Center

Full XML backup management for the active theme.

| Option | Description |
|---|---|
| 1. Create Backup Now | Save current XML with an optional label (8 predefined notes) |
| 2. List Backups | Show all backups with size and date |
| 3. Restore Backup | Replace current XML with a selected backup |
| 4. Compare Backup with Current | Show differences in tag values between a backup and current |
| 5. Restore Specific Config | Restore only selected tags (colors, font, opacity, etc.) |
| 6. Verify Integrity (MD5) | Check or generate MD5 checksums for all backups |
| 7. Delete Specific Backup | Remove a single backup file |
| 8. Delete Old Backups | Keep only the N most recent backups |
| 9. Export to USB Drive | Copy all backups to a connected USB drive |
| 10. Change History | View the last 30 logged operations |
| 11. Space Used | Detailed storage report for the backup folder |
| 12. Automation | Enable/disable automatic backup on every script open |
| 13. Backup Schedule | Set backup frequency (on open / daily / weekly) |
| 14. Full Theme Backup (.ZIP) | Archive the entire theme directory as a ZIP file |

Backups are stored in `/home/ark/darkos_backups/` and named with a timestamp and optional label:
```
darkos_20250704_142300_configuracao-estavel.xml
```
Each backup automatically generates a `.md5` checksum file.

---

### 6. Interface UI

Customizes the appearance of the Alter_MThemes main menu itself (not the ES theme).

| Option | Description |
|---|---|
| 1. Pre-built Themes | Apply a complete color scheme in one step |
| 2. Manual Color Editor | Customize every UI element individually |
| 3. Window Title | Choose from presets or build a custom title character by character |
| 4. Separator Line | Choose from 11 separator styles or remove it |
| 5. Window Size | Set height, width, and visible item count |
| 6. Header Information | Toggle clock, theme name, and backup status in the header |
| 7. Font Size | Change the TTY console font (applied live via `setfont`) |
| 8. Reset to Default | Restore all UI settings to system defaults |

**Pre-built color themes:**

| Theme | Description |
|---|---|
| Minimalist Light | White background, blue selection |
| DarkOS Original | Dark blue, cyan text |
| Terminal Green | Black and green, no borders |
| Retro Amber | CRT orange monitor style |
| Purple Neon | Magenta highlight |
| Red Hacker | Aggressive red border |
| Cyan Night | Sci-fi black and cyan |
| System Default | No customization |

**Console font sizes** (Terminus family, applied via `setfont`):
`12x6` · `14` · `16` (default) · `18x10` · `20x10` · `22x11` · `24x12`

Settings are persisted in `lib/menu_aparencia.cfg` and a `dialogrc` file is generated at `lib/menu_dialogrc`.

---

### 7. Boot Center

Manages the visual elements displayed when the console boots and when a game launches.

| Option | Description |
|---|---|
| 1. Boot Logo | Set the image shown when the R36S powers on |
| 2. Loading Screen | Set the image shown when a game is launched |
| 3. Logo Cycle | Information about using multiple BMPs in the `BMPs/` folder for rotating boot logos |
| 4. Restore Originals | Restore any file from an automatic backup |
| 5. Current Status | Show details of all installed boot/loading files |
| 6. Install Image via USB | Copy images from a USB drive to the user staging folder |

**Boot Logo** (`/boot/logo.bmp`):
- Required format: BMP 24-bit, 640×480
- If ImageMagick is available, images are automatically converted and resized
- Source images go in `/roms/boot_images/` (accessible via SD card on PC)

**Loading Screen** (`/roms/launchimages/loading.*`):
- Supported formats: `.jpg`, `.gif`, `.mp4`, `.ascii`
- EmulationStation automatically picks the available format
- Source files go in `/roms/launchimages/` (also the install destination)

A timestamped backup is created automatically before any file is replaced.

---

### 8. Update Alter_MThemes

Checks for and installs updates from the configured GitHub repository.

| Option | Description |
|---|---|
| 1. Check and Install Updates | Compares local and remote `version.txt`, downloads changed files, applies update |
| 2. Update History | Lists all previous update backup folders with file counts |
| 3. Force Revert to Backup | Restore the most recent pre-update backup |
| 4. Back to Main Menu | Return without any action |

**Update source:** `https://raw.githubusercontent.com/jotafhan/Alter_MThemes/main`

The updater compares MD5 checksums for each file individually — only files that actually changed are downloaded. Before applying, a full backup of the current files is saved to `lib/backups_update_YYYYMMDD_HHMMSS/`. The system clock is synchronized via `timedatectl` before connecting to avoid TLS certificate errors.

---

## Core Architecture

### `core.sh`

Provides all shared functions used across modules:

**`AplicarEmBloco`** — the main XML editing engine. Applies a tag/value pair to a specific named block in the theme XML using `awk` with `dentro`/`achou` flag pairs. Supports 5 targets:

| Target | Block |
|---|---|
| 1 — Global | All `<text>` and `<textlist>` blocks (never touches carousel or background) |
| 2 — Gamelist | `<textlist name="gamelist">` |
| 3 — Carousel | `<text name="sys_line1/2/systemInfo">` in the system view |
| 4 — SystemInfo | `<text name="systemInfo">` |
| 5 — Menu | `<menuText>` blocks only |

When a tag is absent from a block, `AplicarEmBloco` **inserts** it before the closing tag rather than silently doing nothing.

**Dialog wrappers:**
- `DIALOG_MENU` — standard 3-button menu (OK / BACK / EXIT)
- `DIALOG_MSG` — standard 2-button message box (OK / EXIT)
- `NORM_RET` — normalizes exit code 255 (ESC/B button) to 3 (BACK)
- `EscolherAlvo` — reusable target selector for all apply operations
- `PerguntarReiniciar` — prompts to restart EmulationStation after changes

### `init.sh`

Runs once at startup:
- Reads the active theme name from `es_settings.cfg`
- Resolves `XML_FILE` by searching 4 possible theme directories
- Creates a `.bak` copy of the XML (used by Visual Studio's Reset option)
- Runs the scheduled backup logic (on-open / daily / weekly)
- Defines `ReiniciarES()` for restarting EmulationStation

### `validator.sh`

Runs 7 independent checks on the XML before saving:

| Check | What it verifies |
|---|---|
| Structure | Balanced open/close tags, presence of `<theme>` root |
| Required tags | `formatVersion` and `view` must exist |
| Color values | All color tags must be valid 6 or 8-digit HEX |
| Numeric ranges | `opacity` within 0.0–1.0, `fontSize` within valid range |
| File size | Not truncated; not reduced by more than 60% vs original |
| Encoding | File must be valid UTF-8 |
| Duplicates | Tags like `formatVersion` must not appear more than once |

On failure, the user can choose to save anyway, cancel (recommended), or exit.

---

## Controller Mapping

The controller map is generated at runtime from a bash heredoc (no external `.gptk` file dependency):

| Button | Action |
|---|---|
| D-pad | Navigate menus |
| A | Confirm / OK |
| B | Back / Cancel |
| Start | Confirm (same as A) |
| L1 / R1 | Page Up / Page Down |

---

## User Data Folders

All user data is stored outside the theme directory and survives theme updates:

| Folder | Purpose | SD Card Accessible |
|---|---|---|
| `/home/ark/darkos_backups/` | XML backups | No (SSH only) |
| `/home/ark/darkos_wallpapers/` | Wallpaper images | No (SSH only) |
| `/home/ark/darkos_fonts/` | Custom fonts (.ttf/.otf) | No (SSH only) |
| `/home/ark/darkos_logos/` | Downloaded logo packs | No (SSH only) |
| `/roms/boot_images/` | Boot logo staging area | **Yes** |
| `/roms/launchimages/` | Loading screen files | **Yes** |

To add files without SSH, use the SD card slot on a PC and place files directly in `/roms/boot_images/` or `/roms/launchimages/`.

---

## Known Limitations

**B button ~1s delay:** The `gptokeyb` binary has a hardcoded delay when processing the ESC key sequence. This is a platform-level limitation and cannot be fixed from script or config level. `ESCDELAY=25` is set in `core.sh` to minimize the effect where possible.

**Tag insertion via `sed`:** Direct `sed` calls in Font Studio (font family application), Logo Center, Theme Hub, and Backup Center (specific restore) only replace existing tags — they do not insert when a tag is absent. This is intentional: EmulationStation's XML spec requires color/font tags to be children of a specific named element, and blind insertion risks structurally invalid XML that fails silently in the ES parser. Use the `AplicarEmBloco` targets (options that ask "where to apply") for guaranteed insertion.

**Blur and gradient effects:** Blur (Visual Studio option 6) requires ImageMagick (`convert`), which may not be installed on all ArkOS builds. Gradient generation has been removed as it also depended on ImageMagick.

**Scanlines and Glow:** Support depends on the EmulationStation build and theme version. These options write the tags but there is no guarantee the running ES binary supports them.

**Wi-Fi required:** Logo pack downloads and the update system require an active Wi-Fi connection.

---

## Contributing

1. Fork the repository at `https://github.com/jotafhan/Alter_MThemes`
2. Make your changes in a feature branch
3. Test on real hardware (R36S / ArkOS) if possible
4. Submit a pull request with a clear description of what changed and why

The codebase is entirely in Brazilian Portuguese (variable names, comments, UI strings). New modules should follow the existing pattern:
- Define a `categoria_N()` function with a `CATEGORIA="N"` guard
- Source in `Alter_MThemes.sh` via the `MODULOS` array
- Add the menu entry and `case` branch in the main dispatcher

---

*Alter_MThemes v7.0.3 — Made for the R36S community*
