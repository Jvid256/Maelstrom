# Making a build for your laptop and testers

Builds come out of the Godot editor on your desktop. Four presets are already set up in `export_presets.cfg`: **Windows Desktop**, **Web**, **Linux** and **macOS**. Once the export templates are installed, each build is one click.

## One-time setup: export templates (about 1 GB, once per Godot version)

1. Open the project in Godot 4.4.1 on your desktop.
2. **Editor > Manage Export Templates...**
3. Click **Download and Install**. Wait for it to finish, then close the window.

## Windows build (for your laptop)

1. **Project > Export...**
2. Select **Windows Desktop** in the left list.
3. Click **Export Project...** at the bottom, keep the suggested path (`../builds/windows/Maelstrom.exe`), and click **Save**.
4. Zip the `builds/windows` folder and copy it to the laptop. Testers get the same zip. The `.pck` is embedded, so it's a single `Maelstrom.exe` (plus nothing else).

Windows SmartScreen will warn about an unsigned program the first time; **More info > Run anyway**.

## Web build (a link for testers)

1. **Project > Export...**, select **Web**, click **Export Project...**, keep `../builds/web/index.html`.
2. The preset has thread support **off**, so the build runs from ordinary static hosting (no special headers needed). Upload the whole `builds/web` folder to itch.io (set the project to **HTML**, mark `index.html` as the file to run, viewport 1440×810) or any static host. It will not run from a `file://` double-click; it needs a web server.

Saves in the web build live in the browser's storage and are per browser.

## Linux and macOS

Same steps with the **Linux** or **macOS** preset. The macOS build is unsigned; testers open it with right-click > Open the first time.

## Testing from the command line (optional)

With templates installed, the desktop can also export without opening the editor:

    godot --headless --path . --export-release "Windows Desktop" ../builds/windows/Maelstrom.exe

## What testers should know

- Saves are automatic (end of each day, closing a screen). **Start over** is at the bottom of the Hero screen's Gear tab.
- The playtest script (`tools/chapter_test.gd`) is not in the export; it's for development only.
- Things most worth feedback: pacing of the first chapter, the three story fights (throne hall, the plaza, the airlock), and whether Power and Parts feel like decisions or chores.
