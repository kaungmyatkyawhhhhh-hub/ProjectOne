# TopbarPlus sometimes not showing (researched 30 Oct 2026)

- **Version:** GYM ARC uses TopbarPlus v3.4.0. Studio's output says v3.5.0 is out (DevForum thread 1017485). The GitHub releases page only lists up to v3.4.0.
- **Older fixes in the GitHub releases:**
  - v3.2.0: race condition when checking PlayerGuis.
  - v3.2.4: topbar wrongly switching to the old topbar.
  - v3.3.0: errors on reset when icons sit in a ResetOnSpawn gui.
- **DevForum reports** ("Topbar plus bug" 4047726, "TopBarPlus v3 Glitch?"): icons sometimes don't appear or overlap the CoreGui.
  - No confirmed code fix. Some only happened in Studio, and one went away with a Roblox update.
  - A rectangular settings button was fixed with a UIAspectRatioConstraint set to 1.
- **How TopbarPlus hides:** `Icon.setTopbarEnabled(bool)` sets `Enabled` on its container ScreenGuis (TopbarStandard, TopbarCentered and their Clipped versions).
- **GYM ARC fix (30 Oct):** Shared/UI/TopBar's `refreshVisible` no longer trusts its cached state.
  - Every 0.4 s it checks each container ScreenGui: it re-enables or re-disables any in the wrong state, and re-parents one that lost its parent.
  - It skips this while Roblox's own menu is open.
  - Tested: a disabled or unparented TopbarStandard came back within about 1 s.
- **Later:** update to v3.5.0 after the Hall of Fame launch, not right before it.

Sources: https://github.com/1ForeverHD/TopbarPlus/releases , https://devforum.roblox.com/t/topbar-plus-bug/4047726 , https://devforum.roblox.com/t/topbarplus-v3-issue/4272259
