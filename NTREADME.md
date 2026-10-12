# MISG Hub - Roblox Size Editor GUI

**MISG Hub** is a feature-rich, sleek Roblox script designed for manipulating player sizes, body scales, and head dimensions dynamically using custom sequence commands. It features an interactive UI with smooth animations, mobile-friendly dragging, player selection via ESP or a search menu, and a powerful size-sequencing parser.

---

## ✨ Features

- **Dynamic Size Editor GUI**: Sleek dark-mode interface with smooth opening/closing animations and draggable windows/status panels.
- **Advanced Sequence Parser**: Chain multiple scaling commands together with custom delays, increments, and dynamic targets.
- **Dynamic `?` Target Support**: Automatically detects and transitions back to player baseline or original sizes seamlessly (`!!?`).
- **Simultaneous Multi-Target Scaling**: Apply size adjustments instantly across all selected players or everyone in the server at the exact same time.
- **Multi-Part Control**: Toggle and apply scaling to specific body parts (`Height`, `Width`, `Depth`, `Head`) simultaneously.
- **Built-in ESP & Infinite Click Selection**: Easily highlight and select players by clicking them from any distance or through the searchable player list.
- **Loop Modes**: Continuously loop size updates for selected players or everyone.

---

## 🚀 How to Use

1. Execute the script using your preferred Roblox exploit/executor.
2. The **MISG HUB** floating button and status label will appear on your screen. Click **MISG** to toggle the main menu.
3. Select your target players using the **Select Player** menu or click directly on players using the infinite-distance ESP click selector.
4. Choose which body parts to affect (`Height`, `Width`, `Depth`, `Head`) using the toggle buttons.
5. Enter your size command into the scale box and click **Apply To Select** or **Apply To All**.

---

## ⌨️ Sequence Command Guide

You can chain multiple commands together separated by commas `,` to create smooth, animated size sequences.

### Command Syntax
- **`[Number]`**: Sets the target size instantly (e.g., `1`).
- **`..[Seconds]`**: Sets the delay/wait time between incremental steps (e.g., `..0.1`).
- **`.![Step]`**: Specifies how much size to add per step (e.g., `.!0.1`).
- **`!![Target]`**: Increments smoothly toward a target size using a default step of `0.5` (e.g., `!!5`).
- **`!?`**: Dynamically targets the player's original baseline/starting size (e.g., `!!?` or `.!0.1!?`).

### Example Sequences

- **Grow to 5 smoothly:**
  ```text
  1, ..0.1, .!0.1, !!5
