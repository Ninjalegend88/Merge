-- Drag to Combine | Auto Merge Script
-- Key: Zkiller
-- Uses Rayfield UI Library

-- ─── LOAD RAYFIELD ──────────────────────────────────────────────────────

local Rayfield = nil
pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not Rayfield then
    pcall(function()
        Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua"))()
    end)
end

if not Rayfield then
    game.StarterGui:SetCore("SendNotification", {
        Title = "Error",
        Text = "Failed to load UI",
        Duration = 5
    })
    return
end

getgenv().SecureMode = true

-- ─── SERVICES ────────────────────────────────────────────────────────────

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ─── VARIABLES ───────────────────────────────────────────────────────────

local AutoMergeEnabled = false
local MergeSpeed = 1
local CurrentItems = {}
local ItemList = {}
local GameBoard = nil
local Dragging = false
local Mouse = LP:GetMouse()
local MergeQueue = {}
local IsMerging = false

-- ─── FIND GAME BOARD ──────────────────────────────────────────────────

local function FindGameBoard()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("board") or v.Name:lower():find("grid") or v.Name:lower():find("play") then
            return v
        end
    end
    -- Fallback: find any model with items
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and #v:GetChildren() > 5 then
            return v
        end
    end
    return Workspace
end

GameBoard = FindGameBoard()

-- ─── FIND ITEMS ON BOARD ─────────────────────────────────────────────

local function GetAllItems()
    local items = {}
    if GameBoard then
        for _, v in ipairs(GameBoard:GetDescendants()) do
            if v:IsA("Model") and v:FindFirstChild("Handle") or v:FindFirstChild("ClickDetector") or v:FindFirstChild("TouchInterest") then
                table.insert(items, v)
            end
        end
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():find("item") or v.Name:lower():find("food") or v.Name:lower():find("resource") or v.Name:lower():find("material")) then
            table.insert(items, v)
        end
    end
    return items
end

local function GetItemType(item)
    -- Try to determine item type from name or attributes
    local name = item.Name:lower()
    local types = {
        "wood", "stone", "iron", "gold", "diamond", "emerald", "ruby",
        "leather", "cloth", "silk", "wool", "cotton",
        "apple", "berry", "meat", "fish", "bread",
        "sword", "shield", "helmet", "armor", "boots",
        "ring", "necklace", "amulet", "crown",
        "wand", "staff", "bow", "arrow", "spear"
    }
    for _, t in ipairs(types) do
        if name:find(t) then
            return t
        end
    end
    -- Check for number values indicating tier/level
    local tier = item:FindFirstChild("Tier") or item:FindFirstChild("Level") or item:FindFirstChild("Value")
    if tier then
        return name .. "_" .. tostring(tier.Value)
    end
    return name
end

local function GetItemTier(item)
    local tier = item:FindFirstChild("Tier") or item:FindFirstChild("Level") or item:FindFirstChild("Value")
    if tier then
        return tier.Value
    end
    local name = item.Name:lower()
    local tiers = {"common", "uncommon", "rare", "epic", "legendary", "mythic", "godly"}
    for i, t in ipairs(tiers) do
        if name:find(t) then
            return i
        end
    end
    return 1
end

-- ─── COMBINATION LOGIC ─────────────────────────────────────────────────

local function CanCombine(item1, item2)
    if item1 == item2 then return false end
    local type1 = GetItemType(item1)
    local type2 = GetItemType(item2)
    if type1 == type2 then
        local tier1 = GetItemTier(item1)
        local tier2 = GetItemTier(item2)
        if tier1 == tier2 then
            return true
        end
    end
    return false
end

local function GetCombinationResult(item1, item2)
    -- Return what the combination would produce
    local name1 = item1.Name:lower()
    local name2 = item2.Name:lower()
    local tier1 = GetItemTier(item1)
    local tier2 = GetItemTier(item2)
    
    -- Try to find result from game objects
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find(name1) and v.Name:lower():find("combined") then
            return v
        end
    end
    
    -- Create result name based on tier
    local resultName = name1:gsub(" tier %d+", "") .. " Tier " .. (tier1 + 1)
    return resultName
end

-- ─── DRAG ITEMS ──────────────────────────────────────────────────────

local function DragItem(item, targetPos)
    -- Simulate dragging item to target position
    if not item or not targetPos then return end
    
    local root = item:FindFirstChild("HumanoidRootPart") or item:FindFirstChild("RootPart") or item.PrimaryPart
    if not root then return end
    
    -- Tween to target
    local tweenInfo = TweenInfo.new(0.2 / MergeSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    
    -- Wait for tween to finish
    tween.Completed:Wait()
    
    -- Trigger combine by sending click/input
    local clickDetector = item:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
    end
    
    -- Check for touch interest
    local touch = item:FindFirstChild("TouchInterest")
    if touch then
        firetouchinterest(root, touch.Parent, 0)
        firetouchinterest(root, touch.Parent, 1)
    end
    
    return true
end

local function FindItemPosition(item)
    local root = item:FindFirstChild("HumanoidRootPart") or item:FindFirstChild("RootPart") or item.PrimaryPart
    if root then
        return root.Position
    end
    return nil
end

-- ─── AUTO MERGE LOGIC ─────────────────────────────────────────────────

local function FindMergePairs()
    local items = GetAllItems()
    local pairs = {}
    
    for i = 1, #items do
        for j = i + 1, #items do
            if CanCombine(items[i], items[j]) then
                table.insert(pairs, {items[i], items[j]})
            end
        end
    end
    
    return pairs
end

local function ProcessMerges()
    if IsMerging then return end
    IsMerging = true
    
    local attempts = 0
    local maxAttempts = 50
    
    while AutoMergeEnabled and attempts < maxAttempts do
        local pairs = FindMergePairs()
        if #pairs == 0 then
            break
        end
        
        for _, pair in ipairs(pairs) do
            if not AutoMergeEnabled then break end
            
            local item1, item2 = pair[1], pair[2]
            local pos1 = FindItemPosition(item1)
            local pos2 = FindItemPosition(item2)
            
            if pos1 and pos2 then
                -- Drag item1 to item2's position
                local success = DragItem(item1, pos2)
                if success then
                    wait(0.1 / MergeSpeed)
                end
            end
        end
        
        attempts = attempts + 1
        wait(0.5 / MergeSpeed)
    end
    
    IsMerging = false
end

-- ─── FIND ALL COMBINATIONS ─────────────────────────────────────────────

local function GetFullCombinationTree()
    -- Scan game for all combination possibilities
    local combinations = {}
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Combination") then
            local combo = v:FindFirstChild("Combination")
            if combo:IsA("StringValue") then
                local parts = combo.Value:split("+")
                if #parts == 2 then
                    table.insert(combinations, {
                        Input1 = parts[1]:gsub(" ", ""),
                        Input2 = parts[2]:gsub(" ", ""),
                        Output = v.Name
                    })
                end
            end
        end
    end
    
    return combinations
end

-- ─── CREATE UI ──────────────────────────────────────────────────────────

local Window = Rayfield:CreateWindow({
    Name = "Drag to Combine",
    Icon = 0,
    LoadingTitle = "Auto Merge Hub",
    LoadingSubtitle = "by The Invisible Man",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DragCombine",
        FileName = "Config"
    },
    KeySystem = true,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Enter Key Below",
        Note = "Key: Zkiller",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"Zkiller"}
    }
})

local MainTab = Window:CreateTab("Auto Merge")
local CombosTab = Window:CreateTab("Combinations")
local SettingsTab = Window:CreateTab("Settings")

-- ─── AUTO MERGE TOGGLE ─────────────────────────────────────────────────

local AutoMergeToggle = MainTab:CreateToggle({
    Name = "Auto Merge",
    CurrentValue = false,
    Flag = "AutoMerge",
    Callback = function(Value)
        AutoMergeEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Merge",
                Content = "Enabled",
                Duration = 2
            })
            spawn(function()
                while AutoMergeEnabled do
                    ProcessMerges()
                    wait(1)
                end
            end)
        else
            IsMerging = false
            Rayfield:Notify({
                Title = "Auto Merge",
                Content = "Disabled",
                Duration = 2
            })
        end
    end
})

-- ─── MERGE SPEED ──────────────────────────────────────────────────────

local MergeSpeedSlider = MainTab:CreateSlider({
    Name = "Merge Speed",
    Range = {1, 10},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "MergeSpeed",
    Callback = function(Value)
        MergeSpeed = Value
    end
})

-- ─── SCAN BUTTONS ─────────────────────────────────────────────────────

local ScanItemsButton = MainTab:CreateButton({
    Name = "Scan for Items",
    Callback = function()
        local items = GetAllItems()
        Rayfield:Notify({
            Title = "Scan Complete",
            Content = "Found " .. #items .. " items",
            Duration = 2
        })
        print("Items found:")
        for _, v in ipairs(items) do
            print(" - " .. v.Name)
        end
    end
})

local ScanCombosButton = MainTab:CreateButton({
    Name = "Scan Combinations",
    Callback = function()
        local combos = GetFullCombinationTree()
        if #combos > 0 then
            Rayfield:Notify({
                Title = "Combinations Found",
                Content = "Found " .. #combos .. " combinations",
                Duration = 2
            })
        else
            Rayfield:Notify({
                Title = "No Combos",
                Content = "No combination data found in game",
                Duration = 2
            })
        end
    end
})

-- ─── COMBINATIONS LIST ─────────────────────────────────────────────────

local CombosList = CombosTab:CreateParagraph({
    Title = "Known Combinations",
    Content = "Scan game to find combinations"
})

local RefreshCombosButton = CombosTab:CreateButton({
    Name = "Refresh Combinations",
    Callback = function()
        local combos = GetFullCombinationTree()
        local text = ""
        for _, c in ipairs(combos) do
            text = text .. c.Input1 .. " + " .. c.Input2 .. " → " .. c.Output .. "\n"
        end
        if text == "" then
            text = "No combinations found\n\nTry scanning the game board"
        end
        CombosList:SetContent(text)
        Rayfield:Notify({
            Title = "Combinations",
            Content = "Updated",
            Duration = 2
        })
    end
})

-- ─── FIND BOARD ──────────────────────────────────────────────────────

local FindBoardButton = SettingsTab:CreateButton({
    Name = "Find Game Board",
    Callback = function()
        GameBoard = FindGameBoard()
        if GameBoard then
            Rayfield:Notify({
                Title = "Board Found",
                Content = GameBoard.Name,
                Duration = 2
            })
        else
            Rayfield:Notify({
                Title = "Board Not Found",
                Content = "Using workspace fallback",
                Duration = 2
            })
        end
    end
})

-- ─── CREDITS ──────────────────────────────────────────────────────────

local CreditsLabel = SettingsTab:CreateParagraph({
    Title = "Drag to Combine Hub",
    Content = "by The Invisible Man\nKey: Zkiller\nAuto merges all items on board"
})

-- ─── AUTO REFRESH LOOP ─────────────────────────────────────────────────

spawn(function()
    while true do
        wait(5)
        if AutoMergeEnabled and not IsMerging then
            spawn(function()
                ProcessMerges()
            end)
        end
    end
end)

-- ─── NOTIFY ON LOAD ──────────────────────────────────────────────────

Rayfield:Notify({
    Title = "Loaded",
    Content = "Drag to Combine Hub | by The Invisible Man",
    Duration = 3
})

print("[DragCombine] Loaded | Key: Zkiller")
