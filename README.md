# Conway’s Game of Life — Commodore 64 (6502 ASM)

An implementation of **Conway’s Game of Life** for the **Commodore 64**, written in **6502 assembly** using **KickAssembler** syntax.

This is a personal learning project: a first serious exploration of C64 assembly programming, focused on understanding the machine, memory layout, and performance trade-offs rather than on polish or completeness.

The program includes an interactive **editor/setup phase** to define the initial pattern, followed by a continuously running **simulation phase**.

---

## Features

- Pure **6502 assembly** (KickAssembler)
- Runs on real C64 hardware or in **VICE**
- Interactive editor to define the initial board state
- Game of Life simulation with **toroidal wrap-around** (edges connect)
- **Double-buffered screen RAM** for faster generation updates
- Direct screen RAM access (no KERNAL output during simulation)
- Keyboard-driven interface

---

## Controls

### Setup / Edit phase

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
| **E** | Return to editor |

---

## Technical details

- Resolution: **40 × 25**
- Screen buffers:
  - Screen 0: `$0400`
  - Screen 1: `$2000`
- Screen flipping via **VIC-II register `$D018`**
- Separate **read** and **write** screen buffers per generation
- Uses zero-page pointers for fast memory access

### Game of Life rules

- A live cell survives with **2 or 3** live neighbours
- A dead cell is born with **exactly 3** live neighbours
- All other cells die or remain empty

Cells are stored as:
- `*` — alive  
- `' '` — empty  

(Intermediate states are avoided by writing the next generation directly into the off-screen buffer.)

### Algorithm overview

1. Read the current generation from the active screen buffer
2. Compute the next generation into the inactive screen buffer
3. Flip the visible screen by updating `$D018`
4. Swap read/write buffers and repeat

This avoids a full redraw pass and keeps the inner loop tight.

---
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