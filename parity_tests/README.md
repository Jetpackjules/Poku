# Poku Godot 3-to-4 parity suite

This suite compares the immutable `2023-edition` worktree with the Godot 4 project. It copies both projects into temporary directories, injects version-specific harnesses, and never modifies the legacy worktree.

Godot 3 runs with `--no-window --audio-driver Dummy`; Godot 4 runs with `--headless`. The archived Godot 3 import cache is copied instead of launching its editor, so the suite does not open or focus game/editor windows.

Run everything:

```bash
python3 parity_tests/run_parity.py --repeats 5
```

Run one gate with `--scenario`, for example:

```bash
python3 parity_tests/run_parity.py --scenario throw --repeats 5
python3 parity_tests/run_parity.py --scenario players
python3 parity_tests/run_parity.py --scenario maps
```

The suite currently checks:

- scene paths/types/groups/signals; collision polygons, shapes, layers, and masks; physics materials; joints; cameras; transforms; mass, damping, sleep, contact, CCD, and converted body modes;
- live project/engine physics settings, input mappings, gravity-unit normalization, solver settings, and logical/window size;
- every legacy layerless gameplay boundary against actual body motion, including the basketball centre divider;
- spear and shuriken collision, actual-player impalement, completion, twin embed pins, stab/ragdoll callbacks, and embedded-weapon weight;
- real automatic pickup plus six spear/shuriken spin-and-release directions/durations, judged against five independent Godot 3 runs; a failed stochastic-envelope check automatically gathers five more legacy samples before returning a failure. Shuriken held-angle drift uses a measured 10-degree mode allowance because legacy sampling demonstrated separate 114.6-117.8 and 124.9-127.9 degree modes;
- idle, run, short/long jump, running jump, crouch, and spin traces using the actual player scene and the real input pipeline; five traces are taken from each engine, each accepted Godot 4 trace must have a complete strict match in the five-trace Godot 3 support set, and a majority of Godot 4 traces must be accepted. This treats the old solver's observed modes as valid support without assigning meaning to their unstable batch frequencies;
- finite body states, grounded transitions, jump takeoff/apex/landing, limb and hand trajectories, velocities, rotations, arm reach, and knee folding;
- contact/friction outcomes for spear and ball across slow, fast, flat, tilted, and steep landings;
- unfixed-seed Wipeout wall gaps, offsets, cadence, viewport placement, velocity, and collision behavior;
- 200 unfixed-seed Vertical Parkour platforms per engine, including probability bands, gaps, x clamps, moving offsets, and moving-platform rate;
- basketball scoring/ball completion, speed-powerup doubling/restoration, and death-zone player/tool behavior;
- all ten maps loading and simulating real player movement/jumping without script errors or non-finite body states.

Test-only input scripting does not alter game randomness or add fixed seeds to either project. Random systems are checked using authored invariants and broad probability bands rather than requiring identical random sequences.

Two test-copy-only accommodations preserve the archive while making intended behavior testable:

- the legacy Spaceship spawner key `tools = ["Coal"]` is corrected to its script's authored `tool_names` property only inside the temporary copy;
- the basketball mechanics harness stops the repeating hoop timer after the first successful score, because the original timer otherwise keeps invoking the freed ball. The first-score behavior itself is compared unchanged.
