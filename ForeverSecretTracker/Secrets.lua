local _, ns = ...

-- Map IDs of the zones the steps point into.
local MAP = {
    ["Arathi Highlands"] = 1417,
    ["Ashenvale"] = 1440,
    ["Darkshore"] = 1439,
    ["Elwynn Forest"] = 1429,
    ["Hillsbrad Foothills"] = 1424,
    ["Loch Modan"] = 1432,
    ["Silverpine Forest"] = 1421,
    ["Stonetalon Mountains"] = 1442,
    ["Stormwind City"] = 1453,
    ["The Barrens"] = 1413,
    ["Tirisfal Glades"] = 1420,
    ["Undercity"] = 1458,
    ["Westfall"] = 1436,
    ["Wetlands"] = 1437,
    ["Zephras Isle"] = 2521,
}
ns.MAP = MAP

-- Where a find was first written up, shown in the guide with a link to copy.
-- `credit` is one of these or a list of them; `what` names the part found.
local SECRET_FINDING = { name = "WoW Secret Finding & Collections", url = "https://discord.gg/wowsecrets" }
local KISSTA96 = { name = "Kissta96 on Reddit", url = "https://www.reddit.com/user/Kissta96/" }

-- step(text, zone, x, y, check, extra): x and y may be nil for a step
-- without a known spot. `check` is what tells the addon the step is done,
-- see README.md for the keys it understands.
local function step(text, zone, x, y, check, extra)
    local s = extra or {}
    s.text, s.zone, s.x, s.y, s.check = text, zone, x, y, check
    s.mapID = zone and MAP[zone]
    return s
end

ns.SECRETS = {
    -- Pets ---------------------------------------------------------------
    {
        id = "musical-gustjumper", icon = "Spell_Shaman_Hex", kind = "pet", name = "Musical Gustjumper",
        zone = "Zephras Isle", reward = "Musical Gustjumper (pet)",
        done = { pet = "Musical Gustjumper" },
        steps = {
            step("Find the frogs on the rock.", "Zephras Isle", 51.5, 72.1),
            step("Stand next to them and type /sing.", "Zephras Isle", 51.5, 72.1, nil, { macro = "/sing" }),
            step("A frog hops onto the log beside you: pick it up and use it to learn the pet.", "Zephras Isle", 51.5, 72.1,
                { pet = "Musical Gustjumper" }),
        },
    },
    {
        id = "excitable-slime", icon = "Spell_Nature_Acid_01", kind = "pet", name = "Excitable Slime", faction = "Horde",
        zone = "Undercity", reward = "Excitable Slime (pet)",
        done = { pet = "Excitable Slime" },
        steps = {
            step("Buy a Nutritious Slime Sludge from Boyle.", "Undercity", 56.2, 64.6,
                { itemName = "Nutritious Slime Sludge" }),
            step("Jump into the canal and find the Excitable Slime patrolling it.", "Undercity", 57.2, 64.3,
                nil, { macro = "/target Excitable Slime" }),
            step("/dance at it until it dances back and offers WRIGGLE. It can take several tries.", "Undercity", 57.2, 64.3,
                { questAccepted = "WRIGGLE.", onQuest = 97583 }, { macro = "/dance" }),
            step("Hand it the sludge to finish WRIGGLE and get the pet.", "Undercity", 57.2, 64.3,
                { questName = "WRIGGLE.", quest = 97583, pet = "Excitable Slime" }),
        },
    },
    {
        id = "baby-crocolisk", icon = "Ability_Hunter_Pet_Crocolisk", kind = "pet", name = "Baby Crocolisk", faction = "Alliance",
        zone = "Stormwind City", reward = "Baby Crocolisk (pet)",
        note = "Sewer Beast is a level 50 elite: bring a group.",
        done = { pet = "Baby Crocolisk" },
        steps = {
            step("Find Sewer Beast patrolling the canals and kill it.", "Stormwind City", 71.2, 48.8,
                { kill = "Sewer Beast" }, { spots = { { 71.2, 48.8 }, { 71.1, 68.0 } } }),
            step("Loot the Baby Crocolisk and use it to learn the pet.", "Stormwind City", nil, nil,
                { pet = "Baby Crocolisk" }),
        },
    },

    -- Toys -----------------------------------------------------------------
    {
        id = "alcaz-operative", icon = "Ability_Rogue_Disguise", kind = "toy", name = "Alcaz Operative Insignia",
        credit = SECRET_FINDING,
        level = 48, zone = "Alcaz Prison, Westfall, Booty Bay / Stormwind",
        reward = "Alcaz Operative Insignia (toy): a Defias disguise",
        note = "Do not sell the Document Box (it vendors for 25g). The Fractured Insignia trades: the other five can be bought or traded from friends.",
        done = { itemName = { "Alcaz Operative Insignia", "Alcaz Operative Disguise" } },
        steps = {
            step("Alcaz Prison: skip the first boss, The Questioner. At the end, the prisoner Mason Connery asks you to kill The Questioner for the key to his freedom."),
            step("Kill The Questioner, bring the key to Mason, and take More Valuable than Gold. His note says \"WF, 43.4, 67.8\".", nil, nil, nil,
                { questAccepted = "More Valuable than Gold" }),
            step("Moonbrook inn, second floor: click the floorboards by the box to turn in the quest and get the Document Box.", "Westfall", 43.4, 67.8,
                { questName = "More Valuable than Gold", itemName = "Document Box" }),
            step("Bring the Document Box to Rix Xizzix in Booty Bay, near the auction house, for State Secrets.", nil, nil, nil,
                { questName = "State Secrets", itemName = "Fractured Insignia" }, { faction = "Horde" }),
            step("Bring the Document Box to Renzik \"The Shiv\" in the SI:7 building in Old Town for State Secrets.", "Stormwind City", nil, nil,
                { questName = "State Secrets", itemName = "Fractured Insignia" }, { faction = "Alliance" }),
            step("Get five more Fractured Insignias: buy them or trade with friends."),
            step("Combine the six insignias into the toy.", nil, nil, nil,
                { itemName = { "Alcaz Operative Insignia", "Alcaz Operative Disguise" } }),
        },
    },

    -- Hidden quests --------------------------------------------------------
    {
        id = "cozy-sleeping-bag", icon = "INV_Misc_Bag_10", kind = "quest", name = "Cozy Sleeping Bag", level = 14,
        zone = "Westfall, The Barrens, Stonetalon, Loch Modan, Hillsbrad",
        reward = "Cozy Sleeping Bag, a 12-slot bag, Student Fodder",
        note = "No quest givers: every step is an object you click.",
        done = { itemName = "Cozy Sleeping Bag", questName = "This Must Be The Place", quest = 79976 },
        steps = {
            step("Click the Burned-Out Remains in the cart wreckage at Alexston Farmstead.", "Westfall", 37.0, 50.0,
                { onQuest = 79008 }, { faction = "Alliance" }),
            step("Click the Burned-Out Remains south of Camp Taurajo.", "The Barrens", 46.0, 74.0,
                { onQuest = 79007 }, { faction = "Horde" }),
            step("Click the Nailed Plank next to the remains: turn in the note, take Stepping Stones.", "The Barrens", 46.0, 74.0,
                { questAccepted = "Stepping Stones", onQuest = 79192 }, { faction = "Alliance" }),
            step("Click the Nailed Plank at Alexston Farmstead: turn in the note, take Stepping Stones.", "Westfall", 37.0, 50.0,
                { questAccepted = "Stepping Stones", onQuest = 79192 }, { faction = "Horde" }),
            step("Take the mountain path northeast of Sun Rock Retreat to the abandoned camp; click the Pocket Litter to take Scramble.", "Stonetalon Mountains", 40.6, 52.4,
                { questAccepted = "Scramble", onQuest = 79980 }),
            step("Climb north and jump to the ledge with the Mound of Dirt; click it to take Wet Job.", "Stonetalon Mountains", 39.6, 49.8,
                { questAccepted = "Wet Job", onQuest = 79974 }),
            step("At the dam, jump onto the carved heads facing the Wetlands and click the Carved Figurine to take Eagle's Fist.", "Loch Modan", 49.4, 12.9,
                { questAccepted = "Eagle's Fist", onQuest = 79975 }),
            step("Thoradin's Wall: use the broken cart to start the climb, then click the Messenger Bag on the wall.", "Hillsbrad Foothills", 87.4, 49.7,
                { questAccepted = "This Must Be The Place", onQuest = 79976 }),
            step("Click the Hastily Rolled-Up Satchel just below the Messenger Bag.", "Hillsbrad Foothills", 87.4, 49.7,
                { itemName = "Cozy Sleeping Bag", questName = "This Must Be The Place", quest = 79976 }),
        },
    },
    {
        id = "silver-of-the-waves", icon = "INV_Misc_Comb_01", kind = "quest", name = "Silver of the Waves",
        zone = "Loch Modan", reward = "Repurposed Hair Band (wrist)",
        done = { itemName = "Repurposed Hair Band" },
        steps = {
            step("Dive to the Discarded Fishing Toolbox on the lakebed. The Young Threshadons there are higher level than the shore.", "Loch Modan", 45.6, 43.4),
            step("Loot the Monogrammed Silver Hair Clip (marked K.D.).", "Loch Modan", 45.6, 43.4,
                { itemName = "Monogrammed Silver Hair Clip" }),
            step("Take it to Khara Deepwater, the fishing supplies vendor.", "Loch Modan", 39.5, 39.2,
                { itemName = "Repurposed Hair Band" }),
        },
    },
    {
        id = "malignant-root", icon = "INV_Jewelry_Ring_15", kind = "quest", name = "Malignant Root",
        zone = "Tirisfal Glades, Wetlands", reward = "Malignant Root (ring)",
        note = "Who takes the Rotheap Innards is not known yet.",
        done = { itemName = "Malignant Root" },
        steps = {
            step("Kill the Whispering Horror in a cellar and loot the Whispering Horror Residue.", "Tirisfal Glades", 9.5, 62.0,
                { itemName = "Whispering Horror Residue" }),
            step("Kill the Nightveiled Rotheap and loot the Rotheap Innards.", "Wetlands", nil, nil,
                { itemName = "Rotheap Innards" }),
            step("Trade the Innards for the Malignant Root.", nil, nil, nil,
                { itemName = "Malignant Root" }),
        },
    },
    {
        id = "captain-sander", icon = "INV_Misc_Map_01", kind = "quest", name = "Captain Sander's Hidden Treasure", level = 10,
        zone = "Westfall", reward = "Captain Sander's Locker, Shirt and Sash",
        done = { itemName = "Captain Sander's Locker", quest = 140 },
        steps = {
            step("Kill coastal murlocs until Captain Sander's Treasure Map drops, then right-click it.", "Westfall", nil, nil,
                { itemName = "Captain Sander's Treasure Map", onQuest = 136 }),
            step("Captain's Footlocker on Longshore Beach, west of Gold Coast Quarry.", "Westfall", 25.9, 47.8,
                { onQuest = 138 }),
            step("Broken Barrel at the burned farm, by the fence and chimney.", "Westfall", 40.5, 47.8,
                { onQuest = 139 }),
            step("Old Jug by the wood pile on the cliff northwest of Jangolode Mine.", "Westfall", 40.6, 17.0,
                { onQuest = 140 }),
            step("Swim west to the island and open the Locked Chest by the hut.", "Westfall", 26.0, 16.9,
                { itemName = "Captain Sander's Locker", quest = 140 }),
        },
    },
    {
        id = "applejack-still", icon = "INV_Misc_Food_19", kind = "quest", name = "Applejack Still", faction = "Alliance",
        zone = "Elwynn Forest", reward = "Thunder Applejack",
        done = { quest = 91738 },
        steps = {
            step("Buy four Shiny Red Apples, e.g. from Tharynn Bouden in Goldshire.", "Elwynn Forest", 41.8, 67.2,
                { itemName = "Shiny Red Apple" }),
            step("Use the unmarked Applejack Still on the hillside by Thunder Falls.", "Elwynn Forest", 24.6, 58.0,
                { quest = 91736, item = 247824 }),
            step("Bring the Thunder Applejack to Sergeant De Vries in Westbrook Garrison (An Apple Treat, level 7+).", "Elwynn Forest", 24.1, 73.2,
                { quest = 91738 }),
        },
    },

    -- Bosses and places ----------------------------------------------------
    {
        id = "lyn-the-ignored", icon = "INV_Misc_Book_06", kind = "boss", name = "Lyn the Ignored",
        zone = "Shadowfang Keep, Silverpine, City of Dalaran", reward = "A hidden boss",
        note = "The tome is not used up and has a 3 minute cooldown.",
        done = { kill = "Lyn the Ignored" },
        steps = {
            step("Shadowfang Keep: kill Archmage Arugal and click the book on his table for the Black Tome.", nil, nil, nil,
                { itemName = "Black Tome" }),
            step("Ambermill: use the Black Tome on the Leyline Focus, the blue crystal by Archmage Ataeric in the town hall at the back of the town.", "Silverpine Forest", 63.4, 64.3,
                { itemName = "Tome of Dalaran", item = 275989 }),
            step("City of Dalaran: kill Atrexis the Grave Knight, go through the sewer, and straight on into the tunnel where it turns right.", nil),
            step("Use the Tome of Dalaran on the purple rune on the floor; Lyn appears after a short scene.", nil, nil, nil,
                { kill = "Lyn the Ignored" }),
        },
    },
    {
        id = "ruins-of-lordaeron", icon = "Spell_Shadow_RaiseDead", kind = "boss", name = "Ruins of Lordaeron bosses", level = 15,
        zone = "Ruins of Lordaeron",
        reward = "Scepter of the Abandoned, Rotmender's Leggings, Grip of Fear; Vilewalkers, Bloodied Chestwraps, Vileblood Scimitar",
        note = "Both are optional bosses that come after waves of adds: clear around them and rest to full first.",
        done = { kill = { "The Abandoned", "Viktor the Vile" }, all = true },
        steps = {
            step("The Abandoned: walk up to the knight statue in the small hall on the left side of the map. It flares violet, and the boss leaps out after three or four waves.", nil, nil, nil,
                { kill = "The Abandoned" }),
            step("Viktor the Vile: in the ruined house with a chimney in the bottom left of the map, southwest of Lordamere Overlook, click the Warm Kindling under the chimney. He comes after five waves.", nil, nil, nil,
                { kill = "Viktor the Vile" }),
        },
    },
    {
        id = "drunken-dwarf", icon = "INV_Drink_05", kind = "boss", name = "The Drunken Dwarf Tavern",
        zone = "Dun Algaz", reward = "Food and drink",
        note = "The cellar is locked, and nobody has opened it yet.",
        steps = {
            step("Climb the mountain above the Dun Algaz tunnels.", "Wetlands"),
            step("Find the tavern at the top.", "Wetlands"),
        },
    },

    -- Rares -----------------------------------------------------------------
    {
        id = "blessing-of-kalimdor", icon = "Ability_Hunter_Pet_Cat", kind = "rare", name = "Blessing of Kalimdor", level = 16,
        zone = "The Barrens", reward = "Two set pieces: +5% speed in the Barrens and Stonetalon",
        note = "Any two of the three rares will do; the third is optional. Click a rare to put a waypoint on where it spawns.",
        picks = { rares = 2 },
        steps = {
            step("Kill Humar the Pridelord, a lion north of the Crossroads.", "The Barrens", 62.1, 33.3,
                { kill = "Humar the Pridelord" }, { pick = "rares" }),
            step("Kill Swiftmane, a zhevra that walks a loop north of the Crossroads.", "The Barrens", 60.6, 32.6,
                { kill = "Swiftmane" }, { pick = "rares" }),
            step("Kill Takk the Leaper, a raptor in the far north of the Barrens.", "The Barrens", 59.6, 8.3,
                { kill = "Takk the Leaper" }, { pick = "rares" }),
            step("Wear two pieces of the set."),
        },
    },

    -- Items with a twist --------------------------------------------------
    {
        id = "coldflame-saber", icon = "INV_Sword_27", kind = "twist", name = "Coldflame Saber", class = { MAGE = true },
        zone = "Shadowfang Keep", reward = "Coldflame Saber (a sword that burns frozen targets)",
        done = { itemName = "Coldflame Saber" },
        steps = {
            step("Get the Blade of Silverlaine in Shadowfang Keep.", nil, nil, nil, { itemName = "Blade of Silverlaine" }),
            step("Find the Scroll of the Saber.", nil, nil, nil, { itemName = "Scroll of the Saber" }),
            step("Use the scroll on the blade.", nil, nil, nil, { itemName = "Coldflame Saber" }),
        },
    },
    {
        id = "wits-edge", icon = "INV_Sword_39", kind = "twist", name = "Wit's Edge", class = { MAGE = true },
        credit = {
            { name = KISSTA96.name, url = KISSTA96.url, what = "Weapon" },
            { name = SECRET_FINDING.name, url = SECRET_FINDING.url, what = "Scroll" },
        },
        zone = "Scholomance", reward = "Wit's Edge (a new sword)",
        done = { itemName = "Wit's Edge" },
        steps = {
            step("Get the Witchblade from Darkmaster Gandling in Scholomance.", nil, nil, nil, { itemName = "Witchblade" },
                { macro = "/target Darkmaster Gandling" }),
            step("Use a mage's comprehension on the level 175 skill scrolls to find the Scroll of Wit.", nil, nil, nil,
                { itemName = "Scroll of Wit" }),
            step("Use the scroll on the Witchblade.", nil, nil, nil, { itemName = "Wit's Edge" }),
        },
    },
    {
        id = "graverobbers-shovel", icon = "INV_Misc_Shovel_01", kind = "twist", name = "Graverobber's Shovel",
        zone = "The Stockade, Duskwood", reward = "A mace that digs up graves",
        steps = {
            step("Graverobber's Shovel drops from Dextren Ward in the Stockade.", nil, nil, nil, { itemName = "Graverobber's Shovel" },
                { macro = "/target Dextren Ward" }),
            step("Dig a grave with it, e.g. at Raven Hill in Duskwood."),
        },
    },

    -- Unsolved ------------------------------------------------------------
    {
        id = "stone-key", icon = "INV_Misc_Key_10", kind = "mystery", name = "The Stone Key",
        zone = "Many zones", reward = "Unknown: the keyhole has not been found",
        steps = {
            step("A Burnt Page on Thoradin's Wall, in the same room as the Cozy Sleeping Bag.", "Hillsbrad Foothills", 87.4, 49.7,
                { itemName = "Burnt Page" }),
            step("A fragment in the Undercity canal.", "Undercity"),
            step("The Stone Key itself, in Riverglades (earlier in the Blasted Lands).", nil, nil, nil,
                { itemName = "Stone Key" }),
            step("Notes in the Blasted Lands."),
            step("A hidden stash in Un'Goro Crater that needs a lit Night Watchman's Torch (from a fallen watchman in Duskwood).", nil, nil, nil,
                { itemName = "Night Watchman's Torch", item = 280612 }),
            step("A Brittle Key in Stonetalon Mountains.", "Stonetalon Mountains", nil, nil,
                { itemName = "Brittle Key" }),
        },
    },
    {
        id = "bloody-map-destination", icon = "INV_Misc_Map_01", kind = "mystery", name = "Where the Bloody Map leads",
        zone = "Unknown", reward = "Unknown",
        faction = "Horde",
        note = "The map comes from an ordinary Horde chain, Dragonmaw Rumors from Zaruk in Hammerfall, then Open the Maw in the Wetlands. Player theories: Dun Modr, Uldaman, Bael Modan.",
        steps = {
            step("Get the Bloody Map: Dragonmaw Rumors from Zaruk in Hammerfall, then Open the Maw.", "Arathi Highlands", 74.5, 35.6,
                { item = 271745 }),
            step("Find the place it shows."),
        },
    },
    {
        id = "partners-in-crime", icon = "INV_Jewelry_Ring_04", kind = "mystery", name = "Partners in Crime",
        zone = "The Deadmines", reward = "Two rings with a set bonus",
        note = "Band of the Better Half, the level 60 partner ring, has no known source.",
        steps = {
            step("First Mate Band drops from Mr. Smite in the Deadmines.", nil, nil, nil, { itemName = "First Mate Band" }),
            step("Find Band of the Better Half.", nil, nil, nil, { itemName = "Band of the Better Half" }),
        },
    },
    {
        id = "dawn-waker", icon = "INV_Sword_62", kind = "mystery", name = "Dawn Waker",
        credit = SECRET_FINDING,
        zone = "Zephras Isle, Ashenvale, Darkshore", reward = "Unknown yet: the chain is not solved to the end",
        note = "Possibly the answer to the five Darnassian words on the board in the official podcast, episode 6. Part 4 and on is only in the secret-finding Discord so far.",
        steps = {
            step("Thendal Village: take Coming of Age from Ailee Farheart.", "Zephras Isle", 42.83, 23.45,
                { questAccepted = "Coming of Age", onQuest = 92460 }),
            step("Turn it in to Rorian the Dayseeker nearby for the Ancient Heirloom ring. The ring also lies on the top floor.", "Zephras Isle", 41.7, 23.4,
                { questName = "Coming of Age", quest = 92460, itemName = { "Ancient Heirloom", "Ancient Heirloom Ring" } }),
            step("Use a Night Watchman's Torch (from a fallen watchman in Duskwood) at the Ruins of Ban'aethal to uncover the Ancient Hilt.", "Zephras Isle", 58.13, 24.06,
                { itemName = "Ancient Hilt" }),
            step("Take the Ancient Hilt to Ealaane.", "Zephras Isle", 65.94, 74.37),
            step("Find the Ancient Skyborne Blade somewhere on the island.", "Zephras Isle", 48.94, 72.68,
                { itemName = "Ancient Skyborne Blade" },
                { spots = { { 48.94, 72.68 }, { 50.4, 44.3 }, { 66.25, 43.15 }, { 59.9, 82.2 } } }),
            step("Bring the blade to Ealaane for Eluvi'ana.", "Zephras Isle", 65.94, 74.37,
                { itemName = "Eluvi'ana" }),
            step("Kill Baron Aquanis in Blackfathom Deeps for the Strange Water Globe.", nil, nil, nil,
                { itemName = "Strange Water Globe" }, { faction = "Horde" }),
            step("Turn it in to Je'neu at Zoram'gar Outpost, then talk to him again to get the globe back.", "Ashenvale", 11.6, 34.2,
                { itemName = "Befouled Water Globe" }, { faction = "Horde" }),
            step("Collect 20 Mathystra Amulet Fragments from the naga in the Ruins of Mathystra and combine them.", "Darkshore", nil, nil,
                nil, { faction = "Alliance" }),
            step("At the water structure, use the amulet and kill Baron Marinous.", "Darkshore", 58.9, 22.6,
                { kill = "Baron Marinous" }, { faction = "Alliance" }),
            step("Turn his globe in to Onu in the Grove of the Ancients, then talk to him again to get it back.", "Darkshore", 43.6, 76.4,
                { itemName = "Befouled Water Globe" }, { faction = "Alliance" }),
            step("Wear the Ancient Heirloom ring and go to the Zoram Strand. Talk to the Highborne Spirit that appears: with the globe, he sends you to the Tower of Althalaxx.", "Ashenvale", 15.68, 19.33),
            step("Kill Narassin at the top of the tower for an Azsharan Key.", "Darkshore", 56.4, 26.5,
                { itemName = "Azsharan Key", kill = "Narassin" }),
            step("Open the lockbox just behind him for Narassin's Tome.", "Darkshore", 56.4, 26.5,
                { itemName = "Narassin's Tome" }),
            step("Go back to the Highborne Spirit.", "Ashenvale", 15.68, 19.33),
            step("Part 4 and on: not in the guide yet."),
        },
    },
    {
        id = "lands-end-island", icon = "INV_Misc_Spyglass_02", kind = "mystery", name = "The island south of Land's End",
        zone = "Tanaris", reward = "Unknown",
        note = "An island you cannot swim to.",
        steps = {
            step("Find a way onto the island."),
        },
    },
}
