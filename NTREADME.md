# MISG Hub - Advanced Roblox Size Editor GUI

A sleek, responsive, and mobile-friendly GUI script designed for Roblox size editor games. It features automatic RemoteEvent detection, per-part scaling, live ESP name tags, and advanced custom size sequencing.

---

## 🌟 Key Features

* **Snappy UI Animations:** Smooth pop-in and pop-out scaling animations with zero sluggish delays.
* **Smart Search Hub:** The player selection menu automatically snaps to the right side of the main hub when opened, and can be dragged freely.
* **Clickable ESP Name Tags:** Toggle ESP on and click directly on a player's name tag in the 3D world to instantly select or deselect them.
* **Persistent Selection:** Player selections survive character resets, deaths, and respawns until they leave the server.
* **Camera Zoom Limits:** Automatically unlocks maximum camera zoom and sets minimum zoom to the closest possible distance.
* **Advanced Size Sequencing:** Custom parser for progressive growth/shrink sequences.

---

## 🎮 How to Use Size Sequences

You can type advanced automated commands into the **Set Size** input box:

* **Basic Set:** `1` (Sets size to 1)
* **Timed Delay (`..`):** `1, ..2, 2` (Sets size to 1, waits 2 seconds, then sets to 2)
* **Incremental Step (`.!`) & Limit (`!!`):** 
  `1, ..2, .!0.5, !!2` 
  *(Starts at 1, waits 2 seconds, adds 0.5 every interval until it reaches a limit of 2, then stops)*

---

## 🛠️ Controls & Buttons

* **MISG Floating Button:** Toggles the Main Hub open or closed.
* **Select Player >:** Opens the player search window directly beside the hub.
* **DeSelect All Player:** Clears all currently selected players.
* **Height / Width / Depth / Head:** Toggles individual body part scaling on or off.
* **Apply To Select / Apply To All:** Executes your scale values or sequences immediately.
* **LOOP 🟢 / 🔴:** Continuously loops size application for selected players or everyone.
* **ESP:** Highlights players and shows name tags in the game world.
