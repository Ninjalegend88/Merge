-- Drag to Combine | Auto Merge Script
-- Key: Zkiller

-- ─── ANTI-CHEAT BYPASS ──────────────────────────────────────────────────

local function BypassAntiCheat()
    pcall(function()
        local oldKick = game.Players.LocalPlayer.Kick
        game.Players.LocalPlayer.Kick = function(self, msg)
            if msg and (msg:find("tamper") or msg:find("cheat") or msg:find("exploit") or msg:find("detect") or msg:find("ban")) then
                warn("[AC] Blocked kick: " .. msg)
                return
            end
            return oldKick(self, msg)
        end
        
        local acNames = {"AntiCheat", "BanEvent", "DetectionEvent", "ReportEvent", "KickEvent", "LogEvent", "Watchdog", "SecurityCheck", "FileIntegrityCheck", "IntegrityCheck", "HashCheck"}
        for _, name in ipairs(acNames) do
            local r = game.ReplicatedStorage:FindFirstChild(name)
            if r then r:Destroy() end
        end
        
        for i, v in ipairs(game:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then
                local name = v.Name:lower()
                if name:find("anticheat") or name:find("watchdog") or name:find("security") or name:find("detect") then
                    v.Disabled = true
                end
            end
        end
    end)
end

BypassAntiCheat()

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
local Mouse = LP:GetMouse()

-- ─── VARIABLES ───────────────────────────────────────────────────────────

local AutoMergeEnabled = false
local MergeSpeed = 1
local IsMerging = false
local DebugMode = false
local ItemsFound = {}

-- ─── FIND ALL ITEMS ────────────────────────────────────────────────────

local function GetAllGameItems()
    local items = {}
    local searchRoots = {
        Workspace,
        game:GetService("Lighting"),
        ReplicatedStorage
    }
    
    for _, root in ipairs(searchRoots) do
        for _, v in ipairs(root:GetDescendants()) do
            if v:IsA("Model") then
                -- Check if it has click detector or touch interest (interactable)
                local hasClick = v:FindFirstChildOfClass("ClickDetector")
                local hasTouch = v:FindFirstChild("TouchInterest")
                local hasHandle = v:FindFirstChild("Handle")
                local hasRoot = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("RootPart")
                
                if hasClick or hasTouch or hasHandle or hasRoot then
                    -- Get item type from name or attributes
                    local tier = v:FindFirstChild("Tier") or v:FindFirstChild("Level") or v:FindFirstChild("Rarity")
                    local tierValue = tier and tier.Value or 1
                    local itemType = v.Name:gsub(" %d+", ""):gsub(" Tier %d+", ""):gsub(" Lv%.%d+", "")
                    
                    table.insert(items, {
                        Model = v,
                        Name = v.Name,
                        Type = itemType,
                        Tier = tierValue,
                        Root = hasRoot or v.PrimaryPart,
                        ClickDetector = hasClick,
                        TouchInterest = hasTouch,
                        Position = hasRoot and hasRoot.Position or v.PrimaryPart and v.PrimaryPart.Position or v:GetPivot().Position
                    })
                end
            end
        end
    end
    
    return items
end

-- ─── FIND MERGE PAIRS ──────────────────────────────────────────────────

local function FindMergePairs()
    local items = GetAllGameItems()
    local pairs = {}
    
    for i = 1, #items do
        for j = i + 1, #items do
            local a = items[i]
            local b = items[j]
            
            -- Check if same type and same tier
            if a.Type == b.Type and a.Tier == b.Tier then
                table.insert(pairs, {a, b})
            end
        end
    end
    
    return pairs
end

-- ─── SIMULATE DRAG ─────────────────────────────────────────────────────

local function SimulateDrag(item1, item2)
    if not item1 or not item2 then return false end
    
    local root1 = item1.Root or item1.Model:FindFirstChild("HumanoidRootPart") or item1.Model:FindFirstChild("RootPart") or item1.Model.PrimaryPart
    local root2 = item2.Root or item2.Model:FindFirstChild("HumanoidRootPart") or item2.Model:FindFirstChild("RootPart") or item2.Model.PrimaryPart
    
    if not root1 or not root2 then return false end
    
    local pos1 = root1.Position
    local pos2 = root2.Position
    local targetPos = pos2 + Vector3.new(0, 2, 0)
    
    -- Method 1: Tween the item
    local tweenInfo = TweenInfo.new(0.15 / MergeSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(root1, tweenInfo, {CFrame = CFrame.new(targetPos)})
    tween:Play()
    tween.Completed:Wait()
    
    -- Method 2: Fire click detector if exists
    if item1.ClickDetector then
        fireclickdetector(item1.ClickDetector)
        task.wait(0.05)
    end
    if item2.ClickDetector then
        fireclickdetector(item2.ClickDetector)
        task.wait(0.05)
    end
    
    -- Method 3: Simulate touch
    if root1 and root2 then
        local touch1 = root1:FindFirstChild("TouchInterest")
        local touch2 = root2:FindFirstChild("TouchInterest")
        
        if touch1 then
            firetouchinterest(root1, root2.Parent, 0)
            firetouchinterest(root1, root2.Parent, 1)
        end
        if touch2 then
            firetouchinterest(root2, root1.Parent, 0)
            firetouchinterest(root2, root1.Parent, 1)
        end
    end
    
    -- Method 4: Fire remote if exists
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            local name = remote.Name:lower()
            if name:find("merge") or name:find("combine") or name:find("craft") then
                pcall(function()
                    remote:FireServer(item1.Model, item2.Model)
                end)
            end
        end
    end
    
    return true
end

-- ─── AUTO MERGE LOOP ──────────────────────────────────────────────────

local function ProcessMerges()
    if IsMerging then return end
    IsMerging = true
    
    local attempts = 0
    local maxAttempts = 100
    
    while AutoMergeEnabled and attempts < maxAttempts do
        local pairs = FindMergePairs()
        
        if #pairs == 0 then
            if DebugMode then
                print("[Merge] No more mergeable items found")
            end
            break
        end
        
        if DebugMode then
            print("[Merge] Found " .. #pairs .. " mergeable pairs")
        end
        
        for _, pair in ipairs(pairs) do
            if not AutoMergeEnabled then break end
            
            local item1, item2 = pair[1], pair[2]
            
            if DebugMode then
                print("[Merge] Merging: " .. item1.Name .. " + " .. item2.Name)
            end
            
            local success = SimulateDrag(item1, item2)
            if success then
                wait(0.2 / MergeSpeed)
            end
        end
        
        attempts = attempts + 1
        wait(0.3 / MergeSpeed)
    end
    
    IsMerging = false
end

-- ─── GET ITEM LIST DISPLAY ────────────────────────────────────────────

local function GetItemListDisplay()
    local items = GetAllGameItems()
    local text = ""
    local grouped = {}
    
    for _, item in ipairs(items) do
        local key = item.Type .. " (Tier " .. item.Tier .. ")"
        if not grouped[key] then
            grouped[key] = 0
        end
        grouped[key] = grouped[key] + 1
    end
    
    for key, count in pairs(grouped) do
        text = text .. key .. ": " .. count .. "x\n"
    end
    
    if text == "" then
        text = "No items found on board"
    end
    
    return text
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
local ItemsTab = Window:CreateTab("Items")
local DebugTab = Window:CreateTab("Debug")
local SettingsTab = Window:CreateTab("Settings")

-- ─── AUTO MERGE ─────────────────────────────────────────────────────────

local AutoMergeToggle = MainTab:CreateToggle({
    Name = "Auto Merge",
    CurrentValue = false,
    Flag = "AutoMerge",
    Callback = function(Value)
        AutoMergeEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "Auto Merge",
                Content = "Enabled - Scanning for items...",
                Duration = 2
            })
            spawn(function()
                while AutoMergeEnabled do
                    ProcessMerges()
                    wait(0.5)
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

local MergeNowButton = MainTab:CreateButton({
    Name = "Merge Now (Single Pass)",
    Callback = function()
        if not IsMerging then
            spawn(function()
                ProcessMerges()
                Rayfield:Notify({
                    Title = "Merge Pass",
                    Content = "Completed",
                    Duration = 2
                })
            end)
        else
            Rayfield:Notify({
                Title = "Busy",
                Content = "Already merging",
                Duration = 1
            })
        end
    end
})

-- ─── ITEMS TAB ──────────────────────────────────────────────────────────

local ItemListLabel = ItemsTab:CreateParagraph({
    Title = "Items on Board",
    Content = GetItemListDisplay()
})

local RefreshItemsButton = ItemsTab:CreateButton({
    Name = "Refresh Item List",
    Callback = function()
        ItemListLabel:SetContent(GetItemListDisplay())
        local items = GetAllGameItems()
        Rayfield:Notify({
            Title = "Refreshed",
            Content = "Found " .. #items .. " items",
            Duration = 2
        })
    end
})

local ScanAllButton = ItemsTab:CreateButton({
    Name = "Full Game Scan",
    Callback = function()
        local items = GetAllGameItems()
        local text = ""
        for _, item in ipairs(items) do
            text = text .. item.Name .. " [Tier " .. item.Tier .. "] - " .. tostring(item.Position) .. "\n"
        end
        if text == "" then
            text = "No items found"
        end
        ItemListLabel:SetContent(text)
        Rayfield:Notify({
            Title = "Scan Complete",
            Content = "Found " .. #items .. " items",
            Duration = 2
        })
    end
})

-- ─── DEBUG TAB ──────────────────────────────────────────────────────────

local DebugToggle = DebugTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Flag = "DebugToggle",
    Callback = function(Value)
        DebugMode = Value
        Rayfield:Notify({
            Title = "Debug",
            Content = Value and "Enabled" or "Disabled",
            Duration = 2
        })
    end
})

local DebugInfo = DebugTab:CreateParagraph({
    Title = "Debug Info",
    Content = "Press 'Scan Debug' to update"
})

local ScanDebugButton = DebugTab:CreateButton({
    Name = "Scan Debug",
    Callback = function()
        local items = GetAllGameItems()
        local pairs = FindMergePairs()
        
        local info = ""
        info = info .. "Items Found: " .. #items .. "\n"
        info = info .. "Merge Pairs: " .. #pairs .. "\n"
        info = info .. "Board: " .. (Workspace:FindFirstChild("Board") and "Found" or "Not Found") .. "\n"
        info = info .. "ReplicatedStorage Remotes: "
        
        local remoteCount = 0
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                remoteCount = remoteCount + 1
            end
        end
        info = info .. remoteCount
        
        DebugInfo:SetContent(info)
        
        print("=== Debug Info ===")
        print("Items:", #items)
        print("Merge Pairs:", #pairs)
        for _, pair in ipairs(pairs) do
            print("  " .. pair[1].Name .. " + " .. pair[2].Name)
        end
        print("===================")
        
        Rayfield:Notify({
            Title = "Debug",
            Content = "Found " .. #items .. " items, " .. #pairs .. " pairs",
            Duration = 3
        })
    end
})

-- ─── SETTINGS TAB ──────────────────────────────────────────────────────

local CreditsLabel = SettingsTab:CreateParagraph({
    Title = "Drag to Combine Hub",
    Content = "by The Invisible Man\nKey: Zkiller\nAuto merges all items on the board"
})

-- ─── AUTO REFRESH ──────────────────────────────────────────────────────

spawn(function()
    while true do
        wait(10)
        if AutoMergeEnabled and not IsMerging then
            spawn(function()
                ProcessMerges()
            end)
        end
        if not AutoMergeEnabled then
            ItemListLabel:SetContent(GetItemListDisplay())
        end
    end
end)

-- ─── NOTIFY ON LOAD ──────────────────────────────────────────────────

Rayfield:Notify({
    Title = "Loaded",
    Content = "Drag to Combine Hub | by The Invisible Man",
    Duration = 3
})

print("[Merge] Loaded | Key: Zkiller")
