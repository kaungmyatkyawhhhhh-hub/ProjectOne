--[[
	Strings (19 Nov 2026, owner: Burmese language option, "for burmese language u need to use unicode").
	Every player-facing UI string, English + Myanmar UNICODE (never Zawgyi). Vault note with the review
	table: "City Legends/2026-11-19 Burmese language.md". Check: python tools/strings_check.py

	  Strings.get("menu.play")             -> "Play" / "ကစားမည်"
	  Strings.get("map.kmAway", 2.4)       -> string.format on the current language's text
	  Strings.setLang("auto" | "en" | "my") ; Strings.lang() ; Strings.Changed (fires on a switch)

	Entry = { English, Myanmar, review }: review = true marks a translation the owner should check.
	Rules: brand / car / place names stay as they are; Level, XP, CP, VIP, PI, Robux, Drift, Turbo stay
	English (Myanmar players use them); the same %d / %s in the same order in both languages.
	Not here yet (server-sent texts, ChallengeData / goals text, car names): see the vault note.
]]

local Players = game:GetService("Players")

local T: { [string]: { any } } = {
	-- common
	["common.play"] = { "Play", "ကစားမည်" },
	["common.back"] = { "BACK", "နောက်သို့" },
	["common.close"] = { "CLOSE", "ပိတ်မည်" },
	["common.cancel"] = { "CANCEL", "မလုပ်တော့ပါ" },
	["common.exit"] = { "EXIT", "ထွက်မည်" },
	["common.buy"] = { "BUY", "ဝယ်မည်" },
	["common.buyX"] = { "BUY %s", "%s ဝယ်မည်" },
	["common.sell"] = { "SELL", "ရောင်းမည်" },
	["common.sellX"] = { "SELL %s", "%s ရောင်းမည်" },
	["common.claim"] = { "CLAIM", "ယူမည်" },
	["common.claimX"] = { "CLAIM %s", "%s ယူမည်" },
	["common.owned"] = { "OWNED", "ပိုင်ပြီး" },
	["common.open"] = { "OPEN", "ဖွင့်မည်" },
	["common.done"] = { "DONE", "ပြီးပြီ" },
	["common.ready"] = { "READY!", "ရပြီ!" },
	["common.readyIn"] = { "READY IN %s", "%s အကြာတွင် ရမည်" },
	["common.free"] = { "FREE", "အခမဲ့" },
	["common.on"] = { "ON", "ဖွင့်" },
	["common.off"] = { "OFF", "ပိတ်" },
	["common.auto"] = { "AUTO", "အလိုအလျောက်" },
	["common.low"] = { "LOW", "နိမ့်" },
	["common.medium"] = { "MEDIUM", "အလယ်" },
	["common.high"] = { "HIGH", "မြင့်" },
	["common.normal"] = { "NORMAL", "ပုံမှန်" },
	["common.all"] = { "ALL", "အားလုံး" },
	["common.new"] = { "New", "အသစ်" },
	["common.search"] = { "Search", "ရှာရန်" },
	["common.loading"] = { "Loading...", "ဖွင့်နေသည်..." },
	["common.oneMoment"] = { "ONE MOMENT...", "ခဏစောင့်ပါ..." },
	["common.tryAgain"] = { "Try again", "ထပ်ကြိုးစားပါ" },
	["common.comingSoon"] = { "COMING SOON", "မကြာမီ လာမည်" },
	["common.unavailable"] = { "UNAVAILABLE", "မရနိုင်ပါ" },
	["common.notEnoughCash"] = { "Not enough cash", "ငွေ မလောက်ပါ" },
	["common.notEnoughCashMore"] = { "Not enough cash: %s more", "ငွေ မလောက်ပါ: %s ထပ်လိုသည်" },
	["common.youHave"] = { "You have %s", "သင့်မှာ %s ရှိသည်" },
	["common.noServer"] = { "The server didn't answer: try again", "Server က မတုံ့ပြန်ပါ: ထပ်ကြိုးစားပါ" },
	["common.noServerShort"] = { "Server did not respond", "Server က မတုံ့ပြန်ပါ" },
	["common.cantNow"] = { "Can't do that right now, try again", "ယခု မလုပ်နိုင်ပါ၊ ထပ်ကြိုးစားပါ" },
	["common.waypoint"] = { "Waypoint: %s (on your map)", "ဦးတည်ရာ: %s (မြေပုံပေါ်တွင်)" },
	["common.waypointSet"] = { "Waypoint set: %s", "ဦးတည်ရာ မှတ်ပြီး: %s" },
	["common.level"] = { "LEVEL %d", "Level %d" },
	["common.levelCash"] = { "LEVEL %d   ·   CASH  %s", "Level %d   ·   ငွေ  %s" },
	["common.xp"] = { "%d / %d XP", "%d / %d XP" },
	["common.days"] = { "%dd %dh", "%d ရက် %d နာရီ" },
	["common.day"] = { "DAY %d", "နေ့ %d" },
	["common.pts"] = { "%d PTS", "%d မှတ်" },

	-- language setting
	["lang.title"] = { "Language", "ဘာသာစကား" },
	["lang.auto"] = { "Auto", "အလိုအလျောက်" },
	["lang.en"] = { "English", "English" },
	["lang.my"] = { "မြန်မာ", "မြန်မာ" },

	-- loading and intro
	["load.sounds"] = { "Loading sounds...", "အသံများ ဖွင့်နေသည်..." },
	["load.city"] = { "Building the city...", "မြို့ကို တည်ဆောက်နေသည်..." },
	["load.cars"] = { "Shaping the cars...", "ကားများကို ပုံဖော်နေသည်..." },
	["load.engines"] = { "Starting engines...", "စက်နှိုးနေသည်..." },
	["load.skyline"] = { "Painting the skyline...", "မြို့ပုံကို ဆေးခြယ်နေသည်..." },
	["load.traffic"] = { "Filling the streets with traffic...", "လမ်းများပေါ် ကားများ ထည့်နေသည်..." },
	["load.map"] = { "Loading the map...", "မြေပုံ ဖွင့်နေသည်..." },
	["load.still"] = { "Still loading the city...", "မြို့ကို ဖွင့်နေဆဲ..." },
	["load.streets"] = { "Loading the streets...", "လမ်းများ ဖွင့်နေသည်..." },
	["intro.skip"] = { "SKIP  ▶", "ကျော်မည်  ▶" },
	["intro.tagline"] = { "NIGHT  ·  CITY  ·  TRAFFIC", "ည  ·  မြို့  ·  ယာဉ်ကြော" },
	["intro.pitch"] = { "Cut up through traffic. Get paid. Become a legend.", "ကားကြား ဖြတ်မောင်း။ ငွေရှာ။ Legend ဖြစ်လာ။", true },

	-- main menu tiles and tabs
	["menu.cars"] = { "CARS", "ကားများ" },
	["menu.jobs"] = { "JOBS", "အလုပ်များ" },
	["menu.houses"] = { "HOUSES", "အိမ်များ" },
	["menu.map"] = { "MAP", "မြေပုံ" },
	["menu.store"] = { "SHOP", "ဆိုင်" },
	["menu.goals"] = { "GOALS", "ပန်းတိုင်များ", true },
	["menu.more"] = { "MORE", "နောက်ထပ်" },
	["menu.settings"] = { "Settings", "ဆက်တင်" },
	["menu.settingsSub"] = { "Map, graphics, camera, sound", "မြေပုံ၊ ဂရပ်ဖစ်၊ ကင်မရာ၊ အသံ" },
	["menu.goalsSub"] = { "Daily tasks and rewards", "နေ့စဉ်တာဝန်များနှင့် ဆုများ" },
	["menu.chauffeurSub"] = { "Call your driver", "ကားဆရာ ခေါ်ရန်" },
	["menu.achievements"] = { "Achievements", "အောင်မြင်မှုများ" },
	["menu.worldMap"] = { "World Map", "မြေပုံ" },
	["menu.switchTab"] = { "Switch tab", "Tab ပြောင်းမည်" },
	["menu.playPick"] = { "First, pick your free car", "အခမဲ့ကား အရင်ရွေးပါ" },
	["menu.playBack"] = { "Back to the road", "လမ်းပေါ် ပြန်သွားမည်" },
	["menu.playOut"] = { "Drive your car out", "ကား ထုတ်မောင်းမည်" },
	["menu.nextGoal"] = { "Next goal: %s", "နောက်ပန်းတိုင်: %s" },
	["menu.pathCount"] = { "Legends Path %d / %d", "Legends Path %d / %d" },
	["menu.carsCount"] = { "Cars %d / %d", "ကား %d / %d" },
	["menu.claimCar"] = { "CLAIM CAR", "ကားယူမည်" },
	["menu.firstFree"] = { "Pick your first car: it's free", "ပထမဆုံးကား ရွေးပါ: အခမဲ့ပါ" },
	["menu.yourCar"] = { "YOUR CAR", "သင့်ကား" },
	["menu.carLv"] = { "CAR LV %d", "ကား LV %d" },
	["menu.lv"] = { "LV %d", "LV %d" },

	-- world map
	["map.youAreHere"] = { "You are here", "သင် ဒီမှာ" },
	["map.yourHouse"] = { "Your House", "သင့်အိမ်" },
	["map.pickPlace"] = { "Pick a place", "နေရာတစ်ခု ရွေးပါ" },
	["map.help"] = { "Click or tap a symbol on the map to see what's there, fast travel to it or set a waypoint.\n\nDrag to move, scroll or + / - to zoom.", "မြေပုံပေါ်က အမှတ်အသားကို နှိပ်ပြီး ဘာရှိလဲ ကြည့်ပါ၊ ချက်ချင်းသွားပါ သို့မဟုတ် ဦးတည်ရာ မှတ်ပါ။\n\nဆွဲပြီး ရွှေ့ပါ၊ scroll သို့မဟုတ် + / - ဖြင့် ချဲ့ချုံ့ပါ။" },
	["map.kmAway"] = { "%.1f km away", "%.1f km ကွာ" },
	["map.mAway"] = { "%d m away", "%d m ကွာ" },
	["map.losePolice"] = { "Lose the police first", "ရဲကို အရင် လွတ်အောင်ပြေးပါ" },
	["map.fastTravel"] = { "FAST TRAVEL", "ချက်ချင်းသွားမည်", true },
	["map.setWaypoint"] = { "SET WAYPOINT", "ဦးတည်ရာ မှတ်မည်", true },
	["map.travelling"] = { "TRAVELLING...", "သွားနေသည်..." },
	["map.cantTravel"] = { "Can't travel now", "ယခု မသွားနိုင်ပါ" },
	["map.waypointSet"] = { "WAYPOINT SET ✓", "ဦးတည်ရာ မှတ်ပြီး ✓" },
	["map.arrived"] = { "You've arrived", "ရောက်ပါပြီ" },
	["map.miniHelpTouch"] = { "MAP  ·  drag to move, + / - to zoom", "မြေပုံ  ·  ဆွဲပြီး ရွှေ့ပါ၊ + / - ဖြင့် ချဲ့ချုံ့ပါ" },
	["map.miniHelpMouse"] = { "MAP  ·  scroll to zoom, drag to move", "မြေပုံ  ·  scroll ဖြင့် ချဲ့ချုံ့ပါ၊ ဆွဲပြီး ရွှေ့ပါ" },
	["map.bankLive"] = { "LIVE · The bank vault is open: green $ on the map", "LIVE · ဘဏ်တိုက် ဖွင့်ထားသည်: မြေပုံပေါ်က အစိမ်းရောင် $" },

	-- leaderboard
	["board.noOne"] = { "No one yet", "မရှိသေးပါ" },
	["board.failed"] = { "Couldn't load the board: try again", "အဆင့်ဇယား ဖွင့်မရပါ: ထပ်ကြိုးစားပါ" },
	["board.topSpeed"] = { "TOP SPEED", "အမြန်ဆုံး" },
	["board.bestDrift"] = { "BEST DRIFT", "အကောင်းဆုံး Drift" },
	["board.you"] = { "YOU  ·  top speed %d mph  ·  best drift %d  ·  longest jump %.1fs", "သင်  ·  အမြန်ဆုံး %d mph  ·  Drift %d  ·  အရှည်ဆုံးခုန် %.1fs" },

	-- settings
	["set.stuck"] = { "Stuck? Back on the road", "ပိတ်မိနေလား? လမ်းပေါ် ပြန်တင်မည်" },
	["set.resetCar"] = { "RESET CAR", "ကား ပြန်တင်မည်" },
	["set.getInFirst"] = { "Get in your car first", "ကားထဲ အရင်ဝင်ပါ" },
	["set.graphics"] = { "GRAPHICS", "ဂရပ်ဖစ်" },
	["set.camera"] = { "CAMERA", "ကင်မရာ" },
	["set.driving"] = { "DRIVING", "မောင်းနှင်မှု" },
	["set.handling"] = { "HANDLING", "ကိုင်တွယ်မှု", true },
	["set.cameraView"] = { "Camera view", "ကင်မရာ မြင်ကွင်း" },
	["set.miniMap"] = { "Mini map", "မြေပုံငယ်" },
	["set.miniMapSpot"] = { "Mini map spot", "မြေပုံငယ် နေရာ" },
	["set.topRight"] = { "TOP RIGHT", "ညာဘက် အပေါ်" },
	["set.topLeft"] = { "TOP LEFT", "ဘယ်ဘက် အပေါ်" },
	["set.bottomRight"] = { "BOTTOM RIGHT", "ညာဘက် အောက်" },
	["set.bottomLeft"] = { "BOTTOM LEFT", "ဘယ်ဘက် အောက်" },
	["set.renderDistance"] = { "Render distance", "မြင်ကွင်း အကွာအဝေး" },
	["set.traffic"] = { "Traffic", "ယာဉ်အသွားအလာ" },
	["set.ambient"] = { "Ambient light", "ပတ်ဝန်းကျင် အလင်း" },
	["set.sunRays"] = { "Sun rays", "နေရောင်ခြည်" },
	["set.dof"] = { "Depth of field", "နောက်ခံ မှုန်ဝါးခြင်း", true },
	["set.timeWeather"] = { "TIME AND WEATHER", "အချိန်နှင့် ရာသီဥတု" },
	["set.timeOfDay"] = { "Time of day", "နေ့အချိန်" },
	["set.setHour"] = { "Set the hour", "နာရီ သတ်မှတ်ပါ" },
	["set.morning"] = { "MORNING", "မနက်" },
	["set.noon"] = { "NOON", "နေ့လယ်" },
	["set.night"] = { "NIGHT", "ည" },
	["set.sunClouds"] = { "Sun and clouds", "နေနှင့် တိမ်" },
	["set.haze"] = { "Horizon haze", "မိုးကုပ်စက်ဝိုင်း မြူ" },
	["set.fog"] = { "Fog layer", "မြူထု" },
	["set.shake"] = { "Camera shake", "ကင်မရာ လှုပ်ခြင်း" },
	["set.headMove"] = { "Head movement", "ခေါင်း လှုပ်ရှားမှု" },
	["set.motionBlur"] = { "Motion blur", "Motion blur" },
	["set.fov"] = { "Chase camera FOV", "နောက်လိုက်ကင်မရာ FOV" },
	["set.calm"] = { "Calm motion (less shake and blur)", "ငြိမ်ငြိမ်လေး (လှုပ်ခြင်း၊ မှုန်ခြင်း နည်း)" },
	["set.units"] = { "Speed units", "အမြန်နှုန်း ယူနစ်" },
	["set.gearbox"] = { "Gearbox", "ဂီယာ" },
	["set.manual"] = { "MANUAL", "MANUAL" },
	["set.speedo"] = { "Speedometer", "အမြန်နှုန်းပြ" },
	["set.digital"] = { "DIGITAL", "DIGITAL" },
	["set.analogue"] = { "ANALOGUE", "ANALOGUE" },
	["set.tc"] = { "Traction control", "Traction control" },
	["set.sc"] = { "Stability control", "Stability control" },
	["set.abs"] = { "ABS", "ABS" },
	["set.counter"] = { "Countersteer help", "Countersteer အကူ" },
	["set.offPro"] = { "OFF (PRO)", "ပိတ် (PRO)" },
	["set.smoke"] = { "Tyre smoke", "တာယာ မီးခိုး" },
	["set.marks"] = { "Tyre marks", "တာယာ ရာ" },
	["set.controls"] = { "Controls on screen", "မျက်နှာပြင်ပေါ် ခလုတ်များ" },
	["set.sfx"] = { "Sound effects", "အသံ effect များ" },
	["set.music"] = { "Music", "သီချင်း" },
	["set.hints"] = { "Hints", "အကြံပြုချက်များ" },
	["set.photo"] = { "Photo mode", "ဓာတ်ပုံ mode" },
	["set.driveOutFirst"] = { "Drive your car out first", "ကား အရင် ထုတ်မောင်းပါ" },
	["set.hide"] = { "HIDE", "ဖျောက်မည်" },

	-- starter car pick
	["starter.packTitle"] = { "Starter Pack: pick your car", "Starter Pack: ကား ရွေးပါ" },
	["starter.title"] = { "Pick your first car", "ပထမဆုံးကား ရွေးပါ" },
	["starter.packSub"] = { "One of these, yours for good. Cars you own are greyed out.", "ဒီထဲက တစ်စီး၊ အပြီးပိုင်ပါပြီ။ ပိုင်ပြီးသားကားများကို မီးခိုးရောင် ပြထားသည်။" },
	["starter.sub"] = { "It's yours for good. You can buy more at Rider Auto.", "အပြီးပိုင်ပါပြီ။ Rider Auto မှာ ထပ်ဝယ်နိုင်သည်။" },
	["starter.ownIt"] = { "You own the %s: pick another", "%s ကို ပိုင်ပြီးပါပြီ: နောက်တစ်စီး ရွေးပါ" },
	["starter.claimThe"] = { "CLAIM THE %s", "%s ကို ယူမည်" },
	["starter.pickAbove"] = { "PICK A CAR ABOVE", "အပေါ်က ကား ရွေးပါ" },
	["starter.packCar"] = { "STARTER PACK CAR", "STARTER PACK ကား" },
	["starter.firstCar"] = { "YOUR FIRST CAR", "သင့် ပထမဆုံးကား" },

	-- cars tab (garage)
	["cars.pick"] = { "Pick a car", "ကား ရွေးပါ" },
	["cars.engineRepair"] = { "ENGINE NEEDS REPAIR", "အင်ဂျင် ပြင်ရန် လိုသည်" },
	["cars.serviceDue"] = { "SERVICE DUE", "Service ဝင်ရန် ကျပြီ" },
	["cars.worth"] = { "WORTH %s", "တန်ဖိုး %s" },
	["cars.tows"] = { "TOWS %s KG", "%s KG ဆွဲနိုင်" },
	["cars.driving"] = { "DRIVING ✓", "မောင်းနေသည် ✓" },
	["cars.finishFirst"] = { "Finish your race or job first", "ပြိုင်ပွဲ သို့မဟုတ် အလုပ်ကို အရင် ပြီးအောင်လုပ်ပါ" },
	["cars.favourite"] = { "FAVOURITE", "အကြိုက်ဆုံး" },
	["cars.favourites"] = { "FAVOURITES", "အကြိုက်ဆုံးများ" },
	["cars.sellMarket"] = { "SELL / MARKET", "ရောင်း / ဈေး" },
	["cars.upgrade"] = { "UPGRADE", "အဆင့်မြှင့်" },
	["cars.customise"] = { "CUSTOMISE", "ပြင်ဆင်မည်" },
	["cars.trailer"] = { "TRAILER", "TRAILER" },
	["cars.trailerBuy"] = { "Buy one at Rider Auto: TRAILERS.", "Rider Auto ရဲ့ TRAILERS မှာ ဝယ်ပါ။" },
	["cars.trailerOn"] = { "On it: %s", "ပေါ်မှာ: %s" },
	["cars.trailerHitched"] = { "Hitched to your car.", "သင့်ကားနဲ့ ချိတ်ထားသည်။" },
	["cars.trailerParked"] = { "Parked out on the road.", "လမ်းပေါ်မှာ ရပ်ထားသည်။" },
	["cars.trailerHome"] = { "In your garage.", "ကားဂိုဒေါင်ထဲမှာ။", true },
	["cars.towWith"] = { "TOW WITH THIS CAR", "ဒီကားနဲ့ ဆွဲမည်" },
	["cars.cantTow"] = { "This car can't tow. Pick one with the TOWS tag.", "ဒီကား မဆွဲနိုင်ပါ။ TOWS ပါတဲ့ကား ရွေးပါ။" },
	["cars.parkHere"] = { "PARK IT HERE", "ဒီမှာ ရပ်မည်" },
	["cars.loadCar"] = { "LOAD THIS CAR", "ဒီကား တင်မည်" },
	["cars.trailerAway"] = { "PUT TRAILER AWAY", "Trailer သိမ်းမည်" },
	["cars.selected"] = { "✔ SELECTED", "✔ ရွေးထားသည်" },
	["cars.ownedCount"] = { "%d / %d owned", "%d / %d ပိုင်ထားသည်" },
	["cars.getMore"] = { "Get more cars  ·  Rider Auto", "ကား ထပ်ယူရန်  ·  Rider Auto" },
	["cars.putAway"] = { "Car put away · G for the garage", "ကား သိမ်းပြီး · ကားဂိုဒေါင်အတွက် G" },
	["cars.cantGetIn"] = { "Could not get into the car, try again", "ကားထဲ ဝင်မရပါ၊ ထပ်ကြိုးစားပါ" },
	["cars.cantSpawn"] = { "Could not spawn the car, try again", "ကား ထုတ်မရပါ၊ ထပ်ကြိုးစားပါ" },
	["cars.cantPlaceCar"] = { "Can't put the car there right now, try again", "ယခု ကားကို ထိုနေရာ မချနိုင်ပါ၊ ထပ်ကြိုးစားပါ" },
	["cars.cantPlaceYou"] = { "Can't put you there right now, try again", "ယခု သင့်ကို ထိုနေရာ မပို့နိုင်ပါ၊ ထပ်ကြိုးစားပါ" },

	-- store
	["store.pickCar"] = { "PICK YOUR CAR", "ကား ရွေးပါ" },
	["store.needHouse"] = { "NEED A HOUSE", "အိမ် လိုသည်" },
	["store.soon"] = { "%s: coming soon", "%s: မကြာမီ လာမည်" },
	["store.ownIt"] = { "%s: you own it", "%s: ပိုင်ပြီးပါပြီ" },
	["store.garageNeedHouse"] = { "Garage Space: place a house with room for one more space first (Legends Realty)", "Garage Space: နေရာ တစ်ခု ထပ်ဆံ့တဲ့ အိမ်ကို အရင်ချပါ (Legends Realty)" },
	["store.cash2x"] = { "2x Cash", "ငွေ 2 ဆ", true },
	["store.cash2xDesc"] = { "Double the cash from driving, cut-ups and jobs, for good", "မောင်းခြင်း၊ cut-up နှင့် အလုပ်များမှ ငွေ 2 ဆ၊ အမြဲတမ်း" },
	["store.vip"] = { "VIP", "VIP" },
	["store.vipDesc"] = { "A VIP tag, free VIP bays in every tower garage and +10% cash from cut-ups", "VIP tag၊ tower ကားဂိုဒေါင်တိုင်းမှာ အခမဲ့ VIP နေရာ နှင့် cut-up မှ ငွေ +10%" },
	["store.doublePay"] = { "Double Pay", "လစာ 2 ဆ", true },
	["store.doublePayDesc"] = { "Double the pay from every job, for good", "အလုပ်တိုင်းမှ လစာ 2 ဆ၊ အမြဲတမ်း" },
	["store.starter"] = { "STARTER PACK", "STARTER PACK" },
	["store.starterDesc"] = { "$50,000 + a starter car you pick. Once per player", "$50,000 + ကိုယ်ရွေးတဲ့ ကားတစ်စီး။ တစ်ယောက် တစ်ကြိမ်သာ" },
	["store.garage"] = { "Garage Space", "ကားဂိုဒေါင် နေရာ", true },
	["store.garageDesc"] = { "One more garage space at the house you live in", "နေထိုင်တဲ့ အိမ်မှာ ကားဂိုဒေါင် နေရာ တစ်ခု ထပ်တိုး" },
	["store.payLink"] = { "2x with Double Pay  ›", "Double Pay ဖြင့် 2 ဆ  ›" },

	-- houses (main menu tab)
	["house.mine"] = { "My House", "ကိုယ့်အိမ်", true },
	["house.cantGoHome"] = { "Couldn't get you home", "အိမ် ပြန်ပို့မရပါ" },
	["house.settings"] = { "House Settings", "အိမ် ဆက်တင်" },
	["house.settingsSub"] = { "Who can come in, roommates, garage", "ဘယ်သူ ဝင်ခွင့်ရှိလဲ၊ အခန်းဖော်၊ ကားဂိုဒေါင်" },
	["house.realtySub"] = { "Buy a house, then claim a FOR SALE lot  ·  fast travel there", "အိမ်ဝယ်ပြီး FOR SALE မြေကွက် ယူပါ  ·  ချက်ချင်းသွားရန်" },
	["house.blueprints"] = { "Blueprints", "ပုံစံများ" },
	["house.tierLot"] = { "%s tier  ·  %s\nLot %s", "%s အဆင့်  ·  %s\nမြေကွက် %s" },
	["house.teleport"] = { "TELEPORT HOME", "အိမ်သို့ Teleport" },
	["house.nothingStanding"] = { "Nothing standing in this server yet. Put your house back, or claim a FOR SALE lot of its tier.", "ဒီ server မှာ အိမ် မရှိသေးပါ။ အိမ်ကို ပြန်ချပါ၊ သို့မဟုတ် အဆင့်တူ FOR SALE မြေကွက် ယူပါ။" },
	["house.place"] = { "PLACE MY HOUSE", "အိမ် ချမည်" },
	["house.noHouse"] = { "You don't own a house yet. Pick one at Legends Realty, then claim a lot.", "အိမ် မပိုင်သေးပါ။ Legends Realty မှာ ရွေးပြီး မြေကွက် ယူပါ။" },
	["house.seeHouses"] = { "SEE THE HOUSES", "အိမ်များ ကြည့်မည်" },
	["house.noneYet"] = { "None yet  ·  open the catalogue", "မရှိသေးပါ  ·  စာရင်း ဖွင့်ပါ" },
	["house.ownedCount"] = { "%s owned: %s", "%s ပိုင်ထား: %s" },

	-- jobs tab, job bar, job center
	["jobs.center"] = { "JOB CENTER", "အလုပ်စင်တာ", true },
	["jobs.take"] = { "TAKE JOB", "အလုပ်ဝင်မည်" },
	["jobs.quit"] = { "QUIT", "အလုပ်ထွက်မည်" },
	["jobs.get"] = { "GET %s", "%s ယူမည်" },
	["jobs.vehicleNote"] = { "%s: only you can drive it. It goes when you quit", "%s: သင်သာ မောင်းနိုင်သည်။ အလုပ်ထွက်ရင် ပျောက်မည်" },
	["jobs.rankLine"] = { "R%d/%d %s  ·  %s a paycheck%s", "R%d/%d %s  ·  လစာ %s%s" },
	["jobs.youQuit"] = { "You quit: %s", "အလုပ်ထွက်ပြီး: %s" },
	["jobs.goPost"] = { "%s: follow the gold waypoint to %s. You're paid while you stand at your post", "%s: ရွှေရောင် ဦးတည်ရာအတိုင်း %s သို့ သွားပါ။ ကိုယ့်နေရာမှာ ရပ်နေသရွေ့ လစာ ရမည်" },
	["jobs.onJob"] = { "%s: you're on the job", "%s: အလုပ် စပြီ" },
	["jobs.tapGet"] = { ". Tap GET %s for your vehicle", "။ ကားအတွက် %s ယူမည် ကို နှိပ်ပါ" },
	["jobs.followRing"] = { ". Follow the gold ring", "။ ရွှေရောင်ကွင်းအတိုင်း လိုက်ပါ" },
	["jobs.job"] = { "JOB", "အလုပ်" },
	["jobs.pay"] = { "PAY", "လစာ" },
	["jobs.paycheck"] = { "PAYCHECK", "လစာ" },
	["jobs.paycheck2"] = { "PAYCHECK x2", "လစာ x2" },
	["jobs.offKeep"] = { "Off duty: keep working?", "အလုပ်ချိန် ပြင်ပ: ဆက်လုပ်မလား?" },
	["jobs.goToPost"] = { "Go to your post", "ကိုယ့်နေရာကို သွားပါ" },
	["jobs.offDrive"] = { "Off duty: drive the job", "အလုပ်ချိန် ပြင်ပ: အလုပ်ကို မောင်းပါ" },
	["jobs.onDuty"] = { "ON DUTY · %s in %s", "အလုပ်ချိန် · %s · %s" },
	["jobs.standHere"] = { "%s · stand here", "%s · ဒီမှာ ရပ်ပါ" },
	["jobs.busStop"] = { "BUS STOP", "ဘတ်စ်ကားမှတ်တိုင်" },
	["jobs.pickUp"] = { "PICK UP", "ခေါ်ရန်" },
	["jobs.dropOff"] = { "DROP OFF", "ချရန်" },
	["jobs.patrol"] = { "PATROL · stop for radar", "ကင်းလှည့် · radar အတွက် ရပ်ပါ" },
	["jobs.deliveryRing"] = { "DELIVERY · stop in the blue ring", "ပစ္စည်းပို့ · အပြာကွင်းထဲ ရပ်ပါ" },
	["jobs.keepWorking"] = { "KEEP WORKING", "ဆက်လုပ်မည်" },
	["jobs.stillOn"] = { "STILL ON SHIFT?", "အလုပ် ဆက်လုပ်နေတုန်းလား?" },
	["jobs.offStillOn"] = { "OFF DUTY · STILL ON SHIFT?", "အလုပ်ချိန် ပြင်ပ · ဆက်လုပ်နေတုန်းလား?" },
	["jobs.stillOnText"] = { "Still on shift? Tap KEEP WORKING within %d min, or you go off duty", "ဆက်လုပ်နေတုန်းလား? %d မိနစ်အတွင်း ဆက်လုပ်မည် ကို နှိပ်ပါ၊ မဟုတ်ရင် အလုပ်ချိန် ပြီးမည်" },
	["jobs.noAnswer"] = { "Off duty: no answer. Tap KEEP WORKING to start again", "အလုပ်ချိန် ပြီး: အဖြေ မရပါ။ ပြန်စရန် ဆက်လုပ်မည် ကို နှိပ်ပါ" },
	["jobs.promoted"] = { "PROMOTED: %s rank %d: paycheck now %s", "ရာထူးတိုး: %s အဆင့် %d: လစာ %s" },
	["jobs.clocked"] = { "Officer %s clocked you at %d km/h (limit %d)", "ရဲ %s က %d km/h ဖြင့် ဖမ်းမိသည် (ကန့်သတ် %d)" },
	["jobs.backAtPost"] = { "Back at your post: still on duty", "ကိုယ့်နေရာ ပြန်ရောက်: အလုပ်ချိန် ဆက်ရှိ" },
	-- job names, what they do, ranks (Config.Jobs / JobsData)
	["job.delivery"] = { "Delivery", "ပစ္စည်းပို့" },
	["job.taxi"] = { "Taxi", "တက္ကစီ" },
	["job.bus"] = { "YBS Bus Driver", "YBS ကားမောင်း" },
	["job.police"] = { "Traffic Police", "ယာဉ်ထိန်းရဲ" },
	["job.tea"] = { "Tea Shop", "လက်ဖက်ရည်ဆိုင်" },
	["job.fuel"] = { "Fuel Station", "ဆီဆိုင်" },
	["job.dealer"] = { "Dealership Staff", "ကားအရောင်းဆိုင် ဝန်ထမ်း" },
	["job.mall"] = { "Mall Shop", "Mall ဆိုင်" },
	["jobWhat.delivery"] = { "Pick up parcels at the dispatch rings and drop them across town.", "ပို့ဆောင်ရေးကွင်းမှာ ပါဆယ်ယူပြီး မြို့တစ်ဝှမ်း ပို့ပါ။" },
	["jobWhat.taxi"] = { "Drive to the pickup, then take the fare where they want to go.", "ခရီးသည်ဆီ မောင်းသွားပြီး သူတို့ သွားချင်တဲ့နေရာ ပို့ပါ။" },
	["jobWhat.bus"] = { "Drive the YBS line: stop at each of the 7 real bus stops.", "YBS လိုင်း မောင်းပါ: တကယ့် မှတ်တိုင် 7 ခုစလုံးမှာ ရပ်ပါ။" },
	["jobWhat.police"] = { "Patrol points, and ticket real players who speed past you.", "ကင်းလှည့်ပါ၊ အရှိန်လွန် မောင်းသွားတဲ့ ကစားသမားများကို ဒဏ်ရိုက်ပါ။" },
	["jobWhat.tea"] = { "Stand at the counter. Serve customers for tips.", "ကောင်တာမှာ ရပ်ပါ။ ဧည့်သည်များကို ဧည့်ခံပြီး tip ရယူပါ။" },
	["jobWhat.fuel"] = { "Work the pumps. Fill customers' tanks for tips.", "ဆီပန့်မှာ လုပ်ပါ။ ဆီဖြည့်ပေးပြီး tip ရယူပါ။" },
	["jobWhat.dealer"] = { "Work the showroom floor. Help buyers for tips.", "ပြခန်းမှာ လုပ်ပါ။ ဝယ်သူများကို ကူညီပြီး tip ရယူပါ။" },
	["jobWhat.mall"] = { "Work the boutique counter. Serve shoppers for tips.", "ဆိုင်ကောင်တာမှာ လုပ်ပါ။ ဈေးဝယ်သူများကို ဧည့်ခံပြီး tip ရယူပါ။" },
	["jobServe.tea"] = { "Serve tea", "လက်ဖက်ရည် ချပေးမည်" },
	["jobServe.fuel"] = { "Fill a tank", "ဆီဖြည့်ပေးမည်" },
	["jobServe.dealer"] = { "Help a buyer", "ဝယ်သူ ကူညီမည်" },
	["jobServe.mall"] = { "Serve a shopper", "ဈေးဝယ်သူ ဧည့်ခံမည်" },
	["jobRank.delivery"] = { "Parcel Runner|Van Driver|Senior Courier|Route Boss|Express Chief", "ပါဆယ်ပို့သူ|ဗင်ကားဆရာ|အကြီးတန်း ပို့ဆောင်သူ|လမ်းကြောင်း ဘော့စ်|Express အကြီးအကဲ", true },
	["jobRank.taxi"] = { "Night Cabbie|City Driver|Airport Regular|Top Fare|Taxi Legend", "ညဘက် တက္ကစီဆရာ|မြို့တွင်း ကားဆရာ|လေဆိပ် ပုံသေဆရာ|ထိပ်တန်း တက္ကစီ|တက္ကစီ Legend", true },
	["jobRank.bus"] = { "Spare Boy|Bus Driver|Line Driver|Route Captain|YBS Legend", "စပယ်ယာ|ဘတ်စ်ကား ဒရိုင်ဘာ|လိုင်းကား ဒရိုင်ဘာ|လိုင်းခေါင်း|YBS Legend", true },
	["jobRank.police"] = { "Cadet|Constable|Sergeant|Inspector|Traffic Chief", "ရဲလေ့ကျင့်သား|ရဲတပ်သား|ရဲတပ်ကြပ်|ရဲအုပ်|ယာဉ်ထိန်း အကြီးအကဲ", true },
	["jobRank.tea"] = { "Table Boy|Tea Maker|Head Brewer|Shop Manager|Tea House Owner", "စားပွဲထိုး|လက်ဖက်ရည်ဆရာ|လက်ဖက်ရည်ဆရာကြီး|ဆိုင်မန်နေဂျာ|ဆိုင်ပိုင်ရှင်", true },
	["jobRank.fuel"] = { "Pump Attendant|Cashier|Shift Lead|Station Manager|Station Owner", "ဆီထိုး ဝန်ထမ်း|ငွေကိုင်|အဆိုင်း ခေါင်းဆောင်|ဆီဆိုင် မန်နေဂျာ|ဆီဆိုင် ပိုင်ရှင်", true },
	["jobRank.dealer"] = { "Car Washer|Sales Associate|Senior Sales|Sales Manager|General Manager", "ကားဆေးသူ|အရောင်း ဝန်ထမ်း|အကြီးတန်း အရောင်း|အရောင်း မန်နေဂျာ|အထွေထွေ မန်နေဂျာ", true },
	["jobRank.mall"] = { "Shop Helper|Sales Clerk|Senior Clerk|Floor Manager|Boutique Owner", "ဆိုင် အကူ|အရောင်း စာရေး|အကြီးတန်း စာရေး|Floor မန်နေဂျာ|ဆိုင်ပိုင်ရှင်", true },

	-- driving HUD
	["hud.tapStart"] = { "Tap to start up", "စက်နှိုးရန် နှိပ်ပါ" },
	["hud.pressStart"] = { "Press F to start up", "စက်နှိုးရန် F နှိပ်ပါ" },
	["hud.signalL"] = { "◀ SIGNAL", "◀ အချက်ပြ" },
	["hud.signalR"] = { "SIGNAL ▶", "အချက်ပြ ▶" },
	["hud.hazard"] = { "HAZARD", "အရေးပေါ်မီး" },
	["hud.firstPerson"] = { "1ST PERSON", "1ST PERSON", true },
	["hud.parkBrake"] = { "PARK BRAKE", "လက်ဘရိတ်" },
	["hud.brake"] = { "BRAKE", "ဘရိတ်" },
	["hud.gas"] = { "GAS", "လီဗာ" },
	["hud.cruiseUp"] = { "CRUISE +", "CRUISE +" },
	["hud.cruiseDown"] = { "CRUISE −", "CRUISE −" },
	["hud.cruise"] = { "CRUISE %s", "CRUISE %s" },
	["hud.putAway"] = { "PUT AWAY", "သိမ်းမည်" },
	["hud.engineOff"] = { "ENGINE OFF", "စက်ရပ်ထား" },
	["hud.tcOff"] = { "TC OFF", "TC OFF" },
	["hud.checkEngine"] = { "CHECK ENGINE", "အင်ဂျင် စစ်ပါ" },
	["hud.lowFuel"] = { "LOW FUEL", "ဆီနည်းနေ" },
	["hud.lowBattery"] = { "LOW BATTERY", "ဘက်ထရီ နည်းနေ" },
	["hud.carLvMax"] = { "CAR LV MAX", "ကား LV MAX" },
	["hud.lights"] = { "LIGHTS", "မီး" },
	["hud.doors"] = { "DOORS", "တံခါး" },
	["hud.fuel"] = { "FUEL", "ဆီ" },
	["hud.towing"] = { "TOWING", "ဆွဲနေသည်" },
	["hud.getOut"] = { "GET OUT", "ဆင်းမည်" },
	["hud.getIn"] = { "GET IN", "တက်မည်" },
	["hud.menu"] = { "MENU", "မီနူး" },
	["hud.photo"] = { "PHOTO", "ဓာတ်ပုံ" },
	["hud.radio"] = { "RADIO · %s", "ရေဒီယို · %s" },
	["hud.radioOff"] = { "Radio off", "ရေဒီယို ပိတ်" },
	["hud.combo"] = { "x%d COMBO", "x%d COMBO" },
	["hud.cutUp"] = { "CUT UP", "CUT UP", true },
	["hud.levelUp"] = { "LEVEL UP!", "Level တက်ပြီ!" },
	["hud.levelReached"] = { "Level %d reached!", "Level %d ရောက်ပြီ!" },
	["hud.headMove"] = { "Head move", "ခေါင်း လှုပ်ရှားမှု" },
	["hud.cameraFx"] = { "Camera FX", "ကင်မရာ FX" },
	["hud.setUp"] = { "SET UP", "ပြင်ဆင်မည်" },
	-- PC key help
	["keys.throttle"] = { "Throttle  ·  brake / reverse", "လီဗာ  ·  ဘရိတ် / နောက်ဆုတ်" },
	["keys.start"] = { "Start the car · get out / get in", "စက်နှိုး · ဆင်း / တက်" },
	["keys.doors"] = { "Scissor doors up / down (when parked)", "Scissor တံခါး ဖွင့် / ပိတ် (ရပ်ထားချိန်)" },
	["keys.shift"] = { "Shift down / up (manual)", "ဂီယာ ချ / တင် (manual)" },
	["keys.handbrake"] = { "Handbrake on / off", "လက်ဘရိတ် ဖွင့် / ပိတ်" },
	["keys.handbrakeHold"] = { "Handbrake while held (drift)", "ဖိထားစဉ် လက်ဘရိတ် (drift)" },
	["keys.tc"] = { "Traction control on / off", "Traction control ဖွင့် / ပိတ်" },
	["keys.lights"] = { "Lights on / off", "မီး ဖွင့် / ပိတ်" },
	["keys.blinkers"] = { "Left blinker · hazards · right blinker", "ဘယ်အချက်ပြ · အရေးပေါ်မီး · ညာအချက်ပြ" },
	["keys.firstPerson"] = { "First person  (SHIFT + V: other views)", "First person  (SHIFT + V: အခြား မြင်ကွင်း)" },
	["keys.rightMouse"] = { "RIGHT MOUSE", "ညာဘက် MOUSE" },
	["keys.look"] = { "Hold and move: look around the car", "ဖိပြီး ရွှေ့: ကားပတ်လည် ကြည့်" },
	["keys.radio"] = { "Radio: next station", "ရေဒီယို: နောက်ချန်နယ်" },
	["keys.reset"] = { "Reset car to road", "ကား လမ်းပေါ် ပြန်တင်" },
	["keys.freeCam"] = { "Free camera (also O)", "လွတ်လပ် ကင်မရာ (O လည်းရ)" },
	["keys.myCars"] = { "My cars", "ကိုယ့်ကားများ" },
	["keys.market"] = { "Car stock market", "ကား စတော့ဈေး" },
	["keys.gearbox"] = { "Automatic / sequential (in a car) · music on foot", "Auto / sequential (ကားထဲ) · လမ်းလျှောက်စဉ် သီချင်း" },
	-- driving toasts (Driving, CarLamps, CarDoors, OnFoot)
	["drive.noCruiseRace"] = { "No cruise control in a race or on a job", "ပြိုင်ပွဲ သို့မဟုတ် အလုပ်မှာ cruise control မရပါ" },
	["drive.cruiseFrom"] = { "Cruise control works from %s", "Cruise control ကို %s မှ စသုံးနိုင်သည်" },
	["drive.cruiseOffTraffic"] = { "Cruise off: traffic ahead", "Cruise ပိတ်: ရှေ့မှာ ကားရှိသည်" },
	["drive.battery"] = { "Battery empty", "ဘက်ထရီ ကုန်ပြီ" },
	["drive.electric"] = { "Electric: one gear, just drive", "လျှပ်စစ်ကား: ဂီယာ တစ်ခုတည်း၊ မောင်းရုံပဲ" },
	["drive.automatic"] = { "Automatic: press M for sequential (Q / E)", "Auto: sequential အတွက် M နှိပ်ပါ (Q / E)" },
	["drive.sequential"] = { "Sequential: Q / E to shift", "Sequential: ဂီယာ ပြောင်းရန် Q / E" },
	["drive.handbrakeOn"] = { "Handbrake on", "လက်ဘရိတ် ဆွဲထား" },
	["drive.handbrakeOff"] = { "Handbrake off", "လက်ဘရိတ် ချထား" },
	["drive.tcOn"] = { "Traction control on", "Traction control ဖွင့်" },
	["drive.tcOff"] = { "Traction control off", "Traction control ပိတ်" },
	["drive.lightsOn"] = { "Lights on", "မီး ဖွင့်" },
	["drive.lightsOff"] = { "Lights off", "မီး ပိတ်" },
	["drive.lowBeam"] = { "LOW BEAM", "မီးနိမ့်" },
	["drive.highBeam"] = { "HIGH BEAM", "မီးမြင့်" },
	["drive.lightsOffCaps"] = { "LIGHTS OFF", "မီး ပိတ်" },
	["drive.lightsMode"] = { "Lights: %s", "မီး: %s" },
	["drive.launch"] = { "Launch control: let go of the brake", "Launch control: ဘရိတ် လွှတ်ပါ" },
	["drive.radio"] = { "Radio: %s", "ရေဒီယို: %s" },
	["drive.backOnRoad"] = { "Back on the road", "လမ်းပေါ် ပြန်ရောက်ပြီ", true },
	["drive.stopForDoors"] = { "Stop the car to open the doors", "တံခါးဖွင့်ရန် ကားကို ရပ်ပါ" },
	["foot.slowDown"] = { "Slow down to get out", "ဆင်းရန် အရှိန် လျှော့ပါ" },
	["foot.cantGetOut"] = { "Can't get out here", "ဒီမှာ ဆင်းလို့ မရပါ" },
	["foot.noSeat"] = { "No free seat here", "ဒီမှာ ထိုင်ခုံ မလွတ်ပါ" },

	-- daily gift and streak
	["daily.gift"] = { "DAILY GIFT", "နေ့စဉ် လက်ဆောင်" },
	["daily.giftSub"] = { "Free cash every 24 hours.\nGrows with your level.", "24 နာရီတိုင်း အခမဲ့ ငွေ။\nLevel မြင့်လေ များလေ။" },
	["daily.streak"] = { "DAILY STREAK", "နေ့စဉ် Streak" },
	["daily.streakDay"] = { "DAILY STREAK  ·  DAY %d", "နေ့စဉ် Streak  ·  နေ့ %d" },
	["daily.claimPlus"] = { "CLAIM  +%s", "ယူမည်  +%s" },
	["daily.next"] = { "NEXT  %s", "နောက်တစ်ခု  %s" },
	["daily.opensIn"] = { "Day %d of your streak opens in %s", "Streak နေ့ %d ကို %s အကြာတွင် ဖွင့်မည်" },
	["daily.notReady"] = { "Your streak isn't ready yet", "Streak မရသေးပါ" },
	["daily.claimFailed"] = { "Could not claim the gift, try again", "လက်ဆောင် ယူမရပါ၊ ထပ်ကြိုးစားပါ" },
	["daily.day7"] = { "DAY 7: FREE CAR", "နေ့ 7: အခမဲ့ကား" },
	["daily.freeCar"] = { "FREE CAR", "အခမဲ့ကား" },
	["daily.rules"] = { "Come back every day. Day 7 gives you a free car you don't own yet.\nMiss more than 2 days and the streak starts again at day 1.", "နေ့တိုင်း ပြန်လာပါ။ နေ့ 7 မှာ မပိုင်သေးတဲ့ ကား တစ်စီး အခမဲ့ ရမည်။\n2 ရက်ထက် ပိုလွတ်ရင် streak က နေ့ 1 က ပြန်စမည်။" },
	["daily.claimDay"] = { "CLAIM DAY %d", "နေ့ %d ယူမည်" },

	-- goals
	["goals.path"] = { "LEGENDS PATH", "LEGENDS PATH" },
	["goals.pathCount"] = { "LEGENDS PATH  %d/%d", "LEGENDS PATH  %d/%d" },
	["goals.ggQuest"] = { "GG QUEST", "GG QUEST" },
	["goals.ggCount"] = { "GG QUEST  %d/%d", "GG QUEST  %d/%d" },
	["goals.daily"] = { "DAILY", "နေ့စဉ်" },
	["goals.allDone"] = { "Every goal done: a true legend", "ပန်းတိုင် အားလုံး ပြီးပြီ: တကယ့် Legend ပဲ" },
	["goals.newIn"] = { "NEW TASKS IN %s", "%s အကြာတွင် တာဝန်သစ်" },
	["goals.loading"] = { "Goals are still loading: try again", "ပန်းတိုင်များ ဖွင့်နေဆဲ: ထပ်ကြိုးစားပါ" },
	["goals.ggBanner"] = { "GG GAMING FEST · 21-22 NOV · YANGON CONVENTION CENTRE · %d PTS", "GG GAMING FEST · နိုဝင်ဘာ 21-22 · ရန်ကုန် ကွန်ဗင်းရှင်း စင်တာ · %d မှတ်", true },
	["goals.pathDone"] = { "LEGENDS PATH: %d OF %d DONE", "LEGENDS PATH: %d/%d ပြီး" },
	["goals.pathDonePays"] = { "LEGENDS PATH: %d OF %d DONE  ·  each goal pays the moment you finish it", "LEGENDS PATH: %d/%d ပြီး  ·  ပန်းတိုင် ပြီးတာနဲ့ ချက်ချင်း ငွေရ" },
	["goals.threeDaily"] = { "3 NEW TASKS EVERY DAY", "နေ့တိုင်း တာဝန်သစ် 3 ခု" },
	["goals.dailyDone"] = { "DAILY TASK DONE", "နေ့စဉ် တာဝန် ပြီးပြီ" },
	["goals.ggPlus"] = { "GG QUEST +%s", "GG QUEST +%s" },
	["goals.ggLook"] = { "GGFEST LOOK UNLOCKED", "GGFEST ပုံစံ ရပြီ" },
	["goals.done"] = { "GOAL DONE", "ပန်းတိုင် ပြီးပြီ" },

	-- rewards (Legends Rewards, spin, codes)
	["rew.title"] = { "LEGENDS REWARDS", "LEGENDS REWARDS" },
	["rew.superSpin"] = { "SUPER SPIN", "SUPER SPIN" },
	["rew.serverFail"] = { "Couldn't reach the server: try again", "Server နဲ့ မချိတ်မိပါ: ထပ်ကြိုးစားပါ" },
	["rew.notReady"] = { "Not ready yet", "မရသေးပါ" },
	["rew.streak"] = { "%s STREAK", "%s STREAK" },
	["rew.carYours"] = { "The %s is yours! It's in your CARS", "%s ကို ရပြီ! ကားများ ထဲမှာ ရှိသည်" },
	["rew.readyCount"] = { "REWARDS READY  ·  %d", "ဆု ရပြီ  ·  %d" },
	["rew.nextGift"] = { "NEXT GIFT IN %s", "နောက်လက်ဆောင် %s အကြာ" },
	["rew.playtime"] = { "PLAYTIME TODAY: %s  ·  the gifts start again every day", "ဒီနေ့ ကစားချိန်: %s  ·  လက်ဆောင်များ နေ့တိုင်း ပြန်စ" },
	["rew.minutesPlayed"] = { "%d MINUTES PLAYED", "%d မိနစ် ကစားပြီး" },
	["rew.takenToday"] = { "Taken today", "ဒီနေ့ ယူပြီး" },
	["rew.opensIn"] = { "Opens in %s", "%s အကြာတွင် ဖွင့်မည်" },
	["rew.weekly"] = { "WEEKLY GIFT", "အပတ်စဉ် လက်ဆောင်" },
	["rew.weeklyReady"] = { "Ready: once every 7 days", "ရပြီ: 7 ရက် တစ်ခါ" },
	["rew.nextIn"] = { "Next in %s", "နောက်တစ်ခါ %s အကြာ" },
	["rew.welcomeBack"] = { "WELCOME BACK", "ပြန်လာတာ ကြိုဆိုပါတယ်" },
	["rew.welcomeBackSub"] = { "For coming back after a week away", "တစ်ပတ် ပျောက်ပြီး ပြန်လာလို့" },
	["rew.levelRule"] = { "Every level you reach pays %s x the level here, and every %dth level opens a chest of %s x the level.", "Level တစ်ခု တက်တိုင်း %s x Level ရမည်၊ Level %d ခုတိုင်းမှာ %s x Level သေတ္တာ ဖွင့်မည်။" },
	["rew.chest"] = { "CHEST", "သေတ္တာ" },
	["rew.nothingLevel"] = { "Nothing waiting. Level up to earn level rewards (you're level %d)", "ယူစရာ မရှိပါ။ Level ဆု ရရန် Level တင်ပါ (သင် Level %d)" },
	["rew.nothingClaim"] = { "NOTHING TO CLAIM", "ယူစရာ မရှိပါ" },
	["rew.friend"] = { "FRIEND BONUS", "သူငယ်ချင်း ဘောနပ်စ်" },
	["rew.friendIn"] = { "A friend is in your server", "သူငယ်ချင်း server ထဲ ရှိသည်" },
	["rew.friendHow"] = { "Play in the same server as a friend (once a day)", "သူငယ်ချင်းနဲ့ server တူ ကစားပါ (တစ်ရက် တစ်ခါ)" },
	["rew.invite"] = { "INVITE GIFT", "ဖိတ်ခေါ် လက်ဆောင်" },
	["rew.inviteDone"] = { "Your friend joined from your invite", "သင့်ဖိတ်ခေါ်မှုဖြင့် သူငယ်ချင်း ဝင်လာပြီ" },
	["rew.inviteHow"] = { "Invite a friend: when they join for the first time, you both get this", "သူငယ်ချင်း ဖိတ်ပါ: ပထမဆုံး ဝင်လာရင် နှစ်ယောက်လုံး ရမည်" },
	["rew.group"] = { "GROUP GIFT", "Group လက်ဆောင်" },
	["rew.groupDone"] = { "Thanks for joining the group", "Group ဝင်ပေးလို့ ကျေးဇူးပါ" },
	["rew.groupHow"] = { "Join the game's group on Roblox (one time)", "Roblox ပေါ်က ဂိမ်း Group ကို ဝင်ပါ (တစ်ကြိမ်)" },
	["rew.inviteBtn"] = { "INVITE FRIENDS", "သူငယ်ချင်း ဖိတ်မည်" },
	["rew.noInvites"] = { "Invites aren't available right now", "ယခု ဖိတ်လို့ မရပါ" },
	["rew.codeHow"] = { "Got a code? Type it here (it works once). New codes come with updates.", "Code ရှိလား? ဒီမှာ ရိုက်ပါ (တစ်ခါသာ သုံးရ)။ Update တိုင်း code သစ် ထွက်မည်။" },
	["rew.enterCode"] = { "ENTER CODE", "Code ထည့်မည်" },
	["rew.noPenthouse"] = { "No penthouse yet. A penthouse's wall safe pays rent every day: collect it here or at the safe.", "Penthouse မရှိသေးပါ။ Penthouse ရဲ့ နံရံ မီးခံသေတ္တာက နေ့တိုင်း အငှားခ ပေးသည်: ဒီမှာ သို့မဟုတ် သေတ္တာမှာ ကောက်ပါ။" },
	["rew.safeFull"] = { "The safe is full", "မီးခံသေတ္တာ ပြည့်နေပြီ" },
	["rew.refillsIn"] = { "Refills in %s", "%s အကြာတွင် ပြန်ပြည့်မည်" },
	["rew.suite"] = { "HOTEL SUITE", "ဟိုတယ် Suite" },
	["rew.suitePays"] = { "%s pays %s every minute you play, straight into your cash", "%s က ကစားတဲ့ မိနစ်တိုင်း %s ပေးသည်၊ ငွေထဲ တိုက်ရိုက်ဝင်" },
	["rew.suiteBuy"] = { "Buy a suite at the Novotel Yangon Max: it pays every minute you play", "Novotel Yangon Max မှာ suite ဝယ်ပါ: ကစားတဲ့ မိနစ်တိုင်း ငွေရ" },
	["rew.collectRent"] = { "COLLECT RENT", "အငှားခ ကောက်မည်" },
	["rew.noSafe"] = { "NO SAFE READY", "ကောက်စရာ မရှိသေး" },
	["rew.part"] = { "%s PART", "%s PART" },
	["rew.plusSpin"] = { "+1 SPIN", "+1 SPIN" },
	["rew.spinsLeft"] = { "SPINS LEFT", "လှည့်ခွင့် ကျန်" },
	["rew.odds"] = { "THE ODDS  ·  %s", "ဖြစ်နိုင်ခြေ  ·  %s" },
	["rew.oddsEach"] = { "each of the 3 reels", "reel 3 ခု တစ်ခုစီ" },
	["rew.oddsOne"] = { "the reel", "reel" },
	["rew.prizeCar"] = { "A free car (or %s)", "အခမဲ့ကား (သို့မဟုတ် %s)" },
	["rew.prizeJewel"] = { "A Gems Museum jewel (or %s)", "Gems Museum လက်ဝတ်ရတနာ (သို့မဟုတ် %s)" },
	["rew.prizePart"] = { "A free %s part", "အခမဲ့ %s part" },
	["rew.prizeSpin"] = { "One more spin", "နောက်ထပ် တစ်ခါ လှည့်ခွင့်" },
	["rew.buyOne"] = { "BUY 1  ·  %s", "1 ခု ဝယ်မည်  ·  %s" },
	["rew.oddsShown"] = { "ODDS SHOWN  ·  BUY %s", "ဖြစ်နိုင်ခြေ ပြထား  ·  %s ဝယ်မည်" },
	["rew.freeOnly"] = { "Free spins only", "အခမဲ့ လှည့်ခွင့်သာ" },
	["rew.freeReady"] = { "A FREE SPIN IS READY", "အခမဲ့ လှည့်ခွင့် ရပြီ" },
	["rew.nextFree"] = { "NEXT FREE SPIN\n%s", "နောက် အခမဲ့ လှည့်ခွင့်\n%s" },
	["rew.spinning"] = { "SPINNING...", "လှည့်နေသည်..." },
	["rew.spinFree"] = { "SPIN (FREE)", "လှည့်မည် (အခမဲ့)" },
	["rew.noSpins"] = { "NO SPINS LEFT", "လှည့်ခွင့် မကျန်ပါ" },
	["rew.noSpinsText"] = { "No spins left: buy one, or wait for the free spin", "လှည့်ခွင့် မကျန်ပါ: ဝယ်ပါ၊ သို့မဟုတ် အခမဲ့ လှည့်ခွင့်ကို စောင့်ပါ" },
	["rew.cantSpin"] = { "Can't spin now", "ယခု လှည့်လို့ မရပါ" },
	["rew.wonCar"] = { "You won the %s! It's in your CARS", "%s ကို နိုင်ပြီ! ကားများ ထဲမှာ ရှိသည်" },
	["rew.wonJewel"] = { "You won the %s! Wear it from the Gems Museum", "%s ကို နိုင်ပြီ! Gems Museum မှာ ဝတ်ပါ" },
	["rew.wonPart"] = { "You won the %s! It's in My Parts at the workshop", "%s ကို နိုင်ပြီ! အလုပ်ရုံရဲ့ My Parts ထဲမှာ ရှိသည်" },
	["rew.loading"] = { "Rewards are still loading: try again", "ဆုများ ဖွင့်နေဆဲ: ထပ်ကြိုးစားပါ" },
	["rew.readyAtDesks"] = { "%d READY  ·  claim at the desks in Legends Rewards (codes work anywhere)", "%d ခု ရပြီ  ·  Legends Rewards ကောင်တာမှာ ယူပါ (code ကို ဘယ်မှာမဆို သုံးရ)" },
	["rew.playtimeReady"] = { "Playtime gift ready (%d minutes): claim it at Legends Rewards", "ကစားချိန် လက်ဆောင် ရပြီ (%d မိနစ်): Legends Rewards မှာ ယူပါ" },

	-- dealership (Rider Auto) and the garage car card
	["deal.myCars"] = { "MY CARS", "ကိုယ့်ကားများ" },
	["deal.soldAt"] = { "NEW CARS ARE SOLD AT %s, THE DEALERSHIP", "ကားသစ်များကို ကားအရောင်းဆိုင် %s မှာ ရောင်းသည်" },
	["deal.buyHere"] = { "NEW CARS · BUY HERE, DRIVE OUT OF THE BAY", "ကားသစ်များ · ဒီမှာ ဝယ်ပြီး ထုတ်မောင်းပါ" },
	["deal.testDrive"] = { "TEST DRIVE", "စမ်းမောင်းမည်" },
	["deal.driveOut"] = { "DRIVE OUT", "ထုတ်မောင်းမည်" },
	["deal.marketOnly"] = { "MARKET ONLY", "ဈေးမှာသာ" },
	["deal.carMarket"] = { "CAR MARKET", "ကားဈေး" },
	["deal.unlocksAt"] = { "Unlocks at level %d (you're level %d)", "Level %d မှာ ဖွင့်မည် (သင် Level %d)" },
	["deal.testDriveText"] = { "Test drive: 5 minutes in the %s (it pays less)", "စမ်းမောင်း: %s ကို 5 မိနစ် (ငွေ နည်းနည်းပဲ ရ)" },
	["deal.noTestDrive"] = { "No test drive right now", "ယခု စမ်းမောင်းလို့ မရပါ" },
	["deal.testLeft"] = { "Test drive: %d seconds left", "စမ်းမောင်း: %d စက္ကန့် ကျန်" },
	["deal.testOver"] = { "Test drive over: back in your own car", "စမ်းမောင်းချိန် ပြီးပြီ: ကိုယ့်ကား ပြန်ရောက်ပြီ" },
	["deal.brandLv"] = { "BRAND LV %d", "BRAND LV %d" },
	["deal.brandOff"] = { "%d%% off at Optima Werkz", "Optima Werkz မှာ %d%% လျှော့" },
	["deal.topSpeed"] = { "Top speed", "အမြန်ဆုံး" },
	["deal.p2w"] = { "Power to weight", "ပါဝါ / အလေးချိန်" },
	["deal.braking"] = { "Braking", "ဘရိတ်" },
	["deal.weight"] = { "Weight", "အလေးချိန်" },
	["deal.length"] = { "Length", "အလျား" },
	["deal.width"] = { "Width", "အနံ" },
	["deal.height"] = { "Height", "အမြင့်" },
	["deal.yourLevel"] = { "YOUR LEVEL", "သင့် Level" },
	["deal.allModels"] = { "All %d models", "မော်ဒယ် %d မျိုး အားလုံး" },
	["deal.from"] = { "from %s", "%s မှစ" },
	["deal.trim"] = { "%s trim", "%s trim" },
	["deal.inGarage"] = { "IN YOUR GARAGE", "ကိုယ့်ကားဂိုဒေါင်ထဲ ရှိပြီး" },
	["deal.price"] = { "PRICE  ·  %s", "ဈေးနှုန်း  ·  %s" },
	["deal.brandBonus"] = { "-%d%% BRAND BONUS", "-%d%% BRAND ဘောနပ်စ်" },
	["deal.class"] = { "CLASS %s", "CLASS %s" },
	["deal.reachLevel"] = { " · REACH LEVEL %d", " · Level %d ရောက်ရန်" },
	["deal.trimOf"] = { "TRIM %d OF %d", "TRIM %d / %d" },
	["deal.factoryColour"] = { "Factory colour", "စက်ရုံ အရောင်" },
	["deal.classXAt"] = { "Class X opens at level %d", "Class X ကို Level %d မှာ ဖွင့်မည်" },
	["deal.allOpen"] = { "Every car is open to you", "ကားအားလုံး ဝယ်နိုင်ပြီ" },
	["deal.newCar"] = { "NEW CAR", "ကားသစ်" },
	["deal.driveNow"] = { "DRIVE IT NOW", "ချက်ချင်း မောင်းမည်" },
	["deal.keepLooking"] = { "KEEP LOOKING", "ဆက်ကြည့်မည်" },
	["deal.trailerWeighs"] = { "Weighs %s kg. Only cars tagged TOWS can pull it. Take it out from CARS.", "အလေးချိန် %s kg။ TOWS ပါတဲ့ ကားများသာ ဆွဲနိုင်သည်။ ကားများ ထဲမှ ထုတ်ပါ။" },
	["deal.trailerYours"] = { "%s is yours: CARS > TRAILER", "%s ကို ရပြီ: ကားများ > TRAILER" },
	["deal.cantBuy"] = { "Couldn't buy it", "ဝယ်လို့ မရပါ" },
	["deal.sellThis"] = { "SELL THIS CAR", "ဒီကား ရောင်းမည်" },
	["deal.pays"] = { "Rider Auto pays %s", "Rider Auto က %s ပေးမည်" },
	["deal.soldFor"] = { "Sold for %s", "%s ဖြင့် ရောင်းပြီး" },
	["deal.cantSell"] = { "Couldn't sell it", "ရောင်းလို့ မရပါ" },
	["deal.confirm"] = { "CONFIRM PURCHASE", "ဝယ်ယူမှု အတည်ပြုမည်" },
	["deal.classXNeed"] = { "Class X: reach level %d to buy this one", "Class X: ဒီကား ဝယ်ရန် Level %d ရောက်ပါ" },
	["deal.specs"] = { "SPECS", "အချက်အလက်" },
	["deal.paint"] = { "PAINT", "ဆေးရောင်" },
	["deal.trims"] = { "TRIMS", "TRIMS" },
	["deal.features"] = { "FEATURES", "ထူးခြားချက်များ" },
	["deal.performance"] = { "PERFORMANCE", "စွမ်းဆောင်ရည်" },
	["deal.vehicles"] = { "VEHICLES", "ယာဉ်များ" },
	["deal.trailers"] = { "TRAILERS", "TRAILERS" },
	["deal.oneSpeed"] = { "1-SPEED", "ဂီယာ 1 ခု" },

	-- workshop (parts) and car levels
	["shop.title"] = { "OPTIMA WERKZ", "OPTIMA WERKZ" },
	["shop.workshop"] = { "WORKSHOP", "အလုပ်ရုံ" },
	["shop.header"] = { "CAR LEVEL %d  ·  OPTIMA WERKZ WORKSHOP", "ကား LEVEL %d  ·  OPTIMA WERKZ အလုပ်ရုံ" },
	["shop.failed"] = { "Couldn't do that", "မလုပ်နိုင်ပါ" },
	["shop.fitted"] = { "%s fitted", "%s တပ်ပြီး" },
	["shop.inMyParts"] = { "%s is in My Parts", "%s ကို My Parts ထဲ ထည့်ပြီး" },
	["shop.backInParts"] = { "Back in My Parts", "My Parts ထဲ ပြန်ရောက်" },
	["shop.myParts"] = { "MY PARTS", "MY PARTS", true },
	["shop.with"] = { "with %s", "%s နှင့်" },
	["shop.overStock"] = { "over stock", "မူလထက်" },
	["shop.classUp"] = { "moves up to class %s", "Class %s သို့ တက်မည်" },
	["shop.classStill"] = { "still class %s (%s at %d)", "Class %s ပဲ (%s က %d တွင်)" },
	["shop.topClass"] = { "top class", "အမြင့်ဆုံး class" },
	["shop.stock"] = { "Stock %s", "မူလ %s" },
	["shop.stockCaps"] = { "STOCK", "မူလ" },
	["shop.fitStock"] = { "FIT STOCK", "မူလ ပြန်တပ်မည်" },
	["shop.needTurbo"] = { "Needs a turbo", "Turbo လိုသည်" },
	["shop.needSc"] = { "Needs a supercharger", "Supercharger လိုသည်" },
	["shop.needBoost"] = { "Needs a turbo or supercharger", "Turbo သို့မဟုတ် supercharger လိုသည်" },
	["shop.needTurboCaps"] = { "NEEDS A TURBO", "TURBO လို" },
	["shop.needScCaps"] = { "NEEDS A SC", "SC လို" },
	["shop.needBoostCaps"] = { "NEEDS BOOST", "BOOST လို" },
	["shop.noFit"] = { "DOESN'T FIT", "မတပ်နိုင်" },
	["shop.noFitCar"] = { "Doesn't fit this car", "ဒီကားနဲ့ မကိုက်ပါ" },
	["shop.fits"] = { "FITS", "ကိုက်သည်" },
	["shop.install"] = { "INSTALL %s", "%s တပ်မည်" },
	["shop.ownedInstall"] = { "OWNED · INSTALL", "ပိုင်ပြီး · တပ်မည်" },
	["shop.installed"] = { "INSTALLED", "တပ်ပြီး" },
	["shop.uninstall"] = { "UNINSTALL", "ဖြုတ်မည်" },
	["shop.slots"] = { "%d SLOTS · TAP ONE", "နေရာ %d ခု · တစ်ခု နှိပ်ပါ" },
	["shop.options"] = { "%d OPTIONS", "ရွေးစရာ %d ခု" },
	["shop.swaps"] = { "OPEN ENGINE SWAPS  ›", "အင်ဂျင် လဲရန် ဖွင့်မည်  ›" },
	["shop.ownedX"] = { "OWNED x%d", "ပိုင် x%d" },
	["shop.pickPart"] = { "Pick a part", "Part တစ်ခု ရွေးပါ" },
	["shop.perk"] = { "Perk: %s", "အထူး: %s" },
	["shop.engineInfo"] = { "%d hp stock, %d hp tuned max. Revs to %.1fk. %s%s", "မူလ %d hp၊ tune အများဆုံး %d hp။ %.1fk အထိ အရှိန်တင်။ %s%s" },
	["shop.sellOne"] = { "SELL ONE  %s", "တစ်ခု ရောင်းမည်  %s" },
	["shop.installFee"] = { "INSTALL · FEE %s", "တပ်မည် · ခ %s" },
	["shop.buyWith"] = { "BUY WITH %s", "%s ဖြင့် ဝယ်မည်" },
	["shop.buyInstall"] = { "BUY & INSTALL  %s", "ဝယ်ပြီး တပ်မည်  %s" },
	["shop.noSpare"] = { "No spare parts. Parts you take off a car come here", "အပို part မရှိပါ။ ကားမှ ဖြုတ်တဲ့ part များ ဒီမှာ ရောက်မည်" },
	["shop.noMatch"] = { "Nothing matches", "ကိုက်ညီတာ မရှိပါ" },
	["shop.paintAt"] = { "Paint and looks are at Optima Werkz: stop in the tuning bay", "ဆေးရောင်နဲ့ အလှဆင်ခြင်းက Optima Werkz မှာ: tuning bay ထဲ ရပ်ပါ" },
	["shop.pi"] = { "PERFORMANCE INDEX", "စွမ်းဆောင်ရည် အညွှန်း (PI)" },
	["shop.dyno"] = { "▶  DYNO RUN", "▶  DYNO RUN" },
	["shop.tuneNote"] = { "Small changes, free, saved on this car", "အသေးစား ပြင်ဆင်ချက်၊ အခမဲ့၊ ဒီကားမှာ သိမ်းထား" },
	["shop.savedAs"] = { "Saved as %s", "%s အဖြစ် သိမ်းပြီး" },
	["shop.backStock"] = { "Back to stock settings", "မူလ ဆက်တင်သို့ ပြန်" },
	["shop.hpGain"] = { "%d hp  →  %d hp  (%s%d)", "%d hp  →  %d hp  (%s%d)" },
	["shop.hpStock"] = { "%d hp  ·  stock", "%d hp  ·  မူလ" },
	["shop.torque"] = { "%d Nm    redline %.1fk", "%d Nm    redline %.1fk" },
	["shop.legend"] = { "POWER   TORQUE   STOCK", "ပါဝါ   TORQUE   မူလ" },
	["shop.tabShop"] = { "SHOP", "ဆိုင်" },
	["shop.tabTune"] = { "TUNE", "TUNE" },
	["shop.tabStyle"] = { "STYLE", "စတိုင်" },
	["shop.tabSwaps"] = { "SWAPS", "လဲလှယ်" },
	["shop.reset"] = { "RESET", "ပြန်စမည်" },
	["shop.save"] = { "SAVE", "သိမ်းမည်" },
	["shop.power"] = { "POWER", "ပါဝါ" },
	["shop.grip"] = { "GRIP", "ဖမ်းအား" },
	["shop.class"] = { "CLASS", "CLASS" },
	["rarity.common"] = { "Common", "Common", true },
	["rarity.uncommon"] = { "Uncommon", "Uncommon", true },
	["rarity.rare"] = { "Rare", "Rare", true },
	["rarity.epic"] = { "Epic", "Epic", true },
	["rarity.legendary"] = { "Legendary", "Legendary", true },
	["lvl.freePart"] = { "Free part: %s. It's in My Parts at the workshop", "အခမဲ့ part: %s။ အလုပ်ရုံရဲ့ My Parts ထဲမှာ ရှိသည်" },
	["lvl.carLevel"] = { "CAR LEVEL %d", "ကား LEVEL %d" },
	["lvl.cpGain"] = { "+%d CP for the %s: spend it on parts (garage: UPGRADE) or Optima Werkz", "+%d CP (%s အတွက်): part များ (ကားဂိုဒေါင်: အဆင့်မြှင့်) သို့မဟုတ် Optima Werkz မှာ သုံးပါ", true },
	["lvl.brandBonus"] = { "%s brand bonus: cheaper at Rider Auto", "%s brand ဘောနပ်စ်: Rider Auto မှာ ပိုသက်သာ" },

	-- Optima Werkz (paint)
	["cust.cantOpen"] = { "Can't open Optima Werkz now", "ယခု Optima Werkz ဖွင့်လို့ မရပါ" },
	["cust.drag"] = { "Drag to turn the car", "ကား လှည့်ရန် ဆွဲပါ" },
	["cust.dragPrices"] = { "Drag to turn the car  ·  prices for this car's class", "ကား လှည့်ရန် ဆွဲပါ  ·  ဒီကား class ရဲ့ ဈေးနှုန်း" },
	["cust.buyCash"] = { "BUY $", "$ ဖြင့် ဝယ်မည်" },
	["cust.buyCp"] = { "BUY CP", "CP ဖြင့် ဝယ်မည်" },
	["cust.total"] = { "TOTAL  %s  or  %d CP  (you have %d CP)", "စုစုပေါင်း  %s  သို့မဟုတ်  %d CP  (သင့်မှာ %d CP)" },
	["cust.noChanges"] = { "NO CHANGES", "ပြောင်းလဲမှု မရှိ" },
	["cust.perfParts"] = { "PERFORMANCE PARTS  ›", "စွမ်းဆောင်ရည် PART များ  ›" },
	["cust.secondColour"] = { "SECOND COLOUR", "ဒုတိယ အရောင်" },
	["cust.tint"] = { "WINDOW TINT", "မှန် အရောင်" },
	["cust.plate"] = { "NUMBER PLATE", "နံပါတ်ပြား" },
	["cust.yourPlate"] = { "YOUR PLATE", "ကိုယ့် နံပါတ်ပြား" },
	["cust.nothing"] = { "Nothing changed", "ဘာမှ မပြောင်းပါ" },
	["cust.saved"] = { "Optima Werkz: %s", "Optima Werkz: %s" },
	["cust.saveFailed"] = { "Couldn't save that", "သိမ်းလို့ မရပါ" },

	-- car market (MarketUI)
	["mkt.noAnswer"] = { "The market isn't answering, try again", "ဈေးက မတုံ့ပြန်ပါ၊ ထပ်ကြိုးစားပါ" },
	["mkt.paid"] = { "%s · paid %s", "%s · %s ပေးခဲ့" },
	["mkt.salePays"] = { "Market sale pays %s after the %d%% fee.%s", "ဈေးမှာ ရောင်းရင် %s ရမည် (ခ %d%% နုတ်ပြီး)။%s", true },
	["mkt.deliverable"] = { "\nShowroom units can be delivered: the car joins your garage.", "\nShowroom ကားများကို ပို့ပေးနိုင်သည်: ကားက ကိုယ့်ကားဂိုဒေါင်ထဲ ရောက်မည်။" },
	["mkt.takeDelivery"] = { "TAKE DELIVERY", "ကား ထုတ်ယူမည်" },
	["mkt.requests"] = { "Buyers pay a premium for these. New ones in %dh.", "ဝယ်သူများက ဒီကားများအတွက် ပိုပေးသည်။ %d နာရီအကြာ အသစ်။" },
	["mkt.orBetter"] = { "or better · pays %s", "သို့မဟုတ် ပိုကောင်း · %s ပေးမည်" },
	["mkt.needIt"] = { "NEED IT", "လိုသည်" },
	["mkt.stalls"] = { "Stalls · sell to the market", "ဆိုင်ခန်း · ဈေးကို ရောင်းပါ" },
	["mkt.instant"] = { "Instant sale at the market value, minus the %d%% fee (more hype, lower fee).", "ဈေးတန်ဖိုးဖြင့် ချက်ချင်း ရောင်း၊ %d%% ခ နုတ် (hype များလေ ခ နည်းလေ)။" },
	["mkt.stashEmpty"] = { "Your stash is empty: buy something in Listings.", "Stash ထဲ ဘာမှ မရှိပါ: Listings မှာ ဝယ်ပါ။" },
	["mkt.flipOffTitle"] = { "Flip-off vs Slick Vinny", "Slick Vinny နဲ့ Flip-off" },
	["mkt.flipOffRules"] = { "Three minutes. Whoever makes the most profit from flips wins. Vinny is fast, but he gets greedy. Beat him for a cash prize and a hype point.", "3 မိနစ်။ အမြတ် အများဆုံး ရသူ နိုင်မည်။ Vinny က မြန်ပေမယ့် လောဘကြီးသည်။ သူ့ကို နိုင်ရင် ငွေဆု နှင့် hype 1 မှတ် ရမည်။" },
	["mkt.record"] = { "Record: %d wins · lifetime profit %s", "မှတ်တမ်း: %d ကြိမ် နိုင် · စုစုပေါင်း အမြတ် %s" },
	["mkt.readyIn"] = { "READY IN %ds", "%ds အကြာတွင် ရမည်" },
	["mkt.startFlip"] = { "START FLIP-OFF", "FLIP-OFF စမည်" },
	["mkt.leave"] = { "←  Leave", "←  ထွက်မည်" },
	["mkt.howTitle"] = { "How the market works", "ဈေး ဘယ်လို အလုပ်လုပ်လဲ" },
	["mkt.how"] = { "• Cars trade like stocks. Prices move every %s s and jump on news.\n• Tap BUY for the asking price. Hold BUY to lowball: a cheaper deal, or the seller walks.\n• Sell to the market in Stalls (minus fees), or to a buyer's offer (no fee).\n• Requests pay a premium for a car in a condition or better.\n• Good flips raise your hype: better offers, lower fees.\n• Showroom units can be delivered to your garage.", "• ကားများကို စတော့လို ရောင်းဝယ်သည်။ ဈေးက %s စက္ကန့်တိုင်း ပြောင်းပြီး သတင်းထွက်ရင် ခုန်တက်သည်။\n• တောင်းဈေးဖြင့် ဝယ်ရန် ဝယ်မည် နှိပ်ပါ။ ဈေးဆစ်ရန် ဖိထားပါ: ပိုသက်သာ သို့မဟုတ် ရောင်းသူ ထွက်သွားမည်။\n• ဆိုင်ခန်းမှာ ဈေးကို ရောင်းပါ (ခ နုတ်)၊ သို့မဟုတ် ဝယ်သူ ကမ်းလှမ်းချက်ကို ရောင်းပါ (ခ မရှိ)။\n• Request များက သတ်မှတ် အခြေအနေ သို့မဟုတ် ပိုကောင်းတဲ့ ကားအတွက် ပိုပေးသည်။\n• အမြတ်ကောင်းရင် hype တက်သည်: ကမ်းလှမ်းချက် ပိုကောင်း၊ ခ ပိုနည်း။\n• Showroom ကားများကို ကိုယ့်ကားဂိုဒေါင်ထဲ ပို့ပေးနိုင်သည်။", true },
	["mkt.flipOff"] = { "Flip-off", "Flip-off" },
	["mkt.tapBuy"] = { "Tap to buy · hold to lowball", "ဝယ်ရန် နှိပ် · ဈေးဆစ်ရန် ဖိထား" },
	["mkt.clickBuy"] = { "Click to buy · hold to lowball", "ဝယ်ရန် click · ဈေးဆစ်ရန် ဖိထား" },
	["mkt.mkt"] = { "Mkt %s", "ဈေး %s" },
	["mkt.noOffers"] = { "No offers right now: buyers drop by every so often.", "ယခု ကမ်းလှမ်းချက် မရှိပါ: ဝယ်သူများ ခဏခဏ လာသည်။" },
	["mkt.buyToGetOffers"] = { "Buy a car in Listings: buyers will start making offers on your stash.", "Listings မှာ ကား ဝယ်ပါ: ဝယ်သူများက သင့် stash ကို ကမ်းလှမ်းလာမည်။" },
	["mkt.offer"] = { "Offer %s · %s", "ကမ်းလှမ်း %s · %s" },
	["mkt.openDaily"] = { "%d open · new daily", "%d ခု ဖွင့် · နေ့တိုင်း အသစ်" },
	["mkt.allDone"] = { "all done · new in %dh", "အားလုံး ပြီး · %d နာရီအကြာ အသစ်" },
	["mkt.sellFee"] = { "Sell to the market · %d%% fee", "ဈေးကို ရောင်း · ခ %d%%" },
	["mkt.vsReady"] = { "vs Slick Vinny · ready in %ds", "Slick Vinny နဲ့ · %ds အကြာ" },
	["mkt.vs3"] = { "vs Slick Vinny · 3 min", "Slick Vinny နဲ့ · 3 မိနစ်" },
	["mkt.stash"] = { "Stash  %d/%d", "Stash  %d/%d" },
	["mkt.fees"] = { "%d%% fees", "ခ %d%%" },
	["mkt.hype"] = { "HYPE %d/%d", "HYPE %d/%d" },
	["mkt.nothing"] = { "Nothing here yet. Buy low in Listings, sell high.", "ဘာမှ မရှိသေးပါ။ Listings မှာ ဈေးပေါပေါ ဝယ်၊ ဈေးကောင်းကောင်း ရောင်း။" },
	["mkt.buyerLine"] = { "★%.1f buyer · worth %s · %ds", "★%.1f ဝယ်သူ · တန်ဖိုး %s · %ds" },
	["mkt.score"] = { "You %s vs Vinny %s · %d:%02d", "သင် %s vs Vinny %s · %d:%02d" },
	["mkt.beatVinny"] = { "You beat Slick Vinny! +%s", "Slick Vinny ကို နိုင်ပြီ! +%s" },
	["mkt.vinnyWins"] = { "Vinny wins this one: %s vs your %s", "ဒီတစ်ခါ Vinny နိုင်သည်: %s vs သင့် %s" },

	-- car care, fuel, wash
	["care.oil"] = { "OIL SERVICE", "အင်ဂျင်ဝိုင် လဲမည်" },
	["care.engine"] = { "ENGINE REPAIR", "အင်ဂျင် ပြင်မည်" },
	["care.tyres"] = { "NEW TYRES", "တာယာ အသစ်" },
	["care.body"] = { "BODY REPAIR", "ကိုယ်ထည် ပြင်မည်" },
	["care.full"] = { "FULL SERVICE", "Service အပြည့်" },
	["care.dueIn"] = { "due in %s mi", "%s mi အကြာ ကျမည်" },
	["care.overdue"] = { "overdue %s mi", "%s mi ကျော်နေပြီ" },
	["care.marks"] = { "%d marks", "အရာ %d ခု" },
	["care.book"] = { "Service book: %s at %s", "Service စာအုပ်: %s ၊ %s" },
	["care.bookEmpty"] = { "Service book: empty", "Service စာအုပ်: မရှိသေး" },
	["care.onLift"] = { "ON THE LIFT...", "Lift ပေါ်မှာ..." },
	["care.done"] = { "%s done", "%s ပြီးပြီ" },
	["care.station"] = { "RIVIERA FUEL", "RIVIERA FUEL" },
	["care.stationEv"] = { "RIVIERA FUEL · CHARGER", "RIVIERA FUEL · အားသွင်းစက်" },
	["care.charge"] = { "CHARGE   %s", "အားသွင်းမည်   %s" },
	["care.fillUp"] = { "FILL UP   %s", "ဆီဖြည့်မည်   %s" },
	["care.charging"] = { "CHARGING...", "အားသွင်းနေသည်..." },
	["care.filling"] = { "FILLING...", "ဆီဖြည့်နေသည်..." },
	["care.filled"] = { "Filled up", "ဆီ ပြည့်ပြီ" },
	["care.filledFree"] = { "Filled up: free", "ဆီ ပြည့်ပြီ: အခမဲ့" },
	["care.add20"] = { "ADD $20", "$20 ဖြည့်မည်" },
	["care.add50"] = { "ADD $50", "$50 ဖြည့်မည်" },
	["care.wash"] = { "CAR WASH   %s", "ကားဆေးမည်   %s" },
	["care.washing"] = { "WASHING...", "ဆေးနေသည်..." },
	["care.roadside"] = { "ROADSIDE HELP", "လမ်းဘေး အကူအညီ" },
	["care.batteryEmpty"] = { "The battery is empty", "ဘက်ထရီ ကုန်ပြီ" },
	["care.outOfFuel"] = { "Out of fuel", "ဆီ ကုန်ပြီ" },
	["care.quickCharge"] = { "A QUICK CHARGE   %s", "အမြန် အားသွင်း   %s" },
	["care.fuelCan"] = { "FUEL CAN   %s", "ဆီပုံး   %s" },
	["care.tow"] = { "TOW TO THE NEAREST STATION", "အနီးဆုံး ဆီဆိုင်သို့ ဆွဲမည်" },
	["care.enough"] = { "Enough to reach a station", "ဆီဆိုင် ရောက်လောက်ရုံ" },
	["care.towed"] = { "Towed to the station", "ဆီဆိုင်သို့ ဆွဲပြီး" },
	["care.ownOnly"] = { "Your own cars only", "ကိုယ်ပိုင်ကားများသာ" },
	["care.lowFuelNear"] = { "Low fuel: nearest station %.1f mi", "ဆီနည်းနေ: အနီးဆုံး ဆီဆိုင် %.1f mi" },
	["care.lowFuel"] = { "Low fuel", "ဆီနည်းနေ" },

	-- houses (Legends Realty, lots, garage)
	["realty.title"] = { "LEGENDS REALTY", "LEGENDS REALTY" },
	["realty.sub"] = { "BUY A HOUSE, THEN CLAIM A FOR SALE LOT OF ITS TIER ON THE HILLSIDE ROADS", "အိမ်ဝယ်ပြီး တောင်ကုန်းလမ်းများပေါ်က အဆင့်တူ FOR SALE မြေကွက် ယူပါ" },
	["realty.closed"] = { "Legends Realty is closed: try again", "Legends Realty ပိတ်ထားသည်: ထပ်ကြိုးစားပါ" },
	["realty.dragTurn"] = { "DRAG TO TURN", "လှည့်ရန် ဆွဲပါ" },
	["realty.upTo"] = { "%d (up to %d)", "%d (%d အထိ)" },
	["realty.claimLot"] = { "CLAIM A LOT", "မြေကွက် ယူမည်" },
	["realty.claimLotHow"] = { "CLAIM A LOT marks the nearest free %s FOR SALE sign on your map", "မြေကွက် ယူမည် က အနီးဆုံး လွတ်နေတဲ့ %s FOR SALE ဆိုင်းဘုတ်ကို မြေပုံပေါ် မှတ်ပေးမည်" },
	["realty.youNeed"] = { "You need %s", "%s လိုသည်" },
	["realty.shortSpec"] = { "%d fl · %d bed · %d car", "%d ထပ် · အိပ်ခန်း %d · ကား %d" },
	["realty.sortPrice"] = { "SORT: PRICE", "စီရန်: ဈေးနှုန်း" },
	["realty.sortGarage"] = { "SORT: GARAGE", "စီရန်: ကားဂိုဒေါင်" },
	["realty.confirm"] = { "CONFIRM %s", "%s အတည်ပြုမည်" },
	["realty.tapAgain"] = { "Tap again to buy the %s", "%s ဝယ်ရန် ထပ်နှိပ်ပါ" },
	["realty.bought"] = { "You bought the %s: now claim a %s lot", "%s ကို ဝယ်ပြီး: အခု %s မြေကွက် ယူပါ" },
	["realty.sold"] = { "Sold the %s for %s", "%s ကို %s ဖြင့် ရောင်းပြီး" },
	["realty.noFreeLot"] = { "Couldn't find a free lot", "လွတ်နေတဲ့ မြေကွက် ရှာမတွေ့ပါ" },
	["realty.nearestLot"] = { "Waypoint set: the nearest free %s lot", "ဦးတည်ရာ မှတ်ပြီး: အနီးဆုံး လွတ်နေတဲ့ %s မြေကွက်" },
	["lot.title"] = { "LOT %s  ·  %s TIER", "မြေကွက် %s  ·  %s အဆင့်" },
	["lot.forSale"] = { "FOR SALE · LEGENDS PROPERTIES", "FOR SALE · LEGENDS PROPERTIES" },
	["lot.noHouse"] = { "You don't own a %s house yet. Buy one at Legends Realty, then come back and claim this lot.", "%s အိမ် မပိုင်သေးပါ။ Legends Realty မှာ ဝယ်ပြီး ပြန်လာကာ ဒီမြေကွက် ယူပါ။" },
	["lot.claimPick"] = { "CLAIM LOT %s  ·  %s TIER · PICK A HOUSE TO PUT HERE", "မြေကွက် %s ယူမည်  ·  %s အဆင့် · ဒီမှာ ချမည့် အိမ် ရွေးပါ" },
	["lot.claimThis"] = { "CLAIM THIS LOT", "ဒီမြေကွက် ယူမည်" },
	["lot.claimPrompt"] = { "Claim this lot", "ဒီမြေကွက် ယူမည်" },
	["lot.seeHouses"] = { "See %s houses", "%s အိမ်များ ကြည့်မည်" },
	["lot.spec"] = { "%d floors · %d bed · garage %d · %s", "%d ထပ် · အိပ်ခန်း %d · ကားဂိုဒေါင် %d · %s" },
	["lot.building"] = { "BUILDING...", "ဆောက်နေသည်..." },
	["lot.cantClaim"] = { "Couldn't claim this lot", "ဒီမြေကွက် ယူလို့ မရပါ" },
	["home.yours"] = { "YOUR HOUSE", "သင့်အိမ်" },
	["home.nothing"] = { "NOTHING STANDING IN THIS SERVER YET", "ဒီ server မှာ အိမ် မရှိသေးပါ" },
	["home.howBuy"] = { "Buy a house at Legends Realty (fast travel: Legends Realty), then claim a FOR SALE lot of its tier.", "Legends Realty မှာ အိမ်ဝယ်ပါ (ချက်ချင်းသွား: Legends Realty)၊ ပြီးရင် အဆင့်တူ FOR SALE မြေကွက် ယူပါ။" },
	["home.howPlace"] = { "Put your last house back on its lot, or walk up to any FOR SALE sign of its tier to claim a new lot.", "နောက်ဆုံး အိမ်ကို သူ့မြေကွက်ပေါ် ပြန်ချပါ၊ သို့မဟုတ် အဆင့်တူ FOR SALE ဆိုင်းဘုတ်ဆီ လျှောက်သွားပြီး မြေကွက်သစ် ယူပါ။" },
	["home.placeLast"] = { "PLACE MY LAST HOUSE", "နောက်ဆုံး အိမ် ပြန်ချမည်" },
	["home.cantPlace"] = { "Couldn't place it", "ချလို့ မရပါ" },
	["home.cantUse"] = { "You can't use this house", "ဒီအိမ်ကို သုံးခွင့် မရှိပါ" },
	["home.roommate"] = { " · ROOMMATE", " · အခန်းဖော်" },
	["home.whoIn"] = { "WHO CAN COME IN: %s", "ဝင်ခွင့်: %s" },
	["home.roommates"] = { "ROOMMATES (%d/%d)", "အခန်းဖော်များ (%d/%d)" },
	["home.change"] = { "CHANGE HOUSE", "အိမ် ပြောင်းမည်" },
	["home.garageUp"] = { "GARAGE %d → %d  ·  %s", "ကားဂိုဒေါင် %d → %d  ·  %s" },
	["home.garageAdded"] = { "Your garage has one more space", "ကားဂိုဒေါင်မှာ နေရာ တစ်ခု ထပ်တိုးပြီ" },
	["home.garageFailed"] = { "Couldn't add a space", "နေရာ ထပ်တိုးလို့ မရပါ" },
	["home.remove"] = { "REMOVE HOUSE", "အိမ် ဖယ်မည်" },
	["home.removeSure"] = { "SURE? IT GOES BACK TO FOR SALE", "သေချာလား? FOR SALE ပြန်ဖြစ်မည်" },
	["home.packed"] = { "Your house is packed away: claim any FOR SALE lot to put it up again", "အိမ်ကို သိမ်းထားပြီ: ပြန်ဆောက်ရန် FOR SALE မြေကွက် တစ်ခု ယူပါ" },
	["home.roommateNote"] = { "THEY CAN USE YOUR HOUSE AND OPEN ITS GATES", "သူတို့ သင့်အိမ်ကို သုံးနိုင်ပြီး ဂိတ်ဖွင့်နိုင်သည်" },
	["home.slept"] = { "You had a good sleep", "ကောင်းကောင်း အိပ်ပျော်ခဲ့ပြီ" },
	["home.atGate"] = { "%s IS AT YOUR GATE", "%s သင့်ဂိတ်မှာ ရောက်နေသည်" },
	["home.letIn"] = { "LET IN", "ဝင်ခွင့်ပေးမည်" },
	["home.welcome"] = { "Welcome home", "အိမ်ပြန်ရောက်ပြီ" },
	["home.bought"] = { "HOUSE BOUGHT", "အိမ် ဝယ်ပြီး" },
	["home.garageTitle"] = { "GARAGE  ·  %s", "ကားဂိုဒေါင်  ·  %s" },
	["home.ownerOnly"] = { "Only the owner can set up this garage", "ပိုင်ရှင်သာ ဒီကားဂိုဒေါင်ကို ပြင်ဆင်နိုင်သည်" },
	["home.pickBay"] = { "Pick a bay, then the car that stands in it", "နေရာ ရွေးပြီး အဲဒီမှာ ထားမည့်ကား ရွေးပါ" },
	["home.bayFailed"] = { "Could not change the bay", "နေရာ ပြောင်းလို့ မရပါ" },
	["home.emptyBay"] = { "Empty bay", "နေရာလွတ်" },

	-- chauffeur, hotel, gem showcase / VIP
	["chf.title"] = { "LEGENDS CHAUFFEUR", "LEGENDS CHAUFFEUR" },
	["chf.sub"] = { "Your private driver, anywhere in the city", "မြို့ထဲ ဘယ်နေရာမဆို ကိုယ်ပိုင် ကားဆရာ" },
	["chf.noAnswer"] = { "The service didn't answer, try again", "Service က မတုံ့ပြန်ပါ၊ ထပ်ကြိုးစားပါ" },
	["chf.onContract"] = { "On contract · rides are free", "စာချုပ်ရှိ · စီးခ အခမဲ့" },
	["chf.contract"] = { "Chauffeur contract", "ကားဆရာ စာချုပ်" },
	["chf.call"] = { "CALL ›", "ခေါ်မည် ›" },
	["chf.pitch"] = { "A driver in a black suit and this car, whenever you call. Pay once, ride free for good.", "ခေါ်တိုင်း အနက်ရောင် ဝတ်စုံနဲ့ ကားဆရာ နှင့် ဒီကား။ တစ်ခါ ပေး၊ အမြဲ အခမဲ့ စီး။" },
	["chf.sign"] = { "SIGN CONTRACT", "စာချုပ် ချုပ်မည်" },
	["chf.signed"] = { "Contract signed", "စာချုပ် ချုပ်ပြီး" },
	["chf.signFailed"] = { "Couldn't sign", "စာချုပ် မချုပ်နိုင်ပါ" },
	["chf.whereTo"] = { "WHERE TO?", "ဘယ်ကို သွားမလဲ?" },
	["chf.go"] = { "GO ›", "သွားမည် ›" },
	["chf.yours"] = { "YOUR CHAUFFEUR", "ကိုယ့် ကားဆရာ" },
	["chf.getOut"] = { "Get out of your car to call a chauffeur (Y)", "ကားဆရာ ခေါ်ရန် ကားပေါ်က ဆင်းပါ (Y)" },
	["chf.camera"] = { "CAMERA [V]", "ကင်မရာ [V]" },
	["chf.stopHere"] = { "STOP HERE", "ဒီမှာ ရပ်မည်" },
	["chf.skip"] = { "SKIP RIDE", "ခရီး ကျော်မည်" },
	["chf.to"] = { "To %s", "%s သို့" },
	["chf.yourStop"] = { "your stop", "ကိုယ့် မှတ်တိုင်" },
	["chf.welcomeTo"] = { "Welcome to %s", "%s မှ ကြိုဆိုပါတယ်" },
	["chf.enjoy"] = { "Enjoy your stop", "ပျော်ရွှင်ပါစေ" },
	["chf.pulling"] = { "Pulling over...", "ဘေးကပ် ရပ်နေသည်..." },
	["chf.calling"] = { "Calling your driver...", "ကားဆရာကို ခေါ်နေသည်..." },
	["chf.noDriver"] = { "No driver free", "အားတဲ့ ကားဆရာ မရှိပါ" },
	["chf.noRoad"] = { "No road there yet", "ထိုနေရာမှာ လမ်း မရှိသေးပါ" },
	["chf.onWay"] = { "Your %s is on its way", "သင့် %s လာနေပြီ" },
	["chf.here"] = { "Your driver is here.\nWalk to the car and press E (or tap Get in).", "ကားဆရာ ရောက်ပြီ။\nကားဆီ လျှောက်ပြီး E နှိပ်ပါ (သို့မဟုတ် တက်မည် နှိပ်ပါ)။" },
	["chf.arrived"] = { "Your chauffeur has arrived", "ကားဆရာ ရောက်ပါပြီ" },
	["hotel.getCar"] = { "Get my car", "ကိုယ့်ကား ယူမည်" },
	["hotel.valetParking"] = { "The valet is parking your car. Get it back at the valet stand", "Valet က ကားကို ရပ်ပေးနေသည်။ Valet နေရာမှာ ပြန်ယူပါ" },
	["hotel.valet"] = { "Valet  ·  %s", "Valet  ·  %s" },
	["hotel.elevator"] = { "Elevator  ·  %s", "ဓာတ်လှေကား  ·  %s" },
	["hotel.elevatorOwners"] = { "Elevator (suite owners only)", "ဓာတ်လှေကား (suite ပိုင်ရှင်များသာ)" },
	["hotel.yourSuite"] = { "Your suite", "ကိုယ့် suite" },
	["hotel.upgrade"] = { "Upgrade to the %s", "%s သို့ အဆင့်မြှင့်မည်" },
	["hotel.carComing"] = { "Your car is coming round", "ကား လာနေပြီ" },
	["gem.title"] = { "MYANMAR GEMS MUSEUM", "MYANMAR GEMS MUSEUM" },
	["gem.subVip"] = { "The collection  ·  your VIP card takes %d%% off", "စုစည်းမှု  ·  သင့် VIP ကတ်ဖြင့် %d%% လျှော့" },
	["gem.sub"] = { "The collection  ·  VIP members pay less (VIP desk, press R)", "စုစည်းမှု  ·  VIP အဖွဲ့ဝင်များ ပိုသက်သာ (VIP ကောင်တာ၊ R နှိပ်)" },
	["gem.bought"] = { "Bought for %s: you're wearing it", "%s ဖြင့် ဝယ်ပြီး: ဝတ်ထားပြီ" },
	["gem.inCollection"] = { "IN YOUR COLLECTION", "ကိုယ့် စုစည်းမှုထဲ ရှိပြီး" },
	["gem.takeOff"] = { "TAKE OFF", "ချွတ်မည်" },
	["vip.title"] = { "LEGENDS VIP", "LEGENDS VIP" },
	["vip.sub"] = { "Membership cards  ·  in-game cash only  ·  a higher card costs the difference", "အဖွဲ့ဝင်ကတ်များ  ·  ဂိမ်းထဲ ငွေဖြင့်သာ  ·  ကတ်အမြင့်က ကွာခြားငွေသာ ပေးရ" },
	["vip.titleOver"] = { "Title over your head:\n◆ %s", "ခေါင်းပေါ်က ဘွဲ့:\n◆ %s" },
	["vip.gemOff"] = { "%d%% off at the Gems Museum", "Gems Museum မှာ %d%% လျှော့" },
	["vip.yourCard"] = { "YOUR CARD", "ကိုယ့်ကတ်" },
	["vip.upgrade"] = { "UPGRADE  %s", "အဆင့်မြှင့်မည်  %s" },
	["vip.welcome"] = { "Welcome, %s", "ကြိုဆိုပါတယ်၊ %s" },

	-- bank robbery, police
	["bank.loot"] = { "LOOT  %s", "ခိုးရာပါ  %s" },
	["bank.loseCops"] = { "Lose the cops, then %s", "ရဲကို အရင် လွတ်အောင်ပြေး၊ ပြီးရင် %s" },
	["bank.dropoff"] = { "drop-off %d m", "ပို့ရမည့်နေရာ %d m" },
	["bank.grabbed"] = { "CASH GRABBED", "ငွေ ယူပြီး" },
	["bank.bagFull"] = { "Your bag is full: get to the drop-off", "အိတ် ပြည့်ပြီ: ပို့ရမည့်နေရာ သွားပါ" },
	["bank.loseFirst"] = { "Lose the cops first!", "ရဲကို အရင် လွတ်အောင်ပြေးပါ!" },
	["bank.complete"] = { "HEIST COMPLETE", "ဓားပြတိုက်မှု အောင်မြင်", true },
	["bank.busted"] = { "Busted: the loot is gone", "ဖမ်းမိသွားပြီ: ခိုးရာပါ ဆုံးပြီ" },
	["bank.lootGrabbed"] = { "LOOT GRABBED", "ခိုးရာပါ ယူပြီး" },
	["police.getOut"] = { "GET OUT OF THE ZONE", "ဧရိယာထဲက ထွက်ပါ" },
	["police.outOfZone"] = { "OUT OF THE ZONE", "ဧရိယာ အပြင်ရောက်ပြီ" },
	["police.keepGoing"] = { "Keep going!", "ဆက်မောင်း!" },
	["police.giveUpIn"] = { "POLICE GIVE UP IN %d:%02d", "%d:%02d အကြာ ရဲ လက်လျှော့မည်" },
	["police.zone"] = { "POLICE ZONE  ·  %d", "ရဲ ဧရိယာ  ·  %d" },
	["police.camera"] = { "SPEED CAMERA", "အမြန်နှုန်း ကင်မရာ" },
	["police.speeding"] = { "SPOTTED SPEEDING", "အရှိန်လွန် တွေ့ပြီ" },
	["police.assault"] = { "ASSAULT ON POLICE", "ရဲကို တိုက်ခိုက်" },
	["police.bank"] = { "BANK ROBBERY", "ဘဏ်ဓားပြ" },
	["police.coming"] = { "POLICE ARE COMING", "ရဲ လာနေပြီ" },

	-- challenges, races, duels, delivery (Activities, ChallengesClient)
	["chal.noOne"] = { "no one yet", "မရှိသေးပါ" },
	["chal.driftLost"] = { "DRIFT LOST", "DRIFT ဆုံးပြီ" },
	["chal.crashed"] = { "you crashed: %s points gone", "တိုက်မိသွားပြီ: %s မှတ် ဆုံးပြီ" },
	["chal.bigDrift"] = { "BIG DRIFT", "BIG DRIFT" },
	["chal.trapName"] = { "%s  ·  %d MPH", "%s  ·  %d MPH" },
	["chal.newBest"] = { "  ·  NEW BEST", "  ·  စံချိန်သစ်" },
	["chal.best"] = { "  ·  best %s", "  ·  အကောင်းဆုံး %s" },
	["chal.drift"] = { "DRIFT  %d", "DRIFT  %d" },
	["chal.bigAir"] = { "BIG AIR  %.1fs", "BIG AIR  %.1fs" },
	["act.race"] = { "RACE · %s", "ပြိုင်ပွဲ · %s" },
	["act.deliveryJobs"] = { "DELIVERY JOBS · stop here", "ပစ္စည်းပို့ အလုပ် · ဒီမှာ ရပ်ပါ" },
	["act.racingNow"] = { "RACING NOW · %d racers", "ပြိုင်နေသည် · ပြိုင်သူ %d ယောက်" },
	["act.waiting"] = { "%d waiting · starts in %s · stop here to join", "%d ယောက် စောင့်နေ · %s အကြာ စမည် · ဝင်ရန် ဒီမှာ ရပ်ပါ" },
	["act.best"] = { "Best %s", "အကောင်းဆုံး %s" },
	["act.gold"] = { "Gold %s", "ရွှေ %s" },
	["act.go"] = { "GO!", "သွား!" },
	["act.racers"] = { "%d RACERS · %s", "ပြိုင်သူ %d · %s" },
	["act.noNitrous"] = { " · No nitrous", " · Nitrous မရ" },
	["act.cantReachStart"] = { "Couldn't reach the start line, try again", "စမှတ် မရောက်နိုင်ပါ၊ ထပ်ကြိုးစားပါ" },
	["act.cantJoin"] = { "Couldn't join the race", "ပြိုင်ပွဲ ဝင်လို့ မရပါ" },
	["act.friendBonus"] = { "  · FRIEND BONUS", "  · သူငယ်ချင်း ဘောနပ်စ်" },
	["act.newBest"] = { "  NEW BEST", "  စံချိန်သစ်" },
	["act.notCounted"] = { "Race not counted", "ပြိုင်ပွဲ မရေတွက်ပါ" },
	["act.noJob"] = { "No job right now", "ယခု အလုပ် မရှိပါ" },
	["act.dropAt"] = { "Drop at %s", "%s မှာ ချပါ" },
	["act.tooLate"] = { "Too late: no pay this time", "နောက်ကျသွားပြီ: ဒီတစ်ခါ လစာ မရပါ" },
	["act.duelVs"] = { "DUEL · VS %s", "DUEL · %s နဲ့" },
	["act.duelRule"] = { "First to the yellow column wins %s", "အဝါရောင် တိုင်ကို အရင်ရောက်သူ %s နိုင်မည်" },
	["act.youWin"] = { "YOU WIN", "သင် နိုင်ပြီ" },
	["act.duelWon"] = { "DUEL WON · %s", "DUEL နိုင်ပြီ · %s" },
	["act.second"] = { "2ND", "ဒုတိယ" },
	["act.duel"] = { "DUEL · %s", "DUEL · %s" },
	["act.challenge"] = { "RACE CHALLENGE", "ပြိုင်ပွဲ စိန်ခေါ်မှု" },
	["act.wantsRace"] = { "%s WANTS TO RACE YOU", "%s က သင်နဲ့ ပြိုင်ချင်သည်" },
	["act.cantStart"] = { "The race couldn't start", "ပြိုင်ပွဲ မစနိုင်ပါ" },
	["act.challengeSent"] = { "Challenge sent to %s", "%s ကို စိန်ခေါ်ပြီး" },
	["act.challengeFailed"] = { "Couldn't send the challenge", "စိန်ခေါ်လို့ မရပါ" },
	["act.leftLobby"] = { "You left the race lobby", "ပြိုင်ပွဲ စောင့်ခန်းမှ ထွက်လိုက်ပြီ" },
	["act.leftRing"] = { "You drove out of the race ring", "ပြိုင်ပွဲ ကွင်းပြင် ထွက်သွားပြီ" },
	["act.waitingRacers"] = { "Waiting for racers · stay in the ring", "ပြိုင်သူများ စောင့်နေ · ကွင်းထဲ နေပါ" },
	["act.leftCar"] = { "You left the car", "ကားပေါ်က ဆင်းသွားပြီ" },
	["act.policeAfter"] = { "The police are after you", "ရဲ လိုက်နေပြီ" },
	["act.raceTimeout"] = { "Race timed out", "ပြိုင်ပွဲ အချိန်ကုန်ပြီ" },
	["act.deliveryFailed"] = { "Delivery failed: out of time", "ပို့ဆောင်မှု မအောင်မြင်: အချိန်ကုန်ပြီ" },
	["act.forming"] = { "RACE FORMING · %d s to join (orange R on the map)", "ပြိုင်ပွဲ စုနေ · ဝင်ရန် %d စက္ကန့် (မြေပုံပေါ်က လိမ္မော်ရောင် R)" },
	["act.finished"] = { "%s finished %s", "%s ပြီးဆုံး %s" },
	["act.saidNo"] = { "%s said no", "%s က ငြင်းလိုက်သည်" },
	["act.wonDuel"] = { "%s won the duel: finish for second place", "%s က duel နိုင်သွားပြီ: ဒုတိယ ရရန် ဆုံးအောင် မောင်းပါ" },
	["act.duelTimeout"] = { "The duel timed out", "Duel အချိန်ကုန်ပြီ" },

	-- photo mode, minimap labels
	["photo.time"] = { "TIME %02d:%02d", "အချိန် %02d:%02d" },
	["photo.fov"] = { "FOV %d", "FOV %d" },
	["photo.blurOn"] = { "BLUR ON", "BLUR ဖွင့်" },
	["photo.blurOff"] = { "BLUR OFF", "BLUR ပိတ်" },
	["photo.barBack"] = { "Tap or click anywhere to bring the bar back", "Bar ပြန်ပေါ်ရန် ဘယ်နေရာမဆို နှိပ်ပါ" },
	["mini.inyaLake"] = { "INYA LAKE", "အင်းလျားကန်" },
	["mini.city"] = { "THE CITY", "မြို့" },
	-- number plates (2026-11-19: PlateClient, CustomsClient)
	["plates.title"] = { "NUMBER PLATES", "ကားနံပါတ်ပြားများ", true },
	["plates.customsButton"] = { "NUMBER PLATES  ›", "ကားနံပါတ်ပြားများ  ›", true },
	["plates.atOffice"] = { "Plate Office: choose any free number", "နံပါတ်ရုံး: လွတ်နေသော နံပါတ်ကို ရွေးနိုင်သည်", true },
	["plates.thisCar"] = { "THIS CAR", "ဤကား", true },
	["plates.worth"] = { "Worth %s: %s", "တန်ဖိုး %s: %s", true },
	["plates.roll"] = { "ROLL NEW PLATE  %s", "နံပါတ်အသစ် ကျပန်းယူမည်  %s", true },
	["plates.lucky"] = { "Lucky! %s: %s", "ကံကောင်းသည်! %s: %s", true },
	["plates.rolled"] = { "New plate %s", "နံပါတ်အသစ် %s", true },
	["plates.office"] = { "PLATE OFFICE", "နံပါတ်ရုံး", true },
	["plates.officeName"] = { "Plate Office", "နံပါတ်ရုံး", true },
	["plates.officeOnly"] = { "Chosen and lucky numbers are sold only at the Plate Office (# on the map).", "ရွေးထားသော နံပါတ်နှင့် ကံကောင်းနံပါတ်များကို နံပါတ်ရုံး (မြေပုံပေါ်ရှိ #) တွင်သာ ရောင်းသည်။", true },
	["plates.waypoint"] = { "SHOW ON MAP", "မြေပုံပေါ်တွင် ပြမည်", true },
	["plates.hint"] = { "Type a plate like 9E-9999 (1-9 in front, the number from 1000)", "9E-9999 ကဲ့သို့ ရိုက်ပါ (ရှေ့တွင် 1-9၊ နံပါတ်က 1000 မှစ)", true },
	["plates.check"] = { "CHECK PRICE", "ဈေးနှုန်း ကြည့်မည်", true },
	["plates.quote"] = { "%s: %s", "%s: %s", true },
	["plates.taken"] = { "TAKEN", "ယူပြီးသား", true },
	["plates.claim"] = { "CLAIM  %s", "%s ဖြင့် ယူမည်", true },
	["plates.claimed"] = { "%s is yours: %s", "%s သင့်ပိုင်ပြီ: %s", true },
	["plates.ideas"] = { "LUCKY NUMBERS", "ကံကောင်းနံပါတ်များ", true },
	["plates.mine"] = { "MY PLATES", "ကျွန်ုပ်၏ နံပါတ်များ", true },
	["plates.on"] = { "On %s", "%s ပေါ်တွင်", true },
	["plates.spare"] = { "Spare", "အပို", true },
	["plates.putOn"] = { "PUT ON", "တပ်မည်", true },
	["plates.moved"] = { "%s moved", "%s ကို ပြောင်းပြီး", true },
	["plates.sell"] = { "SELL %s", "%s ဖြင့် ရောင်းမည်", true },
	["plates.sold"] = { "%s sold: +%s", "%s ရောင်းပြီး: +%s", true },
	-- Phase B (19 Nov): labels added by the jobs / discoverability / performance / mobile passes
	["menu.campaign"] = { "CAMPAIGN", "ပင်မ", true },
	["menu.storeTab"] = { "STORE", "ဆိုင်" },
	["menu.leaderboard"] = { "Leaderboard", "အဆင့်ဇယား" },
	["menu.comingSoon"] = { "Coming soon", "မကြာမီ လာမည်" },
	["side.market"] = { "MARKET", "ဈေး" },
	["side.despawn"] = { "DESPAWN", "ကား သိမ်းမည်" },
	["side.house"] = { "HOUSE", "အိမ်" },
	["side.dealer"] = { "DEALER", "ကားဆိုင်", true },
	["side.chauffeur"] = { "CHAUFFEUR", "ကားဆရာ" },
	["side.controls"] = { "CONTROLS", "ခလုတ်များ" },
	["set.performance"] = { "Performance", "စွမ်းဆောင်ရည်" },
	["set.lowEnd"] = { "LOW-END", "ဖုန်းအနိမ့်", true },
	["set.quality"] = { "Quality", "အရည်အသွေး" },
	["set.ultra"] = { "ULTRA", "အမြင့်ဆုံး" },
	["set.radio"] = { "Radio", "ရေဒီယို" },
	["set.sound"] = { "SOUND", "အသံ" },
	["set.show"] = { "SHOW", "ပြမည်" },
	["set.sunset"] = { "SUNSET", "နေဝင်ချိန်" },
	["set.english"] = { "ENGLISH", "ENGLISH" },
	["cam.immersive"] = { "IMMERSIVE", "အနီးကပ်", true },
	["cam.chase"] = { "CHASE", "နောက်က" },
	["cam.interior"] = { "INTERIOR", "ကားထဲ" },
	["cam.chaseLow"] = { "chase", "နောက်က" },
	["cam.side"] = { "side", "ဘေးက" },
	["cam.rearSeat"] = { "rear seat", "နောက်ခုံ" },
	["cam.aerial"] = { "aerial", "အပေါ်စီး" },
	["jobs.payDouble"] = { "%s a paycheck (Double Pay)", "လစာ %s (Double Pay)" },
	["jobs.payPost"] = { "%s a paycheck at the post", "ကိုယ့်နေရာမှာ လစာ %s" },
	["jobs.payTask"] = { "%s a paycheck + per task", "လစာ %s + တာဝန်တစ်ခုစီ" },
	["jobs.rankShort"] = { "R%d/%d  %s", "R%d/%d  %s" },
	["deal.importCrates"] = { "IMPORT ONLY · CRATES", "IMPORT သာ · CRATE များမှ", true },
	["deal.importOnly"] = { "IMPORT ONLY", "IMPORT သာ", true },
	["deal.fromCrates"] = { "FROM CRATES", "CRATE များမှ", true },
	["deal.importText"] = { "Import only: from crates", "Import သာ: crate များမှသာ ရနိုင်", true },
	["deal.value"] = { "Value %s", "တန်ဖိုး %s" },
	["deal.findShowroom"] = { "Find a Showroom one on the car market (K)", "ကားဈေး (K) မှာ Showroom ကား ရှာပါ" },
	["deal.ownFirst"] = { "own the %s first", "%s ကို အရင် ပိုင်ပါ" },
	["act.accept"] = { "ACCEPT", "လက်ခံမည်" },
	["home.ignore"] = { "IGNORE", "လျစ်လျူရှုမည်" },
	["home.residents"] = { "%s (residents only)", "%s (နေထိုင်သူများသာ)" },
	["rew.redeem"] = { "REDEEM", "ထုတ်ယူမည်" },
	["rew.buyOneShort"] = { "BUY 1", "1 ခု ဝယ်မည်" },
	["gem.wear"] = { "WEAR", "ဝတ်မည်" },
	["hotel.locked"] = { "Locked", "သော့ခတ်ထား" },
	["realty.mid"] = { "MID", "အလယ်" },
	["shop.builds"] = { "BUILDS", "BUILD များ" },
	["shop.fittedCaps"] = { "FITTED", "တပ်ပြီး" },
	["shop.front"] = { "%d%% front", "ရှေ့ %d%%" },
	["map.cantTravelRight"] = { "Can't travel right now", "ယခု မသွားနိုင်ပါ" },
	["common.noServerComma"] = { "The server didn't answer, try again", "Server က မတုံ့ပြန်ပါ၊ ထပ်ကြိုးစားပါ" },
	["daily.carStreak"] = { "Day %d streak: the %s is yours! It's in your CARS", "Streak နေ့ %d: %s ကို ရပြီ! ကားများ ထဲမှာ ရှိသည်" },
	["daily.streakPopup"] = { "DAY %d STREAK", "Streak နေ့ %d" },
	["chf.yoursStar"] = { "★ YOUR CHAUFFEUR", "★ ကိုယ့် ကားဆရာ" },
	["pent.heli"] = { "HELICOPTER TOUR", "ရဟတ်ယာဉ် ခရီး" },
	["pent.land"] = { "X to land", "ဆင်းရန် X" },
	["pent.look"] = { "Drag to look", "ကြည့်ရန် ဆွဲပါ" },
	["pent.zoom"] = { "scroll to zoom", "ချဲ့ချုံ့ရန် scroll" },
	["pent.stop"] = { "X to stop", "ရပ်ရန် X" },
	["pent.onShow"] = { "CAR ON SHOW", "ပြသထားသော ကား" },
	["pent.isOnShow"] = { "%s is on show", "%s ကို ပြသထားသည်" },
	["pent.sharp"] = { "Looking sharp", "ကြည့်ကောင်းနေပြီ" },
	-- Phase B test round (19 Nov, phone shots): what was still English on screen
	["common.select"] = { "Select", "ရွေးမည်" },
	["common.speed"] = { "Speed", "အမြန်နှုန်း" },
	["common.camera"] = { "Camera", "ကင်မရာ" },
	["common.shake"] = { "Shake", "လှုပ်ခြင်း" },
	["common.price"] = { "Price", "ဈေးနှုန်း" },
	["common.brand"] = { "Brand", "Brand" },
	["common.newest"] = { "Newest", "အသစ်ဆုံး" },
	["common.closeKey"] = { "%s to close", "ပိတ်ရန် %s" },
	["hud.cam"] = { "CAM", "ကင်မရာ" },
	["hud.car"] = { "CAR", "ကား" },
	["hud.engine"] = { "ENGINE", "အင်ဂျင်" },
	["hud.plates"] = { "PLATES", "နံပါတ်ပြား" },
	["hud.lift"] = { "LIFT", "ဓာတ်လှေကား" },
	["look.brightness"] = { "Brightness", "အလင်း" },
	["look.contrast"] = { "Contrast", "Contrast" },
	["look.glow"] = { "Glow", "အလင်းဝင်း" },
	["look.reflections"] = { "Reflections", "ရောင်ပြန်" },
	["look.saturation"] = { "Saturation", "အရောင်ရင့်မှု" },
	["look.shadows"] = { "Shadows", "အရိပ်များ" },
	["look.sky"] = { "Sky", "ကောင်းကင်" },
	["look.weather"] = { "Weather", "ရာသီဥတု" },
	["look.light"] = { "LIGHT", "ပါး" },
	["look.thick"] = { "THICK", "ထူ" },
	["look.clear"] = { "Clear", "ကြည်လင်" },
	["look.rain"] = { "Rain", "မိုးရွာ" },
	["look.dawn"] = { "Dawn", "အရုဏ်" },
	["look.day"] = { "Day", "နေ့" },
	["store.cash2xEffect"] = { "Double the cash from driving, cut-ups and jobs, for good", "မောင်းခြင်း၊ cut-up နှင့် အလုပ်များမှ ငွေ 2 ဆ၊ အမြဲတမ်း" },
	["store.vipEffect"] = { "A VIP tag, free VIP bays in every tower garage and +10% cash from cut-ups", "VIP tag၊ tower ကားဂိုဒေါင်တိုင်းမှာ အခမဲ့ VIP နေရာ နှင့် cut-up မှ ငွေ +10%" },
	["store.doublePayEffect"] = { "Double the pay from every job, for good", "အလုပ်တိုင်းမှ လစာ 2 ဆ၊ အမြဲတမ်း" },
	["store.starterEffect"] = { "$50,000 and a starter car of your choice, once per player", "$50,000 နှင့် ကိုယ်ရွေးတဲ့ ကားတစ်စီး၊ တစ်ယောက် တစ်ကြိမ်သာ" },
	["store.garageEffect"] = { "One more garage space at the house you live in", "နေထိုင်တဲ့ အိမ်မှာ ကားဂိုဒေါင် နေရာ တစ်ခု ထပ်တိုး" },
	["jobWhere.delivery"] = { "Dispatch rings (Myanmar Plaza, Kabar Aye)", "ပို့ဆောင်ရေးကွင်းများ (Myanmar Plaza, Kabar Aye)" },
	["jobWhere.taxi"] = { "Fares all over town", "မြို့တစ်ဝှမ်း ခရီးသည်များ" },
	["jobWhere.bus"] = { "7 stops: Kabar Aye, Kamayut, Mayangone", "မှတ်တိုင် 7 ခု: Kabar Aye, Kamayut, Mayangone" },
	["jobWhere.police"] = { "Patrol points + speeders", "ကင်းလှည့်နေရာများ + အရှိန်လွန်သူများ" },
	["jobWhere.tea"] = { "Shwe Lahpet Tea Shop, Inya Lake", "Shwe Lahpet လက်ဖက်ရည်ဆိုင်၊ Inya Lake" },
	["jobWhere.fuel"] = { "Kabar Aye Fuel (the flyover station)", "Kabar Aye ဆီဆိုင် (flyover ဘေးက)" },
	["jobWhere.dealer"] = { "Rider Auto, Kabar Aye", "Rider Auto, Kabar Aye" },
	["jobWhere.mall"] = { "Golden Thread Boutique, Myanmar Plaza", "Golden Thread Boutique, Myanmar Plaza" },
	-- goals (server Config.Goals texts; numbers come through the %d templates)
	["goal.bankDrifts"] = { "Bank %d drifts", "Drift %d ကြိမ် သိမ်းပါ" },
	["goal.bankDrift"] = { "Bank a drift", "Drift တစ်ခု သိမ်းပါ" },
	["goal.buyHouse"] = { "Buy a house", "အိမ် ဝယ်ပါ" },
	["goal.secondCar"] = { "Buy your second car", "ဒုတိယ ကား ဝယ်ပါ" },
	["goal.chips"] = { "Collect %d chips", "Chip %d ခု စုပါ" },
	["goal.cutUp"] = { "Cut up %d cars", "ကား %d စီး cut up လုပ်ပါ" },
	["goal.miles"] = { "Drive %d miles", "%d မိုင် မောင်းပါ" },
	["goal.milesComma"] = { "Drive 1,000 miles", "1,000 မိုင် မောင်းပါ" },
	["goal.ggfest"] = { "Drive to GG Gaming Fest at YCC", "YCC က GG Gaming Fest ကို မောင်းသွားပါ" },
	["goal.firstMile"] = { "Drive your first mile", "ပထမဆုံး တစ်မိုင် မောင်းပါ" },
	["goal.paychecks"] = { "Earn %d job paychecks", "အလုပ်လစာ %d ကြိမ် ရယူပါ" },
	["goal.deliveries"] = { "Finish %d delivery jobs", "ပစ္စည်းပို့ အလုပ် %d ခု ပြီးအောင်လုပ်ပါ" },
	["goal.races"] = { "Finish %d races", "ပြိုင်ပွဲ %d ပွဲ ပြီးအောင်ပြိုင်ပါ" },
	["goal.delivery"] = { "Finish a delivery job", "ပစ္စည်းပို့ အလုပ် တစ်ခု ပြီးအောင်လုပ်ပါ" },
	["goal.race"] = { "Finish a race", "ပြိုင်ပွဲ တစ်ပွဲ ပြီးအောင်ပြိုင်ပါ" },
	["goal.medals"] = { "Get %d speed trap medals", "Speed trap ဆုတံဆိပ် %d ခု ရယူပါ" },
	["goal.medal"] = { "Get a medal at a speed trap", "Speed trap မှာ ဆုတံဆိပ် ရယူပါ" },
	["goal.escapes"] = { "Get away from the police %d time", "ရဲလက်က %d ကြိမ် လွတ်ပါ" },
	["goal.escape"] = { "Get away from the police", "ရဲလက်က လွတ်ပါ" },
	["goal.gold"] = { "Get gold at a speed trap", "Speed trap မှာ ရွှေ ရယူပါ" },
	["goal.combo"] = { "Hit a x%d combo", "x%d combo ရအောင်လုပ်ပါ" },
	["goal.king"] = { "King of the City: own every car", "မြို့ဘုရင်: ကားအားလုံး ပိုင်ပါ" },
	["goal.jumps"] = { "Land %d jumps", "%d ကြိမ် ခုန်ပြီး ကျပါ" },
	["goal.jump"] = { "Land a jump", "တစ်ကြိမ် ခုန်ပြီး ကျပါ" },
	["goal.own"] = { "Own %d cars", "ကား %d စီး ပိုင်ပါ" },
	["goal.brands"] = { "Own cars from %d brands", "Brand %d ခုမှ ကားများ ပိုင်ပါ" },
	["goal.pvp"] = { "Race against another player", "အခြား ကစားသမားနဲ့ ပြိုင်ပါ" },
	["goal.pvpN"] = { "Race against players %d times", "ကစားသမားများနဲ့ %d ကြိမ် ပြိုင်ပါ" },
	["goal.level"] = { "Reach level %d", "Level %d ရောက်ပါ" },
	["goal.restyle"] = { "Restyle a car at Optima Werkz", "Optima Werkz မှာ ကား ပြင်ဆင်ပါ" },
	["goal.bank"] = { "Rob the bank and get away", "ဘဏ်ဓားပြတိုက်ပြီး လွတ်အောင်ပြေးပါ", true },
	["goal.photo"] = { "Stop on the photo spot at the stage", "စင်ပေါ်က ဓာတ်ပုံနေရာမှာ ရပ်ပါ" },
	["goal.winsN"] = { "Win %d races against players", "ကစားသမားများကို ပြိုင်ပွဲ %d ပွဲ နိုင်ပါ" },
	["goal.win"] = { "Win a race against a player", "ကစားသမားတစ်ယောက်ကို ပြိုင်ပွဲ နိုင်ပါ" },
	["goal.raceGold"] = { "Win gold in a race", "ပြိုင်ပွဲမှာ ရွှေ ရယူပါ" },
	["deal.drive"] = { "DRIVE", "မောင်းမည်" },
	["deal.allOf"] = { "All %s models", "%s မော်ဒယ် အားလုံး" },
	["deal.power"] = { "power", "ပါဝါ" },
	["deal.torque"] = { "torque", "torque" },
	["deal.driveTrain"] = { "drive", "ဒရိုက်" },
	["deal.seats"] = { "seats", "ထိုင်ခုံ" },
	["pop.suite"] = { "SUITE INCOME", "Suite ဝင်ငွေ" },
	["pop.delivered"] = { "DELIVERED", "ပို့ပြီး" },
	["pop.fare"] = { "FARE PAID", "ကားခ ရပြီ" },
	["pop.daily"] = { "DAILY REWARD", "နေ့စဉ် ဆု" },
	["pop.closeCut"] = { "CLOSE CUT", "CLOSE CUT", true },
	["pop.insaneCut"] = { "INSANE CUT", "INSANE CUT", true },
	["pop.available"] = { "AVAILABLE", "ရနိုင်သည်" },
}

local Strings = {}
Strings.T = T
Strings.Changed = Instance.new("BindableEvent")

local current = "en"
local setting = "auto"

-- the player's Roblox language ("my-mm") picks Burmese when the setting is Auto
local function fromLocale(): string
	local p = Players.LocalPlayer
	local id = string.lower(p and p.LocaleId or "")
	return if string.sub(id, 1, 2) == "my" then "my" else "en"
end

function Strings.setLang(code: string)
	setting = if code == "en" or code == "my" then code else "auto"
	local new = if setting == "auto" then fromLocale() else setting
	if new ~= current then
		current = new
		if Strings.clearCache then
			Strings.clearCache()
		end
		Strings.Changed:Fire(current)
	end
end

function Strings.lang(): string
	return current
end

function Strings.setting(): string
	return setting
end

function Strings.get(key: string, ...): string
	local e = T[key]
	if not e then
		return key
	end
	local s = if current == "my" then e[2] else e[1]
	if select("#", ...) > 0 then
		return string.format(s, ...)
	end
	return s
end

-- English text as the screens build it -> the current language (19 Nov, Phase B): screens keep their
-- English literals and client/LangUI runs every label's text through this. Exact lines first, then
-- the templates ("Waypoint: %s (on your map)": %s args are translated too), then " · " / new-line
-- pieces one by one. Burmese -> English the same way for text built with Strings.get.
local SPEC = "%%[-+ #0]*%d*%.?%d*[dsfxXgq%%]"
local exact: { [string]: string }, back: { [string]: string } = {}, {}
local templates: { { pat: string, my: string, en: string, lit: number } } = {}
local cache: { [string]: string } = {}
local cached = 0

local function escape(s: string): string
	return (string.gsub(s, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- an English template -> a Lua pattern ("" when it has nothing to match on)
local function toPattern(en: string): (string, number)
	local out, pos, letters = {}, 1, 0
	while true do
		local a, b = string.find(en, SPEC, pos)
		local lit = string.sub(en, pos, if a then a - 1 else -1)
		letters += #string.gsub(lit, "[^%a]", "")
		table.insert(out, escape(lit))
		if not a then
			break
		end
		local c = string.sub(en, b, b)
		table.insert(out, if c == "%" then "%%" elseif c == "s" then "(.-)" else "([%-%d%.,]+)")
		pos = b + 1
	end
	return "^" .. table.concat(out) .. "$", letters
end

for _, e in T do
	local en, my = e[1], e[2]
	if string.find(en, SPEC) then
		local pat, letters = toPattern(en)
		if letters > 0 then
			table.insert(templates, { pat = pat, my = my, en = en, lit = #en })
		end
	else
		local ens, mys = string.split(en, "|"), string.split(my, "|")
		for i, piece in ens do
			local m = mys[i] or piece
			exact[piece] = m
			exact[string.upper(piece)] = exact[string.upper(piece)] or m
			back[m] = back[m] or piece
		end
	end
end
table.sort(templates, function(a, b)
	return a.lit > b.lit
end)

local tr: (string, number) -> string
-- put the captures into the other language's template, in order (the check keeps the order the same)
local function fill(target: string, caps: { string }, depth: number): string
	local i = 0
	return (string.gsub(target, SPEC, function(spec)
		if spec == "%%" then
			return "%"
		end
		i += 1
		local v = caps[i] or ""
		return if string.sub(spec, -1) == "s" then tr(v, depth + 1) else v
	end))
end

tr = function(text: string, depth: number): string
	if depth > 4 or text == "" or not string.find(text, "[%a\128-\255]") then
		return text
	end
	local lead, core, trail = string.match(text, "^(%s*)(.-)(%s*)$")
	local hit = if current == "my" then (exact[core] or exact[string.upper(core)]) else back[core]
	if hit then
		return lead .. hit .. trail
	end
	-- a symbol in front or behind ("IMMERSIVE  ▶", "★ YOUR CHAUFFEUR")
	local pre, mid = string.match(core, "^([^%w%s]+%s+)(.+)$")
	if pre and not string.find(pre, "\225[\128\129]") then -- (never a Burmese word)
		local t = tr(mid, depth + 1)
		if t ~= mid then
			return lead .. pre .. t .. trail
		end
	end
	local mid2, post = string.match(core, "^(.-)(%s+[^%w%s]+)$")
	if mid2 and mid2 ~= "" and not string.find(post, "\225[\128\129]") then
		local t = tr(mid2, depth + 1)
		if t ~= mid2 then
			return lead .. t .. post .. trail
		end
	end
	if current == "my" then
		for _, t in templates do
			local caps = { string.match(core, t.pat) }
			if caps[1] ~= nil then
				return lead .. fill(t.my, caps, depth) .. trail
			end
		end
	end
	-- pieces: "A  ·  B", "A\nB" (plain splits: "·" is two bytes, a pattern class would cut Burmese letters)
	for _, sep in { "·", "\n" } do
		if string.find(core, sep, 1, true) then
			local parts = string.split(core, sep)
			local changed = false
			for i, piece in parts do
				local t = tr(piece, depth + 1)
				changed = changed or t ~= piece
				parts[i] = t
			end
			if changed then
				return lead .. table.concat(parts, sep) .. trail
			end
			break
		end
	end
	return text
end

-- the current language's version of a screen text (unchanged when it isn't in the table)
function Strings.tr(text: string): string
	if current == "en" and not string.find(text, "[\128-\255]") then
		return text
	end
	local c = cache[text]
	if c then
		return c
	end
	local r = tr(text, 0)
	if cached > 4000 then
		cache, cached = {}, 0
	end
	cache[text] = r
	cached += 1
	return r
end

function Strings.clearCache()
	cache, cached = {}, 0
end

-- a job's rank title (ranks are "a|b|c|d|e" in one entry)
function Strings.rank(jobId: string, n: number): string
	local all = string.split(Strings.get("jobRank." .. jobId), "|")
	return all[n] or ""
end

if Players.LocalPlayer then
	Strings.setLang("auto")
end

return Strings
