--[[
	JobsData (19 Nov 2026, owner: "u should make jobs like in roblox southwest florida"): the jobs' extra
	tables, kept out of Config.lua (it is at pack_sync.py's 199,000-byte limit). Config.Jobs keeps the
	ranks, pay and posts; this has what each job does, the job vehicles, the post actions and the
	AFK shift rules. Used by server/Jobs.lua, client/JobsClient.lua and client/MainMenu.lua (JOBS tab).
]]

return {
	-- one line per job for the JOBS tab: what you do there
	What = {
		delivery = "Pick up parcels at the dispatch rings and drop them across town.",
		taxi = "Drive to the pickup, then take the fare where they want to go.",
		bus = "Drive the YBS line: stop at each of the 7 real bus stops.",
		police = "Patrol points, and ticket real players who speed past you.",
		tea = "Stand at the counter. Serve customers for tips.",
		fuel = "Work the pumps. Fill customers' tanks for tips.",
		dealer = "Work the showroom floor. Help buyers for tips.",
		mall = "Work the boutique counter. Serve shoppers for tips.",
	},
	-- field jobs' vehicles: an existing car re-painted (fictional livery, no logos), driven only by the
	-- job holder (it is their car slot), gone when they quit. shortcut: the YBS "bus" is the Grand
	-- Lounge van, no bus model exists yet; give it a real bus body when one is imported
	Vehicles = {
		bus = { car = "toyoka_alfard", label = "YBS VAN", look = { paint = { 238, 238, 232 }, accent = { 196, 36, 44 }, finish = "gloss", plate = "YBS 36" } },
		taxi = { car = "toyoka_crown", label = "TAXI", look = { paint = { 236, 186, 34 }, accent = { 24, 24, 26 }, finish = "gloss", plate = "TAXI" } },
		police = { car = "toyoka_crown", label = "PATROL CAR", look = { paint = { 244, 246, 250 }, accent = { 28, 56, 138 }, finish = "gloss", plate = "POLICE" } },
	},
	VehicleCooldown = 10, -- seconds between two job vehicle spawns
	-- post actions (a prompt at the post, only for the job holder on duty): an NPC customer for a small
	-- tip; at the fuel post a real player's car stopped at the pumps pays double and gets its tank filled
	Serve = {
		tea = { action = "Serve tea", object = "Customer" },
		fuel = { action = "Fill a tank", object = "Pump", car = true },
		dealer = { action = "Help a buyer", object = "Showroom" },
		mall = { action = "Serve a shopper", object = "Counter" },
	},
	ServeTip = 40, -- x rank pay and Double Pay
	ServeXp = 5,
	ServeCooldown = 20,
	ServeCarRange = 40, -- studs from the fuel post: a player's car there counts as a customer
	-- posts are AFK jobs (owner, 19 Nov): no daily cap. After ShiftCheck seconds in a row at the post a
	-- "Still on shift?" card comes up; no tap in ShiftAnswer seconds: off duty until KEEP WORKING
	ShiftCheck = 2 * 60 * 60,
	ShiftAnswer = 5 * 60,
	-- auto-rejoin before Roblox's 20-minute idle kick, only for a player on duty at a post. NOT officially
	-- approved by Roblox: watch moderation
	RejoinIdle = 18 * 60, -- Players.LocalPlayer.Idled's seconds (it fires every ~2 min: 18 is the last before 20)
	RejoinTries = 3,
	RejoinMaxAge = 300, -- teleport data older than this is ignored
}
