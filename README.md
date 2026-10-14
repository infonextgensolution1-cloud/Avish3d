# BlockForge 3D

A first-person 3D block-puzzle prototype built with Godot 4.x and GDScript, targeting Android first.

## Prototype scope

- Small, lit 3D puzzle room assembled from box geometry.
- First-person movement (WASD / arrow keys) and mouse look.
- Three glowing sequence cubes; click them in order to complete the puzzle.
- Minimal HUD, objective feedback, and a mobile-compatible renderer baseline.
- No production deployment or publication is part of this milestone.

## Open in Godot

1. Install a current stable Godot 4.x build.
2. Import this repository folder by selecting `project.godot`.
3. Open `scenes/main.tscn` or press **F6** after import.
4. Run the project with **F6/F5**. Click once to capture the mouse; right-click or Escape releases it.
5. Complete the sequence by looking at the orange, yellow, and teal cubes and clicking each in order.

## Development workflow

- Active development branch: `feat/blockforge3d-godot-foundation`
- Keep changes isolated from `main`.
- Review changes in a pull request before any merge.
- Do not publish or promote a production release without explicit approval.

## QA checklist

- [ ] Import in the selected stable Godot 4.x version without errors.
- [ ] Main scene starts and all geometry/materials render.
- [ ] Player movement, floor collision, and mouse-look work.
- [ ] Raycast selects only a target within interaction range.
- [ ] Correct cube order completes the puzzle; wrong order does not.
- [ ] Android export template and SDK are configured and a device build launches.
- [ ] Add dedicated on-screen movement/look controls before calling the mobile UX complete.

## Current limitations

This is a foundation prototype, not a release-ready mobile game. Dedicated touch movement/look controls, level progression, persistence, audio, accessibility settings, and device performance testing remain future work. A repository commit alone does not prove the project has been imported or run by Godot.
