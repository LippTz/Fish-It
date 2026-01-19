--[[
    KREINXY Script - Fishing Automation
    Cleaned & Optimized Version
]]

-- ============================================
-- LOAD UI LIBRARY
-- ============================================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "KREINXY | First It",
    Icon = "door-open",
    Author = "by KREINXY",
    Folder = "BlatantScript",
    Size = UDim2.fromOffset(600, 480),
    MinSize = Vector2.new(560, 360),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    KeySystem = false
})

Window:Tag({
    Title = "KREINXY",
    Icon = "github",
    Color = Color3.fromHex("#30ff6a"),
    Radius = 0,
})

-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================
-- NETWORK REMOTES
-- ============================================
local Net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

local Remotes = {
    Charge = Net:WaitForChild("RF/ChargeFishingRod"),
    Request = Net:WaitForChild("RF/RequestFishingMinigameStarted"),
    Cancel = Net:WaitForChild("RF/CancelFishingInputs"),
    Complete = Net:WaitForChild("RE/FishingCompleted"),
    SellAll = Net:WaitForChild("RF/SellAllItems"),
    Weather = Net:WaitForChild("RF/PurchaseWeatherEvent")
}

-- ============================================
-- GLOBAL STATE
-- ============================================
local State = {
    -- Blatant Fishing
    FishingRunning = false,
    CompleteDelay = 0.71,
    CancelDelay = 0.32,
    Phase = "STEP123",
    LastStepTime = 0,
    LoopThread = nil,
    
    -- Teleport
    SelectedLocation = "Fisherman Island",
    SelectedPlayer = nil,
    SelectedEvents = {},
    EventTeleportEnabled = false,
    SavedCFrame = nil,
    TeleportedToEvent = false,
    
    -- Shop
    SelectedWeathers = {},
    WeatherSpam = false,
    
    -- Misc
    NoAnimationEnabled = false,
    AnimConnection = nil,
    NoNotificationEnabled = false,
    HUDEnabled = false,
    AntiAFKEnabled = false
}

-- ============================================
-- BLATANT TAB - FISHING AUTOMATION
-- ============================================
local BlatantTab = Window:Tab({
    Title = "Blatant",
    Icon = "zap"
})

BlatantTab:Paragraph({
    Title = "Blatant Fishing",
    Desc = "Auto fishing by forcing server steps.\n⚠ High risk – use wisely."
})

BlatantTab:Divider()

local BlatantMain = BlatantTab:Section({
    Title = "Main Control",
    Opened = true
})

-- ============================================
-- OPTIMIZED BLATANT FISHING SYSTEM
-- ============================================

-- Enhanced State dengan Stats Tracking
local FishingStats = {
    Success = 0,
    Fail = 0,
    TotalAttempts = 0,
    LastAdjust = os.clock(),
    CurrentSpeed = "Normal"
}

-- Fishing Functions (Optimized)
local function OptimizedForceStep123()
    local timestamp = os.clock()
    local success, errorMsg = pcall(function()
        Remotes.Cancel:InvokeServer()
        Remotes.Charge:InvokeServer({[1] = timestamp})
        Remotes.Request:InvokeServer(timestamp, timestamp, timestamp)
    end)
    
    FishingStats.TotalAttempts = FishingStats.TotalAttempts + 1
    
    if success then
        FishingStats.Success = FishingStats.Success + 1
    else
        FishingStats.Fail = FishingStats.Fail + 1
        warn("⚠️ Step123 failed:", errorMsg)
    end
    
    return success
end

local function OptimizedForceStep4()
    local success = pcall(function()
        Remotes.Complete:FireServer()
        Remotes.Complete:FireServer()
    end)
    
    if not success then
        warn("⚠️ Step4 failed")
    end
    
    return success
end

local function OptimizedForceCancel()
    pcall(function()
        Remotes.Complete:FireServer()
        Remotes.Cancel:InvokeServer()
        Remotes.Cancel:InvokeServer()
    end)
end

-- Auto Adaptive Delay System
local function AutoAdjustDelay()
    local now = os.clock()
    
    -- Adjust setiap 15 detik
    if (now - FishingStats.LastAdjust) < 15 then
        return
    end
    
    local total = FishingStats.Success + FishingStats.Fail
    if total < 5 then return end  -- Butuh minimal 5 attempts untuk adjust
    
    local successRate = FishingStats.Success / total
    
    if successRate < 0.6 then
        -- Success rate rendah (<60%) - SLOW DOWN
        State.CompleteDelay = math.min(1.2, State.CompleteDelay + 0.08)
        State.CancelDelay = math.min(0.6, State.CancelDelay + 0.04)
        FishingStats.CurrentSpeed = "Slow"
        print("🐌 Low success rate! Speed: SLOW | Delay +")
        
    elseif successRate < 0.8 then
        -- Success rate medium (60-80%) - MAINTAIN
        FishingStats.CurrentSpeed = "Normal"
        print("⚡ Medium success rate. Speed: NORMAL")
        
    elseif successRate >= 0.9 then
        -- Success rate tinggi (>90%) - SPEED UP
        State.CompleteDelay = math.max(0.25, State.CompleteDelay - 0.05)
        State.CancelDelay = math.max(0.08, State.CancelDelay - 0.02)
        FishingStats.CurrentSpeed = "Fast"
        print("🚀 High success rate! Speed: FAST | Delay -")
    end
    
    -- Reset stats untuk next cycle
    FishingStats.LastAdjust = now
    FishingStats.Success = 0
    FishingStats.Fail = 0
    
    -- Print current delays
    print(string.format("📊 Complete: %.2fs | Cancel: %.2fs", 
        State.CompleteDelay, State.CancelDelay))
end

-- Smart Retry System
local function SmartRetry(func, maxRetries)
    maxRetries = maxRetries or 2
    
    for attempt = 1, maxRetries do
        if func() then
            return true
        end
        
        if attempt < maxRetries then
            task.wait(0.05)  -- Short retry delay
        end
    end
    
    return false
end

-- Optimized Main Loop
local function StartOptimizedLoop()
    if State.LoopThread then
        task.cancel(State.LoopThread)
    end

    State.Phase = "INIT23"
    State.LastStepTime = os.clock()
    
    -- Reset stats
    FishingStats.Success = 0
    FishingStats.Fail = 0
    FishingStats.TotalAttempts = 0
    FishingStats.LastAdjust = os.clock()

    print("✅ Optimized Fishing Started!")

    State.LoopThread = task.spawn(function()
        while State.FishingRunning do
            task.wait(0.02)  -- Minimal safe delay
            local now = os.clock()
            
            -- Auto adjust delays based on success rate
            AutoAdjustDelay()

            -- Timeout protection (reset if stuck)
            if (now - State.LastStepTime) > 8 then
                warn("⏰ Timeout detected! Resetting phase...")
                State.Phase = "STEP123"
                State.LastStepTime = now
            end

            -- PHASE: INIT23 atau STEP123 (Start Fishing)
            if State.Phase == "INIT23" or State.Phase == "STEP123" then
                State.LastStepTime = now
                
                -- Retry system untuk handle failures
                if SmartRetry(OptimizedForceStep123, 2) then
                    State.Phase = "WAIT_COMPLETE"
                else
                    -- Kalau masih gagal, wait sebentar
                    task.wait(0.2)
                end

            -- PHASE: WAIT_COMPLETE (Tunggu Complete Delay)
            elseif State.Phase == "WAIT_COMPLETE" then
                if (now - State.LastStepTime) >= State.CompleteDelay then
                    State.Phase = "STEP4"
                end

            -- PHASE: STEP4 (Complete Fishing)
            elseif State.Phase == "STEP4" then
                State.LastStepTime = now
                OptimizedForceStep4()
                State.Phase = "WAIT_STOP"

            -- PHASE: WAIT_STOP (Tunggu Cancel Delay)
            elseif State.Phase == "WAIT_STOP" then
                if (now - State.LastStepTime) >= State.CancelDelay then
                    State.Phase = "STEP123"
                end
            end
        end
        
        print("🛑 Optimized Fishing Stopped!")
    end)
end

-- ============================================
-- BLATANT UI CONTROLS (UPDATED)
-- ============================================

BlatantMain:Toggle({
    Title = "Blatant Fishing (Optimized)",
    Desc = "Auto-adaptive speed system",
    Value = false,
    Callback = function(enabled)
        State.FishingRunning = enabled
        if enabled then
            StartOptimizedLoop()  -- ✅ Pakai optimized version
        else
            -- Safe stop with multiple cancels
            OptimizedForceCancel()
            task.wait(0.5)
            OptimizedForceCancel()
            task.wait(0.3)
            OptimizedForceCancel()
        end
    end
})

BlatantMain:Input({
    Title = "Complete Delay",
    Desc = "Delay before Step 4 (auto-adjusts)",
    Value = tostring(State.CompleteDelay),
    Callback = function(value)
        local num = tonumber(value)
        if num then
            State.CompleteDelay = math.max(0.1, num)
            print("✅ Complete Delay set to:", State.CompleteDelay)
        end
    end
})

BlatantMain:Input({
    Title = "Cancel Delay",
    Desc = "Delay before restart (auto-adjusts)",
    Value = tostring(State.CancelDelay),
    Callback = function(value)
        local num = tonumber(value)
        if num then
            State.CancelDelay = math.max(0.05, num)
            print("✅ Cancel Delay set to:", State.CancelDelay)
        end
    end
})

-- Stats Display (Real-time monitoring)
BlatantMain:Paragraph({
    Title = "📊 Statistics",
    Desc = "Will update during fishing..."
})

-- Stats Update Loop
task.spawn(function()
    while task.wait(3) do
        if State.FishingRunning then
            local total = FishingStats.TotalAttempts
            local rate = total > 0 and (FishingStats.Success / total * 100) or 0
            
            local statsText = string.format(
                "Speed: %s | Success: %d | Fail: %d\nRate: %.1f%% | Total: %d",
                FishingStats.CurrentSpeed,
                FishingStats.Success,
                FishingStats.Fail,
                rate,
                total
            )
            
            print("📊 " .. statsText)
            
            -- Update UI paragraph kalau didukung
            -- BlatantMain:UpdateParagraph(statsText)
        end
    end
end)

-- ============================================
-- ADVANCED FEATURES (BONUS)
-- ============================================

-- Speed Presets
local SpeedPresets = {
    ["Safe"] = {Complete = 0.71, Cancel = 0.32},
    ["Balanced"] = {Complete = 0.45, Cancel = 0.18},
    ["Fast"] = {Complete = 0.30, Cancel = 0.12},
    ["Turbo"] = {Complete = 0.20, Cancel = 0.08}
}

BlatantMain:Dropdown({
    Title = "Speed Preset",
    Desc = "Quick delay presets",
    Values = {"Safe", "Balanced", "Fast", "Turbo"},
    Value = "Safe",
    Callback = function(preset)
        local settings = SpeedPresets[preset]
        if settings then
            State.CompleteDelay = settings.Complete
            State.CancelDelay = settings.Cancel
            print(string.format("⚡ Preset '%s' loaded! Complete: %.2f | Cancel: %.2f", 
                preset, settings.Complete, settings.Cancel))
        end
    end
})

-- Emergency Stop Button
BlatantMain:Button({
    Title = "🚨 Emergency Stop",
    Desc = "Force stop all fishing operations",
    Callback = function()
        State.FishingRunning = false
        
        if State.LoopThread then
            task.cancel(State.LoopThread)
            State.LoopThread = nil
        end
        
        -- Multiple cancel attempts
        for i = 1, 5 do
            OptimizedForceCancel()
            task.wait(0.2)
        end
        
        print("🛑 EMERGENCY STOP EXECUTED!")
    end
})

BlatantTab:Divider()

-- Utility Section
local BlatantUtil = BlatantTab:Section({
    Title = "Utility",
    Opened = true
})

BlatantUtil:Button({
    Title = "Sell All Items",
    Callback = function()
        pcall(function()
            Remotes.SellAll:InvokeServer()
        end)
    end
})

BlatantTab:Divider()

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map"
})

TeleportTab:Paragraph({
    Title = "Teleport System",
    Desc = "Location, Player & Event teleport"
})

TeleportTab:Divider()

-- Location Teleport
local LocationSection = TeleportTab:Section({
    Title = "Location Teleport",
    Opened = true
})

local Locations = {
    ["Fisherman Island"] = CFrame.new(34, 26, 2776),
    ["Jungle"] = CFrame.new(1483, 11, -300),
    ["Ancient Ruin"] = CFrame.new(6085, -586, 4639),
    ["Crater Island"] = CFrame.new(1013, 23, 5079),
    ["Christmas Island"] = CFrame.new(1135, 24, 1563),
    ["Christmas Cafe"] = CFrame.new(580, -581, 8930),
    ["Coral"] = CFrame.new(-3029, 3, 2260),
    ["Kohana"] = CFrame.new(-635, 16, 603),
    ["Volcano"] = CFrame.new(-597, 59, 106),
    ["Esetoric Depth"] = CFrame.new(3203, -1303, 1415),
    ["Sisyphus Statue"] = CFrame.new(-3712, -135, -1013),
    ["Treasure"] = CFrame.new(-3566, -279, -1681),
    ["Tropical"] = CFrame.new(-2093, 6, 3699),
}

local function GetLocationList()
    local list = {}
    for name in pairs(Locations) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

LocationSection:Dropdown({
    Title = "Select Location",
    Values = GetLocationList(),
    Value = State.SelectedLocation,
    Callback = function(location)
        State.SelectedLocation = location
    end
})

LocationSection:Button({
    Title = "Teleport",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char.PrimaryPart then
            char:SetPrimaryPartCFrame(Locations[State.SelectedLocation])
        end
    end
})

TeleportTab:Divider()

-- Player Teleport
local PlayerSection = TeleportTab:Section({
    Title = "Player Teleport",
    Opened = true
})

local function GetPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player.Name)
        end
    end
    table.sort(list)
    return list
end

local PlayerDropdown = PlayerSection:Dropdown({
    Title = "Select Player",
    Values = GetPlayerList(),
    Callback = function(playerName)
        State.SelectedPlayer = playerName
    end
})

PlayerSection:Button({
    Title = "Refresh Player List",
    Callback = function()
        PlayerDropdown:SetValues(GetPlayerList())
    end
})

PlayerSection:Button({
    Title = "Teleport To Player",
    Callback = function()
        if not State.SelectedPlayer then return end
        
        local target = Players:FindFirstChild(State.SelectedPlayer)
        if target and target.Character and target.Character.PrimaryPart then
            LocalPlayer.Character:SetPrimaryPartCFrame(
                target.Character.PrimaryPart.CFrame * CFrame.new(0, 1, 0)
            )
        end
    end
})

TeleportTab:Divider()

-- Event Teleport
local EventSection = TeleportTab:Section({
    Title = "Event Teleport",
    Opened = true
})

local EventNames = {
    "Megalodon Hunt",
    "Shark Hunt",
    "Ghost Shark Hunt",
}

EventSection:Dropdown({
    Title = "Select Event",
    Desc = "Teleport once when event appears",
    Values = EventNames,
    Multi = true,
    Callback = function(events)
        State.SelectedEvents = events
    end
})

EventSection:Toggle({
    Title = "Enable Event Teleport",
    Desc = "Auto teleport once & return after event ends",
    Value = false,
    Callback = function(enabled)
        State.EventTeleportEnabled = enabled

        if not enabled and State.TeleportedToEvent and State.SavedCFrame then
            pcall(function()
                LocalPlayer.Character:SetPrimaryPartCFrame(State.SavedCFrame)
            end)
            State.SavedCFrame = nil
            State.TeleportedToEvent = false
        end
    end
})

EventSection:Divider()

EventSection:Paragraph({
    Title = "Info",
    Desc = "• Teleport hanya 1x saat event muncul\n• Posisi disimpan otomatis\n• Akan kembali saat event selesai atau toggle OFF"
})

-- Event CFrame Finder
local function GetEventCFrame(eventName)
    local menu = workspace:FindFirstChild("!!! MENU RINGS")
    if not menu then return end

    local props = menu:FindFirstChild("Props")
    if not props then return end

    local event = props:FindFirstChild(eventName)
    if not event then return end

    if event:IsA("BasePart") then
        return event.CFrame
    end

    if event:IsA("Model") and event.PrimaryPart then
        return event.PrimaryPart.CFrame
    end

    for _, obj in ipairs(event:GetDescendants()) do
        if obj:IsA("BasePart") then
            return obj.CFrame
        end
    end
end

-- Event Monitor
task.spawn(function()
    while task.wait(1) do
        if not State.EventTeleportEnabled then continue end
        if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then continue end

        local foundEvent = false

        for _, eventName in ipairs(State.SelectedEvents) do
            local eventCF = GetEventCFrame(eventName)

            if eventCF then
                foundEvent = true

                if not State.TeleportedToEvent then
                    State.SavedCFrame = LocalPlayer.Character.PrimaryPart.CFrame
                    LocalPlayer.Character:SetPrimaryPartCFrame(eventCF)
                    State.TeleportedToEvent = true
                end

                break
            end
        end

        if State.TeleportedToEvent and not foundEvent then
            if State.SavedCFrame then
                LocalPlayer.Character:SetPrimaryPartCFrame(State.SavedCFrame)
            end
            State.SavedCFrame = nil
            State.TeleportedToEvent = false
        end
    end
end)

TeleportTab:Divider()

-- ============================================
-- SHOP TAB
-- ============================================
local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "shopping-cart"
})

local ShopSection = ShopTab:Section({
    Title = "Weather Shop",
    Opened = true
})

local WeatherList = {
    "Wind", "Storm", "Cloudy", "Snow", "Radiant", "Shark Hunt"
}

ShopSection:Dropdown({
    Title = "Select Weather",
    Values = WeatherList,
    Multi = true,
    Callback = function(weathers)
        State.SelectedWeathers = weathers
    end
})

ShopSection:Toggle({
    Title = "Auto Buy Weather",
    Value = false,
    Callback = function(enabled)
        State.WeatherSpam = enabled
    end
})

-- Weather Purchase Loop
task.spawn(function()
    while task.wait(0.5) do
        if not State.WeatherSpam then continue end
        
        for _, weather in ipairs(State.SelectedWeathers) do
            pcall(function()
                Remotes.Weather:InvokeServer(weather)
            end)
            task.wait(0.8)
        end
    end
end)

ShopTab:Divider()

-- ============================================
-- MISC TAB
-- ============================================
local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "settings"
})

local MiscSection = MiscTab:Section({
    Title = "Performance & Visual",
    Opened = true
})

MiscSection:Button({
    Title = "Boost FPS (Max)",
    Callback = function()
        -- Disable Shadows & Reflections
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0
        Lighting.Brightness = 5

        -- Heavy Fog
        Lighting.FogStart = 0
        Lighting.FogEnd = 100
        Lighting.FogColor = Color3.fromRGB(255, 5, 5)

        -- Disable Post Effects
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end

        -- Remove Textures & Particles
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Texture") or obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("MeshPart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
            elseif obj:IsA("Part") or obj:IsA("UnionOperation") then
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            end
        end

        -- Optimize Terrain
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain:SetMaterialColor(Enum.Material.Grass, Color3.new(0, 0, 0))
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end

        -- Boost Camera FOV
        task.spawn(function()
            for i = 1, 60 do
                if Players.SSASSAA11 then
                    Players.SSASSAA11.CameraMaxZoomDistance = 1000
                end
                task.wait()
            end
        end)

        print("BOOST FPS MAX ACTIVATED!")
    end
})

MiscSection:Button({
    Title = "No Effect",
    Callback = function()
        local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
        if cosmeticFolder then
            cosmeticFolder:Destroy()
        end
    end
})

-- No Animations
local function ApplyNoAnimation(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator", humanoid)
    end

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end

    if State.AnimConnection then
        State.AnimConnection:Disconnect()
    end
    
    State.AnimConnection = animator.AnimationPlayed:Connect(function(track)
        track:Stop()
    end)
end

MiscSection:Toggle({
    Title = "No Animations",
    Desc = "Disable all character animations",
    Value = false,
    Callback = function(enabled)
        State.NoAnimationEnabled = enabled

        if enabled then
            if LocalPlayer.Character then
                ApplyNoAnimation(LocalPlayer.Character)
            end
        else
            if State.AnimConnection then
                State.AnimConnection:Disconnect()
                State.AnimConnection = nil
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    if State.NoAnimationEnabled then
        task.wait(1)
        ApplyNoAnimation(char)
    end
end)

-- No Notifications
local function ApplyNoNotification()
    local gui = PlayerGui:FindFirstChild("Small Notification")
    if not gui then return end

    local display = gui:FindFirstChild("Display")
    if display then
        display.Visible = not State.NoNotificationEnabled
    end
end

MiscSection:Toggle({
    Title = "No Notifications",
    Desc = "Hide small notification popup",
    Value = false,
    Callback = function(enabled)
        State.NoNotificationEnabled = enabled
        ApplyNoNotification()
    end
})

PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "Small Notification" then
        task.wait(0.2)
        ApplyNoNotification()
    end
end)

MiscTab:Divider()

-- HUD FPS + Ping
local HUDSection = MiscTab:Section({
    Title = "HUD Monitor",
    Opened = true
})

local HUDGui, HUDLabel

HUDSection:Toggle({
    Title = "Show FPS & Ping HUD",
    Value = false,
    Callback = function(enabled)
        State.HUDEnabled = enabled

        if enabled then
            if not HUDGui then
                HUDGui = Instance.new("ScreenGui")
                HUDGui.Name = "HUD_FPSPING"
                HUDGui.ResetOnSpawn = false
                HUDGui.Parent = CoreGui

                HUDLabel = Instance.new("TextLabel")
                HUDLabel.Name = "Display"
                HUDLabel.Parent = HUDGui
                HUDLabel.Size = UDim2.new(0, 200, 0, 38)
                HUDLabel.Position = UDim2.new(1, -200, 0, 8)
                HUDLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                HUDLabel.BackgroundTransparency = 0.45
                HUDLabel.BorderSizePixel = 0
                HUDLabel.TextColor3 = Color3.fromRGB(0, 255, 125)
                HUDLabel.Font = Enum.Font.Code
                HUDLabel.TextSize = 15
                HUDLabel.Text = "FPS: --  |  Ping: --"

                -- Make Draggable
                local dragging, dragStart, startPos

                HUDLabel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        dragStart = input.Position
                        startPos = HUDLabel.Position
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local delta = input.Position - dragStart
                        HUDLabel.Position = UDim2.new(
                            startPos.X.Scale, startPos.X.Offset + delta.X,
                            startPos.Y.Scale, startPos.Y.Offset + delta.Y
                        )
                    end
                end)

                HUDLabel.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)
            end
            HUDGui.Enabled = true
        else
            if HUDGui then
                HUDGui.Enabled = false
            end
        end
    end
})

-- HUD Update Loop
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.HUDEnabled and HUDGui and HUDLabel then
            local fps = math.floor(1 / RunService.RenderStepped:Wait())
            local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            HUDLabel.Text = string.format("FPS: %d  |  Ping: %dms", fps, math.floor(ping))
        end
    end
end)

MiscTab:Divider()

-- Anti-AFK
local AFKSection = MiscTab:Section({
    Title = "Anti-AFK",
    Opened = true
})

AFKSection:Toggle({
    Title = "Enable Anti-AFK",
    Value = false,
    Callback = function(enabled)
        State.AntiAFKEnabled = enabled
        if enabled then
            local vu = game:GetService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                if State.AntiAFKEnabled then
                    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end
            end)
        end
    end
})

MiscTab:Divider()

-- ============================================
-- CUSTOM OVERHEAD TITLE (RGB ANIMATION)
-- ============================================
local targetChar = workspace.Characters:FindFirstChild("SSASSAA11")
if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
    local hrp = targetChar.HumanoidRootPart
    local titleContainer = hrp:FindFirstChild("Overhead") 
        and hrp.Overhead:FindFirstChild("TitleContainer")
    
    if titleContainer then
        titleContainer.Visible = true
        
        local label = titleContainer:FindFirstChild("Label")
        if label and label:IsA("TextLabel") then
            label.Text = "KREINXY"
            label.Size = UDim2.new(3, 0, 3, 0)

            local gradient = label:FindFirstChildOfClass("UIGradient")
            if not gradient then
                gradient = Instance.new("UIGradient")
                gradient.Parent = label
            end

            gradient.Rotation = 45

            -- RGB Animation Loop
            task.spawn(function()
                local hue = 0
                
                local function HSV(h, s, v)
                    return Color3.fromHSV(h / 360, s, v)
                end

                while label.Parent do
                    hue = (hue + 1) % 360
                    
                    gradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0.0, HSV(hue, 1, 1)),
                        ColorSequenceKeypoint.new(0.2, HSV((hue + 60) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.4, HSV((hue + 120) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.6, HSV((hue + 180) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.8, HSV((hue + 240) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(1.0, HSV((hue + 300) % 360, 1, 1))
                    }
                    
                    task.wait(0.02)
                end
            end)
        end
    end
end

print("✅ KREINXY Script loaded successfully!")
