# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Empty Godot 4.6 project ("New Game Project"). No scenes, scripts, or gameplay code exist yet — only engine configuration and the default icon. When adding the first files, place scenes/scripts under `res://` and register the main scene in `project.godot` under `[application] run/main_scene`.

## Engine configuration (from `project.godot`)

- **Engine**: Godot 4.6, Forward Plus renderer
- **Physics**: Jolt Physics (3D) — use Jolt-compatible bodies/shapes; some Godot physics nodes have subtle behavioral differences under Jolt
- **Rendering driver (Windows)**: Direct3D 12

Preserve these settings unless the user asks to change them. Editing `project.godot` by hand is supported but the file is normally maintained by the editor — prefer editing via the Godot editor when practical.

## Running and editing

This project has no CLI build or test harness. Development happens in the Godot editor:

- Open the project by launching Godot 4.6 and selecting this folder (or running `godot --path .` / `godot -e --path .` from the project root if Godot is on PATH).
- The `.godot/` directory is the editor's import/cache; it is gitignored and regenerated on first open.

## Conventions

- **Line endings**: `.gitattributes` enforces LF for text files (`* text=auto eol=lf`) — keep LF when creating new text files, even on Windows.
- **Encoding**: UTF-8 (`.editorconfig`).
