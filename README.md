# Conway’s Game of Life — Commodore 64 (6502 ASM)

An implementation of **Conway’s Game of Life** for the **Commodore 64**, written in 6502 assembly (KickAssembler syntax).

No pretentions, just a first attempt to learn assembly for the C64.

The program features an interactive **setup/editor phase** to define the initial pattern, followed by an **in-place simulation** of successive generations.

---

## Features

- Written entirely in **6502 assembly**
- Runs on real C64 hardware or in **VICE**
- Interactive editor for defining the initial pattern
- In-place Game of Life algorithm using transitional states:
  - `*` = alive
  - ` ` = dead
  - `-` = dying
  - `+` = born
- No double buffering; operates directly on screen RAM
- Keyboard-driven interface

---

## Controls

### Setup phase

| Key | Action |
|----|--------|
| **A** | Move cursor left |
| **S** | Move cursor right |
| **W** | Move cursor up |
| **Z** | Move cursor down |
| **Space** | Toggle cell (alive / dead) |
| **Q** | Start simulation |

### Simulation phase

| Key | Action |
|----|--------|
| **Q** | Quit program |

---

## Technical details

- Resolution: **40 × 25**
- Screen RAM base: `$0400`
- Cursor is displayed using **reverse video**
- Neighbor counting follows Conway’s rules:
  - `ALIVE` and `DYING` count as alive
  - `EMPTY` and `BORN` count as dead
- Transitional states are normalized after each generation

### In-place algorithm

The simulation does **not** use a secondary buffer.  
Instead, transitional states (`DYING`, `BORN`) are written directly to screen RAM so that neighbor counts are always based on the previous generation.

---

## Build & Run

### Requirements

- **KickAssembler**
- **Java**
- **VICE** (optional, recommended)

### Build

```sh
java -jar KickAss.jar life.asm
```

### Run in VICE

```
LOAD "LIFE.PRG",8,1
RUN
```