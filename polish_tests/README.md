# Poku polished-jank tests

These are fast Godot 4 checks for the modern game, not comparisons with the archived Godot 3 project.

Run all checks headlessly:

```bash
python3 polish_tests/run_polish_tests.py
```

The suite checks:

- grounded stability, acceleration/deceleration, charged jump range, coyote time, jump buffering, crouch recovery, bounded spin speeds, and arm recovery;
- automatic pickup reservation, magnetic attachment, useful throw velocity, swept high-speed embedding, and two-point weapon attachment;
- distinct spear flight stabilization, shuriken release spin, and ball impact behavior;
- `AnimatableBody2D` movement for Vertical Parkour platforms and Wipeout walls;
- real coal/furnace overlap, fuel consumption, and spaceship lift targeting;
- Volleyball floor scoring, Basketball win score, reachable Wipeout openings, bounded parkour jumps, and physical plane updraft lift;
- isolated Controller 1/P1 and Controller 2/P2 actions, analog trigger input, menu confirm/back, visible default focus, and placeholder focus exclusion;
- finite physics state while every map loads, plus verification that the Ostrich scene is wired to and responds through its shared modern ragdoll motor;
- the actual game-select Ostritch tile, transition route, and parking of the normal Poku players.

These tests intentionally allow physical variation. They protect reliable outcomes and failure bounds while leaving room for funny poses and collision-driven motion.
