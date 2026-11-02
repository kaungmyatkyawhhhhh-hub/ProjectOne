-- GalaxyEconShared (Galaxy Incremental, overnight part 2, 3 Nov; ServerStorage): GalaxyEconService fills this in so other
-- server scripts can reach a player's save without a second copy of it:
--   .sessions[player] = { d = the save data, ... }   (nil while loading)
--   .publish(player, session)  re-sends every attribute the HUD / map read
--   .save(player, release)     writes the save now (release = false keeps the session lock)
return { sessions = {} }
