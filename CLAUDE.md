# Instructions for Claude

This repo is my Obsidian vault. It syncs to my PC with the Obsidian Git plugin (branch `master`).

- **Every session, before replying:** read `00-START-HERE.md`, then `Identity.md`, `Work.md`, `Preferences.md` and `Active-Projects.md`. Then read the CLAUDE.md / Quick Rules inside the game folder you're working on. Read any other note only if it's relevant.
- **Use what you find:**
  - Never ask who I am, what I do or what my businesses are.
  - If I mention something you don't know, check the vault before asking.
- **Communication:** follow the communication rules in `Preferences.md` exactly.
- **Updating the vault:**
  - When I tell you something new and lasting (a decision, a status change, a new project, a new preference), add it to the right note.
  - Commit and push to `master` so Obsidian pulls it. Small updates don't need permission.
  - Ask before restructuring or deleting anything.
- **Don't announce it:** never say that you read the vault.
- **Leave `.obsidian/` alone:** it is Obsidian's own settings and plugins.
- **Roblox Playbook (every game):** before planning or building any feature, update, launch, store item, thumbnail/icon or new game, read `Roblox Playbook/Roblox Playbook - Rules for every game.md` and follow it. For details, search inside the three Playbook guides in that folder (never read them whole).
- **Folders:** each game has its own folder; notes go only there. `Archive/` holds old games: read-only.
- **Roblox Studio (several Studios may be open):**
  - Call `list_roblox_studios` before your first Studio edit each session and pick the Studio of the game you're working on BY NAME. If it has no name, stop and ask me.
  - GYM ARC = placeId 80031260599632. SPEED ARC = placeId 134701616695802 (being moved to a new group, see its prompt 13). MOW ARC = on hold, no place yet.
  - Never touch another game's Studio.
- **Game UI (permanent rule, GYM ARC; MOW ARC has its own UI kit rule in its folder):**
  - Every new button, window, card, pill and popup MUST use the existing designed UI kit (Theme.Button, Kit.Modal, the existing card/pill styles and their images). Never make a new plain button (coded rectangle + gold gradient + UIStroke). That is a placeholder and I don't accept it.
  - Before adding UI, find the closest existing screen (Store, Pump Shop, Coach Dex, Physique, Trainers) and copy its components and sizes.
  - If a needed component doesn't exist in the kit yet, build it in the same style (same corners, outline, lip, shine, fonts) as a reusable kit component, then use it.
  - After building, take a phone-size screenshot next to an existing screen and check they look like the same game. If anything looks like a placeholder, fix it before reporting.
