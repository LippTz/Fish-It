--====================================
-- LOAD WINDUI
--====================================
local WindUI = loadstring(game:HttpGet(
    "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
))()

local Window = WindUI:CreateWindow({
    Title = "KREINXY|First It",
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

--====================================
-- SERVICES
--====================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

--====================================
-- REMOTES
--====================================
local RF_Charge   = Net:WaitForChild("RF/ChargeFishingRod")
local RF_Request  = Net:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_Cancel   = Net:WaitForChild("RF/CancelFishingInputs")
local RE_Complete = Net:WaitForChild("RE/FishingCompleted")
local RF_SellAll  = Net:WaitForChild("RF/SellAllItems")
local RF_Weather  = Net:WaitForChild("RF/PurchaseWeatherEvent")

--====================================
-- TAB: BLATANT
--====================================
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

--====================================
-- STATE & SETTINGS
--====================================
local running = false
local CompleteDelay = 0.71
local CancelDelay = 0.32
local phase = "STEP123"
local lastStepTime = 0
local loopThread

--====================================
-- FORCE FUNCTIONS
--====================================
local function ForceStep123()
    task.spawn(function()
        pcall(function()
            RF_Cancel:InvokeServer()        
            RF_Charge:InvokeServer({ [1] = os.clock() })
            RF_Request:InvokeServer(os.clock(), os.clock(), os.clock())
        end)
    end)
end

local function ForceStep4()
    task.spawn(function()
        pcall(function()
            RE_Complete:FireServer()        
            RE_Complete:FireServer()                    
        end)
    end)
end

local function ForceCancel()
    task.spawn(function()
        pcall(function()
            RE_Complete:FireServer()        
            RF_Cancel:InvokeServer()
            RF_Cancel:InvokeServer()        
        end)
    end)
end

--====================================
-- LOOP SYSTEM (IMPROVED)
--====================================
local function StartLoop()
    if loopThread then task.cancel(loopThread) end

    phase = "INIT23"
    lastStepTime = os.clock()

    loopThread = task.spawn(function()
        while running do
            task.wait(0)
            local now = os.clock()

            if (now - lastStepTime) > 3 then
                phase = "STEP123"
            end

            if phase == "INIT23" then
                lastStepTime = now
                ForceStep123()
                phase = "WAIT_COMPLETE"

            elseif phase == "STEP123" then
                lastStepTime = now
                ForceStep123()
                phase = "WAIT_COMPLETE"

            elseif phase == "WAIT_COMPLETE" then
                if (now - lastStepTime) >= CompleteDelay then
                    phase = "STEP4"
                end

            elseif phase == "STEP4" then
                lastStepTime = now
                ForceStep4()
                phase = "WAIT_STOP"

            elseif phase == "WAIT_STOP" then
                if (now - lastStepTime) >= CancelDelay then
                    phase = "STEP123"
                end
            end
        end
    end)
end

--====================================
-- UI CONTROLS
--====================================
BlatantMain:Toggle({
    Title = "Blatant Fishing",
    Value = false,
    Callback = function(v)
        running = v
        if v then
            StartLoop()
        else
            ForceCancel()
            task.wait(0.5)
            ForceCancel()
            ForceCancel()
            task.wait(1)
            ForceCancel()    
        end
    end
})

BlatantMain:Input({
    Title = "Complete Delay",
    Desc = "Delay before Step 4",
    Value = tostring(CompleteDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n then CompleteDelay = math.max(0, n) end
    end
})

BlatantMain:Input({
    Title = "Cancel Delay",
    Desc = "Delay before restart",
    Value = tostring(CancelDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n then CancelDelay = math.max(0, n) end
    end
})

BlatantTab:Divider()

local BlatantUtil = BlatantTab:Section({
    Title = "Utility",
    Opened = true
})

BlatantUtil:Button({
    Title = "Sell All Items",
    Callback = function()
        pcall(function()
            RF_SellAll:InvokeServer()
        end)
    end
})

BlatantTab:Divider()

--====================================
-- TAB: TELEPORT
--====================================
local TeleportTab = Window:Tab({
    Title = "Teleport",
    Icon = "map"
})

TeleportTab:Paragraph({
    Title = "Teleport System",
    Desc = "Location, Player & Event teleport"
})

TeleportTab:Divider()

-- LOCATION
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

local SelectedLocation = "Fisherman Island"

LocationSection:Dropdown({
    Title = "Select Location",
    Values = (function()
        local t = {}
        for k in pairs(Locations) do table.insert(t, k) end
        return t
    end)(),
    Value = SelectedLocation,
    Callback = function(v)
        SelectedLocation = v
    end
})

LocationSection:Button({
    Title = "Teleport",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char.PrimaryPart then
            char:SetPrimaryPartCFrame(Locations[SelectedLocation])
        end
    end
})

TeleportTab:Divider()

-- PLAYER TELEPORT
local PlayerSection = TeleportTab:Section({
    Title = "Player Teleport",
    Opened = true
})

local SelectedPlayer

local function GetPlayerList()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    table.sort(t)
    return t
end

local PlayerDropdown = PlayerSection:Dropdown({
    Title = "Select Player",
    Values = GetPlayerList(),
    Callback = function(v)
        SelectedPlayer = v
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
        if not SelectedPlayer then return end
        local target = Players:FindFirstChild(SelectedPlayer)
        if target and target.Character and target.Character.PrimaryPart then
            LocalPlayer.Character:SetPrimaryPartCFrame(
                target.Character.PrimaryPart.CFrame * CFrame.new(0,1,0)
            )
        end
    end
})

TeleportTab:Divider()

--====================================
-- EVENT TELEPORT (ONE-TIME SYSTEM)
--====================================
local EventSection = TeleportTab:Section({
    Title = "Event Teleport",
    Opened = true
})

-- EVENT LIST
local EventNames = {
    "Megalodon Hunt",
    "Shark Hunt",
    "Ghost Shark Hunt",
}

local SelectedEvents = {}
local EventTeleportEnabled = false
local SavedCFrame = nil
local TeleportedToEvent = false

-- UI: DROPDOWN EVENT (MULTI)
EventSection:Dropdown({
    Title = "Select Event",
    Desc = "Teleport once when event appears",
    Values = EventNames,
    Multi = true,
    Callback = function(v)
        SelectedEvents = v
    end
})

-- UI: TOGGLE
EventSection:Toggle({
    Title = "Enable Event Teleport",
    Desc = "Auto teleport once & return after event ends",
    Value = false,
    Callback = function(v)
        EventTeleportEnabled = v

        -- kalau dimatikan manual → langsung balik
        if not v and TeleportedToEvent and SavedCFrame then
            pcall(function()
                LocalPlayer.Character:SetPrimaryPartCFrame(SavedCFrame)
            end)
            SavedCFrame = nil
            TeleportedToEvent = false
        end
    end
})

EventSection:Divider()

EventSection:Paragraph({
    Title = "Info",
    Desc = "• Teleport hanya 1x saat event muncul\n• Posisi disimpan otomatis\n• Akan kembali saat event selesai atau toggle OFF"
})

--====================================
-- EVENT CF FINDER (AMAN SEMUA STRUKTUR)
--====================================
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

    for _, v in ipairs(event:GetDescendants()) do
        if v:IsA("BasePart") then
            return v.CFrame
        end
    end
end

--====================================
-- MONITOR EVENT (BUKAN LOOP TELEPORT)
--====================================
task.spawn(function()
    while task.wait(1) do
        if not EventTeleportEnabled then continue end
        if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then continue end

        local foundEvent = false

        for _, eventName in ipairs(SelectedEvents) do
            local cf = GetEventCFrame(eventName)

            if cf then
                foundEvent = true

                if not TeleportedToEvent then
                    SavedCFrame = LocalPlayer.Character.PrimaryPart.CFrame
                    LocalPlayer.Character:SetPrimaryPartCFrame(cf)
                    TeleportedToEvent = true
                end

                break
            end
        end

        -- event sudah hilang → balik ke posisi awal
        if TeleportedToEvent and not foundEvent then
            if SavedCFrame then
                LocalPlayer.Character:SetPrimaryPartCFrame(SavedCFrame)
            end
            SavedCFrame = nil
            TeleportedToEvent = false
        end
    end
end)

TeleportTab:Divider()

--====================================
-- TAB: SHOP
--====================================
local ShopTab = Window:Tab({
    Title = "Shop",
    Icon = "shopping-cart"
})

local ShopSection = ShopTab:Section({
    Title = "Weather Shop",
    Opened = true
})

local WeatherList = {
    "Wind","Storm","Cloudy","Snow","Radiant","Shark Hunt"
}

local SelectedWeathers = {}
local WeatherSpam = false

ShopSection:Dropdown({
    Title = "Select Weather",
    Values = WeatherList,
    Multi = true,
    Callback = function(v)
        SelectedWeathers = v
    end
})

ShopSection:Toggle({
    Title = "Auto Buy Weather",
    Value = false,
    Callback = function(v)
        WeatherSpam = v
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if not WeatherSpam then continue end
        for _, w in ipairs(SelectedWeathers) do
            pcall(function()
                RF_Weather:InvokeServer(w)
            end)
            task.wait(0.8)
        end
    end
end)

ShopTab:Divider()

--====================================
-- TAB: MISC
--====================================
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
        local Lighting = game:GetService("Lighting")
        
        -- MATIKAN SHADOW & PANTULAN
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0
        Lighting.Brightness = 5

        -- KABUT JEBLOCK (SUPER TEBAL)
        Lighting.FogStart = 0
        Lighting.FogEnd = 100
        Lighting.FogColor = Color3.fromRGB(255, 5, 5)

        -- NONAKTIF POST EFFECT
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end

        -- HAPUS TEXTURE / DECAL / PARTICLE
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

        -- NONAKTIF RUMPUT & AIR
        if workspace:FindFirstChildOfClass("Terrain") then
            local Terrain = workspace.Terrain
            Terrain:SetMaterialColor(Enum.Material.Grass, Color3.new(0,0,0))
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
        end
        
        -- BOOST CAMERA FOV (opsional)
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
        local f = workspace:FindFirstChild("CosmeticFolder")
        if f then f:Destroy() end
    end
})

--====================================
-- NO ANIMATIONS (STRONG VERSION)
--====================================
local NoAnimationEnabled = false
local AnimConnection

local function ApplyNoAnimation(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator", humanoid)
    end

    -- stop semua animasi aktif
    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end

    -- hook animasi baru
    if AnimConnection then AnimConnection:Disconnect() end
    AnimConnection = animator.AnimationPlayed:Connect(function(track)
        track:Stop()
    end)
end

MiscSection:Toggle({
    Title = "No Animations",
    Desc = "Disable all character animations (persistent)",
    Value = false,
    Callback = function(v)
        NoAnimationEnabled = v

        if v then
            if LocalPlayer.Character then
                ApplyNoAnimation(LocalPlayer.Character)
            end
        else
            if AnimConnection then
                AnimConnection:Disconnect()
                AnimConnection = nil
            end
        end
    end
})

-- auto re-apply after respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if NoAnimationEnabled then
        task.wait(1)
        ApplyNoAnimation(char)
    end
end)

--====================================
-- NO NOTIFICATION (VISIBLE BASED)
--====================================
local NoNotificationEnabled = false
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function ApplyNoNotification()
    local gui = PlayerGui:FindFirstChild("Small Notification")
    if not gui then return end

    local display = gui:FindFirstChild("Display")
    if not display then return end

    display.Visible = not NoNotificationEnabled
end

MiscSection:Toggle({
    Title = "No Notifications",
    Desc = "Hide small notification popup",
    Value = false,
    Callback = function(v)
        NoNotificationEnabled = v
        ApplyNoNotification()
    end
})

-- 🔁 auto re-apply jika GUI dibuat ulang
PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "Small Notification" then
        task.wait(0.2)
        ApplyNoNotification()
    end
end)

MiscTab:Divider()

--====================================
-- HUD FPS + PING
--====================================
local HUD_Enabled = false
local HUDGui, HUDLabel

local HUDSection = MiscTab:Section({
    Title = "HUD Monitor",
    Opened = true
})

HUDSection:Toggle({
    Title = "Show FPS & Ping HUD",
    Value = false,
    Callback = function(v)
        HUD_Enabled = v

        if v then
            -- Create HUD if missing
            if not HUDGui then
                HUDGui = Instance.new("ScreenGui")
                HUDGui.Name = "HUD_FPSPING"
                HUDGui.ResetOnSpawn = false
                HUDGui.Parent = game:GetService("CoreGui")

                HUDLabel = Instance.new("TextLabel")
                HUDLabel.Name = "Display"
                HUDLabel.Parent = HUDGui
                HUDLabel.Size = UDim2.new(0, 200, 0, 38)
                HUDLabel.Position = UDim2.new(1, -200, 0, 8)
                HUDLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                HUDLabel.BackgroundTransparency = 0.45
                HUDLabel.BorderSizePixel = 0
                HUDLabel.TextColor3 = Color3.fromRGB(0,255,125)
                HUDLabel.Font = Enum.Font.Code
                HUDLabel.TextSize = 15
                HUDLabel.Text = "FPS: --  |  Ping: --"

                -- Make draggable
                local UserInput = game:GetService("UserInputService")
                local dragging, dragStart, startPos

                HUDLabel.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        dragStart = input.Position
                        startPos = HUDLabel.Position
                    end
                end)

                UserInput.InputChanged:Connect(function(input)
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
            if HUDGui then HUDGui.Enabled = false end
        end
    end
})

-- LOOP UPDATE FPS & PING
task.spawn(function()
    while true do
        task.wait(0.5)
        if HUD_Enabled and HUDGui and HUDLabel then
            local stats = game:GetService("Stats")
            local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
            local ping = stats.Network.ServerStatsItem["Data Ping"]:GetValue()
            HUDLabel.Text = ("FPS: %s  |  Ping: %sms"):format(fps, math.floor(ping))
        end
    end
end)

MiscTab:Divider()

--====================================
-- ANTI AFK
--====================================
local AntiAFK_Enabled = false

local AFKSection = MiscTab:Section({
    Title = "Anti-AFK",
    Opened = true
})

AFKSection:Toggle({
    Title = "Enable Anti-AFK",
    Value = false,
    Callback = function(v)
        AntiAFK_Enabled = v
        if v then
            local vu = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                if AntiAFK_Enabled then
                    vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                end
            end)
        end
    end
})

MiscTab:Divider()


--Table Atas kepala
local targetChar = workspace.Characters:FindFirstChild("SSASSAA11")
if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
    local hrp = targetChar.HumanoidRootPart
    local titleContainer = hrp:FindFirstChild("Overhead") and hrp.Overhead:FindFirstChild("TitleContainer")
    
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

            -- LOOP RGB
            task.spawn(function()
                local hue = 0
                while label.Parent do
                    hue = (hue + 1) % 360
                    local function HSV(h, s, v)
                        return Color3.fromHSV(h/360, s, v)
                    end

                    gradient.Color = ColorSequence.new{
                        ColorSequenceKeypoint.new(0, HSV((hue) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.2, HSV((hue + 60) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.4, HSV((hue + 120) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.6, HSV((hue + 180) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(0.8, HSV((hue + 240) % 360, 1, 1)),
                        ColorSequenceKeypoint.new(1, HSV((hue + 300) % 360, 1, 1))
                    }
                    task.wait(0.02) -- update tiap 0.05 detik
                end
            end)
        end
    end
end
