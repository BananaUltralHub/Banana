--[[
    REDNAZ HUB - BLOX FRUITS SCRIPT
    Version: Fixed - Removed Hop Server
    All functions preserved
--]]

-- ========== RESET CHECK ==========
local currentPlaceId = game.PlaceId
if getgenv().RedNaZ and getgenv().LastPlaceId == currentPlaceId then
    if game.CoreGui:FindFirstChild("RedNaZ Hub GUI") then
        for i, v in ipairs(game.CoreGui:GetChildren()) do
            if string.find(v.Name, "RedNaZ Hub") then
                v:Destroy()
            end
        end
    end
else
    getgenv().RedNaZ = nil
end
getgenv().LastPlaceId = currentPlaceId
getgenv().RedNaZ = true

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Stats = game:GetService("Stats")

-- ========== REMOTES (SAFE) ==========
local Remotes = pcall(function() return ReplicatedStorage:WaitForChild("Remotes", 10) end) and ReplicatedStorage.Remotes or nil
local CommF_Remote = (Remotes and pcall(function() return Remotes:WaitForChild("CommF_", 5) end) and Remotes.CommF_) or nil

-- ========== PLAYER ==========
local Player = Players.LocalPlayer
if not Player then error("Không tìm thấy LocalPlayer") end

local PlayerGui = pcall(function() return Player:WaitForChild("PlayerGui", 5) end) and Player.PlayerGui or nil
local MainGui = (PlayerGui and pcall(function() return PlayerGui:WaitForChild("Main", 5) end) and PlayerGui.Main) or nil

-- ========== CHARACTER ==========
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character and pcall(function() return Character:WaitForChild("Humanoid", 5) end) and Character.Humanoid or nil
local HumanoidRootPart = Character and pcall(function() return Character:WaitForChild("HumanoidRootPart", 5) end) and Character.HumanoidRootPart or nil

-- ========== FISHING MODULES (PCALL) ==========
local RFCraft = nil
local FishReplicated = nil
local FishingRequest = nil
local FishingConfig = {}
local JobsRemoteFunction = nil
local JobToolAbilities = nil
local GetWaterHeightAtLocation = function() return 0 end

pcall(function()
    local Modules = ReplicatedStorage:WaitForChild("Modules", 5)
    local Net = Modules:WaitForChild("Net", 5)
    RFCraft = Net:WaitForChild("RF/Craft", 5)
    JobsRemoteFunction = Net:WaitForChild("RF/JobsRemoteFunction", 5)
    JobToolAbilities = Net:WaitForChild("RF/JobToolAbilities", 5)
end)

pcall(function()
    FishReplicated = ReplicatedStorage:WaitForChild("FishReplicated", 5)
    FishingRequest = FishReplicated:WaitForChild("FishingRequest", 5)
    FishingConfig = require(FishReplicated.FishingClient.Config)
end)

pcall(function()
    GetWaterHeightAtLocation = require(ReplicatedStorage.Util.GetWaterHeightAtLocation)
end)

-- ========== WORLD CHECK ==========
local placeId = game.PlaceId
local World1 = placeId == 2753915549 or placeId == 85211729168715 or placeId == 73902483975735
local World2 = placeId == 4442272183 or placeId == 79091703265657 or placeId == 73902483975735
local World3 = placeId == 7449423635 or placeId == 85211729168715 or placeId == 73902483975735
local Sea = World1 or World2 or World3

-- ========== GAME REFERENCES ==========
local Enemies = Workspace:FindFirstChild("Enemies") or Workspace
local replicated = ReplicatedStorage
local plr = Player
local Root = HumanoidRootPart
local Lv = (plr:FindFirstChild("Data") and plr.Data:FindFirstChild("Level") and plr.Data.Level.Value) or 0
local TeamSelf = plr.Team or "Pirates"
local Energy = (Character and Character:FindFirstChild("Energy") and Character.Energy.Value) or 100
local vim1 = VirtualInputManager
local vim2 = VirtualUser
local TW = TweenService

-- ========== NOTIFICATION CONFIG ==========
local lastNotificationTime = 0
local notificationCooldown = 10

-- ========== ALIASES ==========
local ply = Players
local RunSer = RunService

-- ========== LOCAL VARIABLES ==========
local Boss = {}
local BringConnections = {}
local MaterialList = {}
local NPCList = {}  
local shouldTween = false
local SoulGuitar = false
local KenTest = true
local debug = false
local Brazier1 = false
local Brazier2 = false
local Brazier3 = false  
local Sec = 0.1
local ClickState = 0
local Num_self = 25

-- ========== TEAM SETUP ==========
getgenv().Team = getgenv().Team or "Marines"

local loaded = false
local timeout = 0
repeat 
    pcall(function()
        if plr.PlayerGui and plr.PlayerGui:FindFirstChild("Main") then
            local start = plr.PlayerGui.Main:FindFirstChild("Loading")
            if start and game:IsLoaded() then
                loaded = true
            end
        end
    end)
    wait(1)
    timeout = timeout + 1
until loaded or timeout > 30

if CommF_Remote then
    if getgenv().Team == "Pirates" then
        pcall(function() CommF_Remote:InvokeServer("SetTeam", "Pirates") end)
    elseif getgenv().Team == "Marines" then
        pcall(function() CommF_Remote:InvokeServer("SetTeam", "Marines") end)
    else
        pcall(function() CommF_Remote:InvokeServer("SetTeam", "Pirates") end)
    end
end

-- ========== HELPER FUNCTIONS ==========
local fruitsOnSale = {}
local Nms = {}

local function addCommas(number)
    local formatted = tostring(number)
    while true do  
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

pcall(function()
    if CommF_Remote then
        for _, fruitData in pairs(CommF_Remote:InvokeServer("GetFruits", true) or {}) do
            if fruitData and fruitData["OnSale"] == true then
                table.insert(fruitsOnSale, fruitData["Name"])
            end
        end
        for _, fruitData in pairs(CommF_Remote:InvokeServer("GetFruits", false) or {}) do
            if fruitData and fruitData["OnSale"] == true then
                table.insert(Nms, fruitData["Name"])
            end
        end
    end
end)

-- ========== BOSS LISTS ==========
if World1 then
    Boss = {
        "The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader",
        "Vice Admiral", "Saber Expert", "Warden", "Chief Warden", "Swan",
        "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
        "Ice Admiral", "Greybeard"
    }
elseif World2 then
    Boss = {
        "Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral",
        "Awakened Ice Admiral", "Tide Keeper", "Darkbeard", "Cursed Captain", "Order"
    }
elseif World3 then
    Boss = {
        "Tyrant of the Skies", "Stone", "Hydra Leader", "Kilo Admiral",
        "Captain Elephant", "Beautiful Pirate", "Cake Queen", "Longma", "Soul Reaper"
    }
end

-- ========== MATERIAL LISTS ==========
if World1 then
    MaterialList = {"Leather + Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail"}
elseif World2 then
    MaterialList = {
        "Leather + Scrap Metal", "Radioactive Material", "Ectoplasm",
        "Mystic Droplet", "Magma Ore", "Vampire Fang"
    }
elseif World3 then
    MaterialList = {
        "Scrap Metal", "Demonic Wisp", "Conjured Cocoa", "Dragon Scale",
        "Gunpowder", "Fish Tail", "Mini Tusk"
    }
end

-- ========== STATIC LISTS ==========
local DungeonTables = {
    "Flame", "Ice", "Quake", "Light", "Dark", "String",
    "Rumble", "Magma", "Human: Buddha", "Sand", "Bird: Phoenix", "Dough"
}

local ListSeaBoat = {
    "Guardian", "PirateGrandBrigade", "MarineGrandBrigade",
    "PirateBrigade", "MarineBrigade", "PirateSloop", "MarineSloop", "Beast Hunter"
}

local code = {
    "LIGHTNINGABUSE", "1LOSTADMIN", "ADMINFIGHT", "NOMOREHACK", "BANEXPLOIT",
    "krazydares", "TRIPLEABUSE", "24NOADMIN", "REWARDFUN", "Chandler", "NEWTROLL",
    "KITT_RESET", "Magicbus", "Starcodeheo", "fudd10_v2", "Sub2UncleKizaru",
    "Fudd10", "Bignews", "SECRET_ADMIN", "SUB2GAMERROBOT_RESET1", "SUB2OFFICIALNOOBIE",
    "AXIORE", "BIGNEWS", "BLUXXY", "CHANDLER", "ENYU_IS_PRO", "FUDD10", "FUDD10_V2",
    "KITTGAMING", "MAGICBUS", "STARCODEHEO", "STRAWHATMAINE", "SUB2CAPTAINMAUI",
    "SUB2DAIGROCK", "SUB2FER999", "SUB2NOOBMASTER123", "SUB2UNCLEKIZARU",
    "TANTAIGAMING", "THEGREATACE", "WildDares", "BossBuild", "GetPranked",
    "FIGHT4FRUIT", "EARN_FRUITS"
}

local ListSeaZone = {"Lv 1", "Lv 2", "Lv 3", "Lv 4", "Lv 5", "Lv 6", "Lv Infinite"}

local RenMon = {"Snow Lurker", "Arctic Warrior", "Hidden Key", "Awakened Ice Admiral"}
local CursedTables = {
    ["Mob"] = "Mythological Pirate",
    ["Mob2"] = "Cursed Skeleton",
    "Hell's Messenger",
    ["Mob3"] = "Cursed Skeleton",
    "Heaven's Guardian"
}
local Past = {"Part", "SpawnLocation", "Terrain", "WedgePart", "MeshPart"}
local BartMon = {"Swan Pirate", "Jeremy"}
local CitizenTable = {"Forest Pirate", "Captain Elephant"}
local Human_v3_Mob = {"Fajita", "Jeremy", "Diamond"}
local AllBoats = {"Beast Hunter", "Lantern", "Guardian", "Grand Brigade", "Dinghy", "Sloop", "The Sentinel"}
local mastery1 = {"Cookie Crafter"}
local mastery2 = {"Reborn Skeleton"}

PosMsList = {
    ["Pirate Millionaire"] = CFrame.new(-712.8272705078125, 98.5770492553711, 5711.9541015625),
    ["Pistol Billionaire"] = CFrame.new(-723.4331665039062, 147.42906188964844, 5931.9931640625),
    ["Dragon Crew Warrior"] = CFrame.new(7021.50439453125, 55.76270294189453, -730.1290893554688),
    ["Dragon Crew Archer"] = CFrame.new(6625, 378, 244),
    ["Female Islander"] = CFrame.new(4692.7939453125, 797.9766845703125, 858.8480224609375),
    ["Venomous Assailant"] = CFrame.new(4902, 670, 39),
    ["Marine Commodore"] = CFrame.new(2401, 123, -7589),
    ["Marine Rear Admiral"] = CFrame.new(3588, 229, -7085),
    ["Fishman Raider"] = CFrame.new(-10941, 332, -8760),
    ["Fishman Captain"] = CFrame.new(-11035, 332, -9087),
    ["Forest Pirate"] = CFrame.new(-13446, 413, -7760),
    ["Mythological Pirate"] = CFrame.new(-13510, 584, -6987),
    ["Jungle Pirate"] = CFrame.new(-11778, 426, -10592),
    ["Musketeer Pirate"] = CFrame.new(-13282, 496, -9565),
    ["Reborn Skeleton"] = CFrame.new(-8764, 142, 5963),
    ["Living Zombie"] = CFrame.new(-10227, 421, 6161),
    ["Demonic Soul"] = CFrame.new(-9579, 6, 6194),
    ["Posessed Mummy"] = CFrame.new(-9579, 6, 6194),
    ["Peanut Scout"] = CFrame.new(-1993, 187, -10103),
    ["Peanut President"] = CFrame.new(-2215, 159, -10474),
    ["Ice Cream Chef"] = CFrame.new(-877, 118, -11032),
    ["Ice Cream Commander"] = CFrame.new(-877, 118, -11032),
    ["Cookie Crafter"] = CFrame.new(-2021, 38, -12028),
    ["Cake Guard"] = CFrame.new(-2024, 38, -12026),
    ["Baking Staff"] = CFrame.new(-1932, 38, -12848),
    ["Head Baker"] = CFrame.new(-1932, 38, -12848),
    ["Cocoa Warrior"] = CFrame.new(95, 73, -12309),
    ["Chocolate Bar Battler"] = CFrame.new(647, 42, -12401),
    ["Sweet Thief"] = CFrame.new(116, 36, -12478),
    ["Candy Rebel"] = CFrame.new(47, 61, -12889),
    ["Ghost"] = CFrame.new(5251, 5, 1111)
}

-- ========== EQUIP WEAPON ==========
EquipWeapon = function(text)
    if not text then return end
    if plr.Backpack:FindFirstChild(text) then
        pcall(function()
            plr.Character.Humanoid:EquipTool(plr.Backpack:FindFirstChild(text))
        end)
    end
end

weaponSc = function(weapon)
    for __in, v in pairs(plr.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            if v.ToolTip == weapon then 
                EquipWeapon(v.Name) 
            end
        end
    end
end

-- ========== HOOK FUNCTIONS (SAFE) ==========
pcall(function()
    hookfunction(require(game:GetService("ReplicatedStorage").Effect.Container.Death), function() end)
    hookfunction(require(game:GetService("ReplicatedStorage"):WaitForChild("GuideModule")).ChangeDisplayedNPC, function() end)
    hookfunction(error, function() end)
    hookfunction(warn, function() end)
end)

-- ========== REMOVE ROCKS ==========
local Rock = workspace:FindFirstChild("Rocks")
if Rock then Rock:Destroy() end

-- ========== OPTIMIZE LIGHTING ==========
pcall(function()
    local lightingLayers = Lighting:FindFirstChild("LightingLayers")
    if lightingLayers and Lighting then
        local darkFog = lightingLayers:FindFirstChild("DarkFog")
        if darkFog then darkFog:Destroy() end
    end
    
    local Water = workspace._WorldOrigin and workspace._WorldOrigin["Foam;"]
    if Water then Water:Destroy() end
end)

-- ========== ATTACK CLASS ==========
Attack = {}
Attack.__index = Attack

Attack.Alive = function(model) 
    if not model then return false end 
    local hum = model:FindFirstChild("Humanoid")
    return hum and hum.Health > 0 
end

Attack.Pos = function(model, dist) 
    return Root and (Root.Position - model.Position).Magnitude <= dist 
end

Attack.Dist = function(model, dist) 
    if not Root or not model then return false end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hrp and (Root.Position - hrp.Position).Magnitude <= dist 
end

Attack.DistH = function(model, dist) 
    if not Root or not model then return false end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    return hrp and (Root.Position - hrp.Position).Magnitude > dist 
end

Attack.Kill = function(model, Succes)
    if not (model and Succes) then return end
    pcall(function()
        if not model:GetAttribute("Locked") then 
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame) 
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        EquipWeapon(_G.SelectWeapon)
        local Equipped = plr.Character:FindFirstChildOfClass("Tool")
        local ToolTip = Equipped and Equipped.ToolTip or ""
        
        if ToolTip == "Blox Fruit" then 
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,10,0) * CFrame.Angles(0,math.rad(90),0)) 
        else 
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,30,0) * CFrame.Angles(0,math.rad(180),0))
        end
        
        if RandomCFrame then 
            wait(.5)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25)) 
            wait(.5)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(25, 30, 0)) 
            wait(.5)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(-25, 30 ,0)) 
            wait(.5)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25)) 
            wait(.5)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0))
        end
    end)
end

Attack.Kill2 = function(model, Succes)
    if not (model and Succes) then return end
    pcall(function()
        if not model:GetAttribute("Locked") then 
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame) 
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        EquipWeapon(_G.SelectWeapon)
        local Equipped = plr.Character:FindFirstChildOfClass("Tool")
        local ToolTip = Equipped and Equipped.ToolTip or ""
        
        if ToolTip == "Blox Fruit" then 
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,10,0) * CFrame.Angles(0,math.rad(90),0)) 
        else 
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,30,8) * CFrame.Angles(0,math.rad(180),0))
        end
        
        if RandomCFrame then 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(25, 30, 0)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(-25, 30 ,0)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0))
        end
    end)
end

Attack.KillSea = function(model, Succes)
    if not (model and Succes) then return end
    pcall(function()
        if not model:GetAttribute("Locked") then 
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame) 
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        EquipWeapon(_G.SelectWeapon)
        local Equipped = plr.Character:FindFirstChildOfClass("Tool")
        local ToolTip = Equipped and Equipped.ToolTip or ""
        
        if ToolTip == "Blox Fruit" then 
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,10,0) * CFrame.Angles(0,math.rad(90),0)) 
        else 
            notween(model.HumanoidRootPart.CFrame * CFrame.new(0,50,8)) 
            wait(.85)
            notween(model.HumanoidRootPart.CFrame * CFrame.new(0,400,0)) 
            wait(1)
        end
    end)
end

Attack.Sword = function(model, Succes)
    if not (model and Succes) then return end
    pcall(function()
        if not model:GetAttribute("Locked") then 
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame) 
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        weaponSc("Sword")
        _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,30,0))
        
        if RandomCFrame then 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(25, 30, 0)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(-25, 30 ,0)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0, 30, 25)) 
            wait(0.1)
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(-25, 30, 0))
        end
    end)
end

Attack.Mas = function(model, Succes)
    if not (model and Succes) then return end
    pcall(function()
        if not model:GetAttribute("Locked") then 
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame) 
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        
        if model.Humanoid.Health <= HealthM then
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,20,0))
            Useskills("Blox Fruit","Z")
            Useskills("Blox Fruit","X")
            Useskills("Blox Fruit","C")
        else
            weaponSc("Melee")
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,30,0))
        end
    end)
end

Attack.Masgun = function(model, Succes)
    if not (model and Succes) then return end
    pcall(function()
        if not model:GetAttribute("Locked") then 
            model:SetAttribute("Locked", model.HumanoidRootPart.CFrame) 
        end
        PosMon = model:GetAttribute("Locked").Position
        BringEnemy()
        
        if model.Humanoid.Health <= HealthM then
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,35,8))
            Useskills("Gun","Z")
            Useskills("Gun","X")
        else
            weaponSc("Melee")
            _tp(model.HumanoidRootPart.CFrame * CFrame.new(0,30,0))
        end
    end)
end

-- ========== STATS SETTINGS ==========
statsSetings = function(Num, value)
    pcall(function()
        if Num == "Melee" then
            if plr.Data.Points.Value ~= 0 then
                replicated.Remotes.CommF_:InvokeServer("AddPoint","Melee",value)
            end
        elseif Num == "Defense" then
            if plr.Data.Points.Value ~= 0 then
                replicated.Remotes.CommF_:InvokeServer("AddPoint","Defense",value)
            end
        elseif Num == "Sword" then
            if plr.Data.Points.Value ~= 0 then
                replicated.Remotes.CommF_:InvokeServer("AddPoint","Sword",value)
            end
        elseif Num == "Gun" then
            if plr.Data.Points.Value ~= 0 then
                replicated.Remotes.CommF_:InvokeServer("AddPoint","Gun",value)
            end
        elseif Num == "Devil" then
            if plr.Data.Points.Value ~= 0 then
                replicated.Remotes.CommF_:InvokeServer("AddPoint","Demon Fruit",value)
            end
        end
    end)
end

-- ========== BRING ENEMY ==========
BringEnemy = function()
    if not _B then return end
    pcall(function()
        for _,v in pairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                if v.PrimaryPart and PosMon and (v.PrimaryPart.Position - PosMon).Magnitude <= 300 then
                    v.PrimaryPart.CFrame = CFrame.new(PosMon)
                    v.PrimaryPart.CanCollide = true
                    if v:FindFirstChild("Humanoid") then
                        v.Humanoid.WalkSpeed = 0
                        v.Humanoid.JumpPower = 0
                    end
                    if v.Humanoid:FindFirstChild("Animator") then 
                        v.Humanoid.Animator:Destroy()
                    end
                    plr.SimulationRadius = math.huge
                end
            end                               
        end
    end)
end

-- ========== USE SKILLS ==========
Useskills = function(weapon, skill)
    pcall(function()
        if weapon == "Melee" then
            weaponSc("Melee")
            if skill == "Z" then
                vim1:SendKeyEvent(true, "Z", false, game)
                vim1:SendKeyEvent(false, "Z", false, game)
            elseif skill == "X" then
                vim1:SendKeyEvent(true, "X", false, game)
                vim1:SendKeyEvent(false, "X", false, game)
            elseif skill == "C" then
                vim1:SendKeyEvent(true, "C", false, game)
                vim1:SendKeyEvent(false, "C", false, game)
            end
        elseif weapon == "Sword" then
            weaponSc("Sword")
            if skill == "Z" then
                vim1:SendKeyEvent(true, "Z", false, game)
                vim1:SendKeyEvent(false, "Z", false, game)
            elseif skill == "X" then
                vim1:SendKeyEvent(true, "X", false, game)
                vim1:SendKeyEvent(false, "X", false, game)
            end
        elseif weapon == "Blox Fruit" then
            weaponSc("Blox Fruit")
            if skill == "Z" then
                vim1:SendKeyEvent(true, "Z", false, game)
                vim1:SendKeyEvent(false, "Z", false, game)
            elseif skill == "X" then
                vim1:SendKeyEvent(true, "X", false, game)
                vim1:SendKeyEvent(false, "X", false, game)
            elseif skill == "C" then
                vim1:SendKeyEvent(true, "C", false, game)
                vim1:SendKeyEvent(false, "C", false, game)        
            elseif skill == "V" then
                vim1:SendKeyEvent(true, "V", false, game)
                vim1:SendKeyEvent(false, "V", false, game)
            end
        elseif weapon == "Gun" then
            weaponSc("Gun")
            if skill == "Z" then
                vim1:SendKeyEvent(true, "Z", false, game)
                vim1:SendKeyEvent(false, "Z", false, game)
            elseif skill == "X" then
                vim1:SendKeyEvent(true, "X", false, game)
                vim1:SendKeyEvent(false, "X", false, game)
            end
        end
        
        if weapon == "nil" and skill == "Y" then
            vim1:SendKeyEvent(true, "Y", false, game)
            vim1:SendKeyEvent(false, "Y", false, game)
        end
    end)
end

-- ========== HOOK __NAMECALL ==========
local MousePos = Vector3.new()
local ABmethod = "AimBots Skill"

pcall(function()
    local gg = getrawmetatable(game)
    local old = gg.__namecall
    setreadonly(gg, false)
    gg.__namecall = newcclosure(function(...)
        local method = getnamecallmethod()
        local args = {...}    
        if tostring(method) == "FireServer" then
            if tostring(args[1]) == "RemoteEvent" then
                if tostring(args[2]) ~= "true" and tostring(args[2]) ~= "false" then
                    if (_G.FarmMastery_G and not SoulGuitar) or (_G.FarmMastery_Dev) or (_G.FarmBlazeEM) or (_G.Prehis_Skills) or (_G.SeaBeast1 or _G.FishBoat or _G.PGB or _G.Leviathan1 or _G.Complete_Trials) or (_G.AimMethod and ABmethod == "AimBots Skill") or (_G.AimMethod and ABmethod == "Auto Aimbots") then
                        args[2] = MousePos
                        return old(unpack(args))
                    end
                end
            end
        end
        return old(...)
    end)
end)

-- ========== GET CONNECTION ENEMIES ==========
GetConnectionEnemies = function(a)
    pcall(function()
        for i,v in pairs(replicated:GetChildren()) do
            if v:IsA("Model") and ((typeof(a) == "table" and table.find(a, v.Name)) or v.Name == a) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                return v
            end
        end
        
        for i,v in next, game.Workspace.Enemies:GetChildren() do
            if v:IsA("Model") and ((typeof(a) == "table" and table.find(a, v.Name)) or v.Name == a) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                return v
            end
        end
    end)
    return nil
end

-- ========== LOW CPU ==========
LowCpu = function()
    pcall(function()
        local g = game
        local w = g.Workspace
        local l = g.Lighting
        local t = w.Terrain
        
        t.WaterWaveSize = 0
        t.WaterWaveSpeed = 0
        t.WaterReflectance = 0
        t.WaterTransparency = 0
        l.GlobalShadows = false
        l.FogEnd = 9e9
        l.Brightness = 0
        settings().Rendering.QualityLevel = "Level01"
        
        for i, v in pairs(g:GetDescendants()) do
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
                v.TextureID = 10385902758728957
            end
        end
        
        for i, e in pairs(l:GetChildren()) do
            if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
                e.Enabled = false
            end
        end
    end)
end

-- ========== CHECK FUNCTIONS ==========
CheckF = function()
    return GetBP("Dragon-Dragon") or GetBP("Gas-Gas") or GetBP("Yeti-Yeti") or GetBP("Kitsune-Kitsune") or GetBP("T-Rex-T-Rex")
end

CheckBoat = function()
    for i, v in pairs(workspace.Boats:GetChildren()) do
        if v:FindFirstChild("Owner") and tostring(v.Owner.Value) == tostring(plr.Name) then
            return v    
        end
    end
    return false
end

CheckEnemiesBoat = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "FishBoat" and v:FindFirstChild("Health") and v.Health.Value > 0 then
            return true    
        end
    end
    return false
end

CheckPirateGrandBrigade = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if (v.Name == "PirateGrandBrigade" or v.Name == "PirateBrigade") and v:FindFirstChild("Health") and v.Health.Value > 0 then
            return true
        end
    end
    return false
end

CheckShark = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Shark" and Attack.Alive(v) then
            return true    
        end
    end
    return false
end

CheckTerrorShark = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Terrorshark" and Attack.Alive(v) then
            return true    
        end
    end
    return false
end

CheckPiranha = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Piranha" and Attack.Alive(v) then
            return true    
        end
    end
    return false
end

CheckFishCrew = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if (v.Name == "Fish Crew Member" or v.Name == "Haunted Crew Member") and Attack.Alive(v) then
            return true    
        end
    end
    return false
end

CheckHauntedCrew = function()
    for _,v in pairs(workspace.Enemies:GetChildren()) do
        if v.Name == "Haunted Crew Member" and Attack.Alive(v) then
            return true    
        end
    end
    return false
end

GetQuestDracoLevel = function()
    pcall(function()
        local v371 = {[1] = {NPC = "Dragon Wizard",Command = "Upgrade"}}
        return replicated.Modules.Net:FindFirstChild("RF/InteractDragonQuest"):InvokeServer(unpack(v371))
    end)
    return nil
end

CheckSeaBeast = function()
    return workspace.SeaBeasts and workspace.SeaBeasts:FindFirstChild("SeaBeast1") ~= nil
end

CheckLeviathan = function()
    return workspace.SeaBeasts and workspace.SeaBeasts:FindFirstChild("Leviathan") ~= nil
end

UpdStFruit = function()
    pcall(function()
        for z,x in next, plr.Backpack:GetChildren() do
            local StoreFruit = x:FindFirstChild("EatRemote", true)
            if StoreFruit then
                replicated.Remotes.CommF_:InvokeServer("StoreFruit", StoreFruit.Parent:GetAttribute("OriginalName"), plr.Backpack:FindFirstChild(x.Name))
            end
        end
    end)
end

collectFruits = function(Succes)
    if Succes then
        local char = plr.Character
        for _,v1 in pairs(workspace:GetChildren()) do
            if string.find(v1.Name, "Fruit") and v1:FindFirstChild("Handle") then 
                v1.Handle.CFrame = char.HumanoidRootPart.CFrame 
            end
        end
    end
end

Getmoon = function()
    if World1 then
        return Lighting.FantasySky and Lighting.FantasySky.MoonTextureId
    elseif World2 then
        return Lighting.FantasySky and Lighting.FantasySky.MoonTextureId
    elseif World3 then
        return Lighting.Sky and Lighting.Sky.MoonTextureId
    end
    return nil
end

DropFruits = function()
    pcall(function()
        for _,v3 in next, plr.Backpack:GetChildren() do
            if string.find(v3.Name, "Fruit") then
                EquipWeapon(v3.Name) 
                wait(.1)
                if plr.PlayerGui.Main.Dialogue.Visible then 
                    plr.PlayerGui.Main.Dialogue.Visible = false 
                end 
                EquipWeapon(v3.Name) 
                if plr.Character:FindFirstChild(v3.Name) and plr.Character[v3.Name]:FindFirstChild("EatRemote") then
                    plr.Character[v3.Name].EatRemote:InvokeServer("Drop")
                end
            end
        end
        
        for a,b2 in pairs(plr.Character:GetChildren()) do
            if string.find(b2.Name, "Fruit") then 
                EquipWeapon(b2.Name) 
                wait(.1)
                if plr.PlayerGui.Main.Dialogue.Visible then 
                    plr.PlayerGui.Main.Dialogue.Visible = false 
                end 
                EquipWeapon(b2.Name) 
                if b2:FindFirstChild("EatRemote") then
                    b2.EatRemote:InvokeServer("Drop")
                end
            end
        end
    end)
end

GetBP = function(v)
    return plr.Backpack:FindFirstChild(v) or plr.Character:FindFirstChild(v)
end

GetIn = function(Name)
    pcall(function()
        for _ ,v1 in pairs(replicated.Remotes.CommF_:InvokeServer("getInventory")) do
            if type(v1) == "table" then
                if v1.Name == Name or plr.Character:FindFirstChild(Name) or plr.Backpack:FindFirstChild(Name) then
                    return true
                end
            end
        end
    end)
    return false
end

GetM = function(Name)
    pcall(function()
        for _,tab in pairs(replicated.Remotes.CommF_:InvokeServer("getInventory")) do
            if type(tab) == "table" then
                if tab.Type == "Material" then
                    if tab.Name == Name then
                        return tab.Count
                    end
                end
            end
        end
    end)
    return 0
end

GetWP = function(nametool)
    pcall(function()
        for _,v4 in pairs(replicated.Remotes.CommF_:InvokeServer("getInventory")) do
            if type(v4) == "table" then
                if v4.Type == "Sword" then
                    if v4.Name == nametool or plr.Character:FindFirstChild(nametool) or plr.Backpack:FindFirstChild(nametool) then
                        return true
                    end
                end
            end
        end
    end)
    return false
end

getInfinity_Ability = function(Method, Var)
    if not Root then return end
    if Method == "Soru" and Var then
        pcall(function()
            for _,gc in next, getgc() do
                if plr.Character.Soru then
                    if (typeof(gc) == "function") and (getfenv(gc).script == plr.Character.Soru) then
                        for _, v in next, getupvalues(gc) do
                            if (typeof(v) == "table") then
                                repeat 
                                    wait(Sec) 
                                    v.LastUse = 0 
                                until not Var or (plr.Character.Humanoid.Health <= 0)
                            end
                        end
                    end
                end
            end
        end)    
    elseif Method == "Energy" and Var then
        if plr.Character:FindFirstChild("Energy") then
            plr.Character.Energy.Changed:connect(function()
                if Var then 
                    plr.Character.Energy.Value = Energy 
                end 
            end)
        end
    elseif Method == "Observation" and Var then
        local VisionRadius = plr:FindFirstChild("VisionRadius")
        if VisionRadius then VisionRadius.Value = math.huge end
    end
end

-- ========== REMOVE HOP FUNCTION ==========
-- Hop function has been REMOVED as requested

-- ========== BLOCK NOCLIP ==========
local block = Instance.new("Part", workspace)
block.Size = Vector3.new(1, 1, 1)
block.Name = "Rip_Indra"
block.Anchored = true
block.CanCollide = false
block.CanTouch = false
block.Transparency = 1
local blockfind = workspace:FindFirstChild(block.Name)
if blockfind and blockfind ~= block then blockfind:Destroy() end

task.spawn(function()
    while task.wait() do
        if block and block.Parent == workspace then 
            getgenv().OnFarm = shouldTween 
        else 
            getgenv().OnFarm = false 
        end
    end
end)

task.spawn(function()
    local a = game.Players.LocalPlayer
    repeat task.wait() until a.Character and a.Character.PrimaryPart
    block.CFrame = a.Character.PrimaryPart.CFrame
    while task.wait() do
        pcall(function()
            if getgenv().OnFarm then
                if block and block.Parent == workspace then
                    local b = a.Character and a.Character.PrimaryPart
                    if b and (b.Position - block.Position).Magnitude <= 200 then
                        b.CFrame = block.CFrame
                    else
                        block.CFrame = b.CFrame
                    end
                end
                local c = a.Character
                if c then
                    for d,e in pairs(c:GetChildren()) do
                        if e:IsA("BasePart") then e.CanCollide = false end
                    end
                end
            else
                local c = a.Character
                if c then
                    for d,e in pairs(c:GetChildren()) do
                        if e:IsA("BasePart") then e.CanCollide = true end
                    end
                end
            end
        end)
    end
end)

_tp = function(target)
    local character = plr.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local rootPart = character.HumanoidRootPart
    local distance = (target.Position - rootPart.Position).Magnitude
    
    local tweenInfo = TweenInfo.new(distance / (getgenv().TweenSpeed or 300), Enum.EasingStyle.Linear)
    local tween = game:GetService("TweenService"):Create(block, tweenInfo, {CFrame = target})    
    if plr.Character.Humanoid.Sit == true then
        block.CFrame = CFrame.new(block.Position.X, target.Y, block.Position.Z)
    end  
    tween:Play()    
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not shouldTween then tween:Cancel() break end
            task.wait(0.1)
        end
    end)
end

TeleportToTarget = function(targetCFrame)
    if (targetCFrame.Position - plr.Character.HumanoidRootPart.Position).Magnitude > 1000 then 
        _tp(targetCFrame)
    else 
        _tp(targetCFrame)
    end
end

notween = function(p)
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        plr.Character.HumanoidRootPart.CFrame = p
    end
end

function BTP(p)
    local player = game.Players.LocalPlayer
    local humanoidRootPart = player.Character.HumanoidRootPart
    local humanoid = player.Character.Humanoid
    local playerGui = player.PlayerGui.Main
    local targetPosition = p.Position
    local lastPosition = humanoidRootPart.Position
    repeat
        humanoid.Health = 0
        humanoidRootPart.CFrame = p
        playerGui.Quest.Visible = false
        if (humanoidRootPart.Position - lastPosition).Magnitude > 1 then
            lastPosition = humanoidRootPart.Position
            humanoidRootPart.CFrame = p
        end
        task.wait(0.5)
    until (p.Position - humanoidRootPart.Position).Magnitude <= 2000
end

-- ========== TWEEN CONTROL ==========
spawn(function()
    while task.wait() do
        pcall(function()
            if _G.SailBoat_Hydra or _G.WardenBoss or _G.AutoFactory or _G.HighestMirage or _G.HCM or _G.PGB or _G.Leviathan1 or _G.UPGDrago or _G.Complete_Trials or _G.TpDrago_Prehis or _G.BuyDrago or _G.AutoFireFlowers or _G.DT_Uzoth or _G.AutoBerry or _G.Prehis_Find or _G.Prehis_Skills or _G.Prehis_DB or _G.Prehis_DE or _G.FarmBlazeEM or _G.Dojoo or _G.CollectPresent or _G.AutoLawKak or _G.TpLab or _G.AutoPhoenixF or _G.AutoFarmChest or _G.AutoHytHallow or _G.LongsWord or _G.BlackSpikey or _G.AutoHolyTorch or _G.TrainDrago  or _G.AutoSaber or _G.FarmMastery_Dev or _G.CitizenQuest or _G.AutoEctoplasm or _G.KeysRen or _G.Auto_Rainbow_Haki or _G.obsFarm or _G.AutoBigmom or _G.Doughv2 or _G.AuraBoss or _G.Raiding or _G.Auto_Cavender or _G.TpPly or _G.Bartilo_Quest or _G.Level or _G.FarmEliteHunt or _G.AutoZou or _G.AutoFarm_Bone or getgenv().AutoMaterial or _G.CraftVM or _G.FrozenTP or _G.TPDoor or _G.AcientOne or _G.AutoFarmNear or _G.AutoRaidCastle or _G.DarkBladev3 or _G.AutoFarmRaid or _G.Auto_Cake_Prince or _G.Addealer or _G.TPNpc or _G.TwinHook or _G.FindMirage or _G.FarmChestM or _G.Shark or _G.TerrorShark or _G.Piranha or _G.MobCrew or _G.SeaBeast1 or _G.FishBoat or _G.AutoPole or _G.AutoPoleV2 or _G.Auto_SuperHuman or _G.AutoDeathStep or _G.Auto_SharkMan_Karate or _G.Auto_Electric_Claw or _G.AutoDragonTalon or _G.Auto_Def_DarkCoat or _G.Auto_God_Human or _G.Auto_Tushita or _G.AutoMatSoul or _G.AutoKenVTWO or _G.AutoSerpentBow or _G.AutoFMon or _G.Auto_Soul_Guitar or _G.TPGEAR or _G.AutoSaw or _G.AutoTridentW2 or _G.Auto_StartRaid or _G.AutoEvoRace or _G.AutoGetQuestBounty or _G.MarinesCoat or _G.TravelDres or _G.Defeating or _G.DummyMan or _G.Auto_Yama or _G.Auto_SwanGG or _G.SwanCoat or _G.AutoEcBoss or _G.Auto_Mink or _G.Auto_Human or _G.Auto_Skypiea or _G.Auto_Fish or _G.CDK_TS or _G.CDK_YM or _G.CDK or _G.AutoFarmGodChalice or _G.AutoFistDarkness or _G.AutoMiror or _G.Teleport or _G.AutoKilo or _G.AutoGetUsoap or _G.Praying or _G.TryLucky or _G.AutoColShad or _G.AutoUnHaki or _G.Auto_DonAcces or _G.AutoRipIngay or _G.DragoV3 or _G.DragoV1 or _G.SailBoats or NextIs or _G.FarmGodChalice or _G.IceBossRen or senth or senth2 or _G.Lvthan or _G.beasthunter or _G.DangerLV or _G.Relic123 or _G.tweenKitsune or _G.Collect_Ember or _G.AutofindKitIs or _G.snaguine or _G.TwFruits or _G.tweenKitShrine or _G.Tp_LgS or _G.Tp_MasterA or _G.tweenShrine or _G.FarmMastery_G or _G.FarmMastery_S or _G.ChestHOP or _G.RipHOP or _G.DoughKingHOP or _G.FarmTyrantHOP or _G.SoulReaperHOP or _G.FarmEliteHunterHOP or _G.DarkbeardHOP or _G.Auto_Def_DarkCoat or _G.FarmEliteHunt or _G.StartFarm or _G.AutoFightingStyle or _G.StartMastery or _G.Select_CDK_Type or _G.Auto_CDK_Quest or _G.AutoGhoul or _G.UpgradeRaceV2 or getgenv().AutoTouchPadHaki or getgenv().AutoFarmAllBoss or getgenv().AutoFarmBoss or _G.AutoEvoRace or _G.CyborgGet or _G.GhoulGet or _G.AcientOne or _G.TrainDrago or _G.HighestMirage or _G.TPGEAR or _G.Complete_Trials or _G.Defeating or _G.SwordMastery or _G.MeleeMastery or _G.FullyBone then
                shouldTween = true
                if not plr.Character.HumanoidRootPart:FindFirstChild("BodyClip") then
                    local Noclip = Instance.new("BodyVelocity")
                    Noclip.Name = "BodyClip"
                    Noclip.Parent = plr.Character.HumanoidRootPart
                    Noclip.MaxForce = Vector3.new(100000,100000,100000)
                    Noclip.Velocity = Vector3.new(0,0,0)
                end        
                if not plr.Character:FindFirstChild('highlight') then
                    local Test = Instance.new('Highlight')
                    Test.Name = "highlight"
                    Test.Enabled = true
                    Test.FillColor = Color3.fromRGB(255, 255, 255)
                    Test.OutlineColor = Color3.fromRGB(255,255,255)
                    Test.FillTransparency = 1
                    Test.OutlineTransparency = 1
                    Test.Parent = plr.Character
                end
                for _, no in pairs(plr.Character:GetDescendants()) do 
                    if no:IsA("BasePart") then no.CanCollide = false end 
                end
            else
                shouldTween = false
                if plr.Character.HumanoidRootPart:FindFirstChild("BodyClip") then 
                    plr.Character.HumanoidRootPart:FindFirstChild("BodyClip"):Destroy() 
                end
                if plr.Character:FindFirstChild('highlight') then 
                    plr.Character:FindFirstChild('highlight'):Destroy() 
                end	        
            end
        end)
    end
end)

-- ========== QUEST FUNCTIONS ==========
QuestB = function()
    pcall(function()
        if World1 then
            if _G.FindBoss == "The Gorilla King" then
                bMon = "The Gorilla King"
                Qname = "JungleQuest"
                Qdata = 3
                PosQBoss = CFrame.new(-1601.6553955078, 36.85213470459, 153.38809204102)
                PosB = CFrame.new(-1088.75977, 8.13463783, -488.559906, -0.707134247, 0, 0.707079291, 0, 1, 0, -0.707079291, 0, -0.707134247)
            elseif _G.FindBoss == "Bobby" then
                bMon = "Bobby"
                Qname = "BuggyQuest1"
                Qdata = 3
                PosQBoss = CFrame.new(-1140.1761474609, 4.752049446106, 3827.4057617188)
                PosB = CFrame.new(-1087.3760986328, 46.949409484863, 4040.1462402344)
            elseif _G.FindBoss == "The Saw" then
                bMon = "The Saw"
                PosB = CFrame.new(-784.89715576172, 72.427383422852, 1603.5822753906)
            elseif _G.FindBoss == "Yeti" then
                bMon = "Yeti"
                Qname = "SnowQuest"
                Qdata = 3
                PosQBoss = CFrame.new(1386.8073730469, 87.272789001465, -1298.3576660156)
                PosB = CFrame.new(1218.7956542969, 138.01184082031, -1488.0262451172)
            elseif _G.FindBoss == "Mob Leader" then
                bMon = "Mob Leader"
                PosB = CFrame.new(-2844.7307128906, 7.4180502891541, 5356.6723632813)
            elseif _G.FindBoss == "Vice Admiral" then
                bMon = "Vice Admiral"
                Qname = "MarineQuest2"
                Qdata = 2
                PosQBoss = CFrame.new(-5036.2465820313, 28.677835464478, 4324.56640625)
                PosB = CFrame.new(-5006.5454101563, 88.032081604004, 4353.162109375)
            elseif _G.FindBoss == "Saber Expert" then
                bMon = "Saber Expert"
                PosB = CFrame.new(-1458.89502, 29.8870335, -50.633564)
            elseif _G.FindBoss == "Warden" then
                bMon = "Warden"
                Qname = "ImpelQuest"
                Qdata = 1
                PosB = CFrame.new(5278.04932, 2.15167475, 944.101929, 0.220546961, -4.49946401e-06, 0.975376427, -1.95412576e-05, 1, 9.03162072e-06, -0.975376427, -2.10519756e-05, 0.220546961)
                PosQBoss = CFrame.new(5191.86133, 2.84020686, 686.438721, -0.731384635, 0, 0.681965172, 0, 1, 0, -0.681965172, 0, -0.731384635)
            elseif _G.FindBoss == "Chief Warden" then
                bMon = "Chief Warden"
                Qname = "ImpelQuest"
                Qdata = 2
                PosB = CFrame.new(5206.92578, 0.997753382, 814.976746, 0.342041343, -0.00062915677, 0.939684749, 0.00191645394, 0.999998152, -2.80422337e-05, -0.939682961, 0.00181045406, 0.342041939)
                PosQBoss = CFrame.new(5191.86133, 2.84020686, 686.438721, -0.731384635, 0, 0.681965172, 0, 1, 0, -0.681965172, 0, -0.731384635)
            elseif _G.FindBoss == "Swan" then
                bMon = "Swan"
                Qname = "ImpelQuest"
                Qdata = 3
                PosB = CFrame.new(5325.09619, 7.03906584, 719.570679, -0.309060812, 0, 0.951042235, 0, 1, 0, -0.951042235, 0, -0.309060812)
                PosQBoss = CFrame.new(5191.86133, 2.84020686, 686.438721, -0.731384635, 0, 0.681965172, 0, 1, 0, -0.681965172, 0, -0.731384635)
            elseif _G.FindBoss == "Magma Admiral" then
                bMon = "Magma Admiral"
                Qname = "MagmaQuest"
                Qdata = 3
                PosQBoss