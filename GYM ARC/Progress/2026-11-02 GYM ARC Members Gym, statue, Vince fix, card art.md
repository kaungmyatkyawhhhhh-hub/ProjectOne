---
date: 2026-11-02
tags: [gymarc, progress]
status: built and tested in Studio, not published
---
# GYM ARC - 2 Nov (evening): tutorial popups, Members Gym, statue, Vince fix, Run Cards art

Owner's list (2 Nov): no Runway popup in the tutorial; the Starter Pack card from the start of the tutorial; a better, more prominent Members Gym like the VIP Gym; a doorway from the Starter Gym like the VIP one, as big and as good; the statue outside by the leaderboard; after beating Vince the cutscene never went away; images for the Run Cards and a pick screen like Deepwoken's talent cards; the card text was blurry.

## Tutorial
- **Runway invite:** no longer comes during the tutorial or before Growth Spurt 1 (`RunwayClient`).
  - The old check read a player attribute `InTutorial` that nothing sets, so it never worked. It now uses `UIBus.InTutorial` / `InQuietStart`.
  - Tested: an invite sent to a tutorial player stays hidden.
- **Starter Pack card:** shows in the right column from the first second, the tutorial too (`StarterPackClient`).
  - Its 30 minutes count from the join, so hiding it until Spurt 1 lost players most of the deal.
  - Still hidden over the menu, a lift, a big window and the runway.
  - Note: the Playbook says "no shop offers in the tutorial". This is the owner's call.
  - ![[GYM ARC/Screenshots/2026-11-02/tutorial_starter_pack_card.jpg]]

## Vince's cutscene never went away (fixed)
- **Cause:** a cutscene shot cleans up with `ipairs({ grade, dof, rim, motes, gui })`, and `ipairs` stops at the first empty slot.
  - Vince's cliffhanger is a shot of Vince himself, whose copy is already gone after his fall. So there was no rim light, the loop stopped, and the black bars and caption (`StoryScene`) stayed on screen forever.
- **Fix:** every slot is cleared (`StoryClient`).
- **Same bug, also fixed:** `GeneticsClient` (column / hit) and `IntroCutscene` (me / benny / set).
- **Tested** with `TestStoryBeat = "Vince"`: the scene closes, Coach Dex's line shows as a caption, then the screen is clear.

## Members Gym: special and prominent (ruby + gold, its machines' colours)
- **Sign:** the fascia is taller (like the VIP's), "MEMBERS GYM" plus "GROUP MEMBERS ONLY · +10% GAINS", a big glowing ruby at each end, and a ruby strip under it.
- **Street entrance:** a "MEMBERS ENTRANCE" canopy with rubies and a warm light, a glowing ruby door frame, a red carpet with gold edges, and a few ruby sparkles.
- **Blade sign:** a 24-stud sign on the corner, "MEMBERS" down both faces, "+10%", lit ruby edges, and a glowing ruby with a light on top. Seen from down the street.
- **Inside:** ruby gems on the back wall; the floor light is ruby.
- All of it is in `Workspace.Town.MembersGym.Showcase` (50 parts, no shadows, no see-through parts). The fascia's old size is in attributes.
- ![[GYM ARC/Screenshots/2026-11-02/members_gym_front.jpg]]

## Doorway from the Starter Gym (like the VIP's)
- **Where:** in the Starter Gym entrance hall's left wall (the mirror of the VIP doorway on the right).
- **Size:** 9.7 x 10.6 studs (the VIP's is 9.0 x 10.6). It became possible once the statue moved out.
- **Look:**
  - A gold frame, double glass doors with a centre seam and two long gold handles, a dark sill.
  - Over it, "MEMBERS GYM" between two rubies (hall side). Inside, "STARTER GYM" over it.
- **How it works:** the door is one more `Door` of `MembersGym`, so it opens for members and shows the Join group prompt to others, like the two old doors.
- **Moved out, kept in `ServerStorage.MembersGymMoved`:** the hall's solid left wall, two side glass panes and one post.
- **Tested:** a member walked from the hall into the Members Gym.
  - A non-member couldn't be tested: this Studio account is in the group. Same door rule as the old doors, tested 28 Oct.
- The old back door (under the +10% sign, into the Starter Gym's main room) stays.
- ![[GYM ARC/Screenshots/2026-11-02/members_gym_doorway.jpg]]

## Strongest lifter statue: outside by the leaderboards
- **Where:** in the plaza, on the compass rose in front of the leaderboard stand (`Config/ShowOff.Statue.Spot = (0, 0.2, 71)`).
- **Facing:** the street and the gyms' doors (new `Facing`; `ShowOffService` reads it).
- **Pedestal:** `Workspace.StatuePedestal` moved with it; its plaque faces the street. The old spot is in its `OldCFrame` attribute.
- ![[GYM ARC/Screenshots/2026-11-02/statue_plaza.jpg]]

## Run Cards: art and a Deepwoken-style hand
See [[GYM ARC - Run Cards]] (Art and The pick screen).

## Not done
- Phone-size screenshots (the Studio window can't be resized from here).
- A real non-member test of the new door.
