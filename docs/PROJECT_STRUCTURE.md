# Project layout

This is a Godot 4.7 project organized around the main scene and reusable component scenes. See [docs/EDITING.md](docs/EDITING.md) for the editor workflow and where to change each part.

- `scenes/main.tscn` is the entry scene.
- `scenes/ui/hud.tscn` groups the interface component scenes.
- `scenes/components/` contains reusable game systems.
- `scripts/` groups scripts by core, world, gameplay, UI, and audio responsibilities.
- `data/mission_readiness.json` contains editable astronaut-training questions and the pass threshold.
- `assets/` contains the source models and media; `shaders/` contains visual effects.
