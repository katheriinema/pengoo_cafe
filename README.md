# 🐧 Pengu Cafe

Welcome to **Pengu Cafe**, a cozy penguin-themed management and simulation game built with **Godot 4**!

In **Pengu Cafe**, you start your adventure by hatching your first penguin. Expand your cafe empire by hatching eggs, training penguins, managing your economy, and growing your bustling penguin workforce — all while serving delicious treats to your customers!

Link to game --> https://katheriinema.github.io/pingoogoo/
---

## 🎮 Features

- **Egg Hatching**: Buy eggs, feed them, and hatch a variety of adorable penguins.
- **Penguin Management**: Name, level up, and upgrade penguins to improve productivity.
- **Cafe Economy**: Earn coins and fish by managing your penguins' tasks.
- **Upgrades and Skills**: Boost your penguins’ efficiency through leveling and special upgrades.
- **Persistent Cloud Save**: Progress is saved online using **Supabase**, so you never lose your penguin empire!
- **Smooth UI and Animations**: Enjoy responsive controls, polished UI panels, and satisfying animations.
- **Fishing Mini-Game**: Catch fish to feed your growing army of penguins!

---

## 🚀 Tech Stack

- **Engine**: [Godot 4](https://godotengine.org/)
- **Database and Auth**: [Supabase](https://supabase.com/) (Cloud-based user authentication and game state storage)
- **Hosting**: [GitHub Pages](https://pages.github.com/) (for web deployment)

---

## 📦 Project Structure

```plaintext
assets/
 └── art/
 └── scenes/*.gd
 └── sounds/
 └── fonts/
```

- `GameState.gd`: Handles communication with Supabase: login, signup, cloud save, ...
- `Main.tscn`: Main game world and UI scene.
- `PlotPanel.tscn`: Popup panel for penguin/egg management.
- `Fishing.tscn`: Mini-game for catching fish.
- `Many more...`

---

## 🛠️ How to Run Locally

1. **Clone the repo**:
   ```bash
   git clone https://github.com/your-username/pengu-cafe.git
   cd pengu-cafe
   ```

2. **Open the project** in Godot 4.4.1

3. **Configure environment**:
   - Set your **Supabase URL** and **API Key** inside `Supabase.gd`.
   - Make sure you have a `user_data` table set up in your Supabase project.

4. **Run the game**:
   - Press **Play** in Godot!

---

## 🧐 Future Plans

- Add new penguin types, rare eggs, and cafe expansion mechanics
- Implement customer orders and cooking mini-games
- Seasonal events and limited-time eggs
- Mobile optimization for iOS and Android

---

## ❤️ Acknowledgements

- Built with love for penguins and cozy management games
- Music and assets either self-created or under free commercial license
- Thanks to the open-source Godot community!

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

# 🧊 Chill, Hatch, and Serve at **Pengu Cafe**! 🐧☕