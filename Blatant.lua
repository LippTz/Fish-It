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
    KeySystem = false,
    -- TOGGLE GUI KEYBIND
    Key = Enum.KeyCode.LeftAlt
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
local RF_Complete = Net:WaitForChild("RF/CatchFishCompleted")
local RF_SellAll  = Net:WaitForChild("RF/SellAllItems")
local RF_Weather  = Net:WaitForChild("RF/PurchaseWeatherEvent")

--====================================
-- TAB: AUTO FARM
--====================================
local FarmTab = Window:Tab({
    Title = "Auto Farm",
    Icon = "zap"
})

FarmTab:Paragraph({
    Title = "Auto Fishing System",
    Desc = "Instant remote execution - testing speed.\nSafe stop system included."
})

FarmTab:Divider()

local FarmMain = FarmTab:Section({
    Title = "Main Control",
    Opened = true
})

--====================================
-- STATE & SETTINGS
--====================================
local AutoFishEnabled = false
local CompleteDelay = 0.4
local loopThread
local shouldStop = false
local hasCasted = false

--====================================
-- INSTANT REMOTE EXECUTION
--====================================
local function StartAutoFish()
    if loopThread then
        task.cancel(loopThread)
        loopThread = nil
    end

    shouldStop = false
    hasCasted = false

    loopThread = task.spawn(function()
        while AutoFishEnabled and not shouldStop do
            -- STEP 1-2: Cast fishing rod (INSTANT - NO DELAY)
            hasCasted = true
            pcall(function()
                local t = os.clock()
                RF_Charge:InvokeServer({[4] = t})
                RF_Charge:InvokeServer({[4] = t})
                RF_Request:InvokeServer(t, t, t)
            end)
            
            -- Wait for complete delay
            task.wait(CompleteDelay)
            
            -- Check stop request
            if shouldStop then
                print("[Auto Fish] Stop requested, will finish this cycle first...")
            end
            
            -- STEP 3: Complete fishing (INSTANT)
            pcall(function()
                RF_Complete:InvokeServer()
            end)
            
            hasCasted = false
            
            -- Check after complete
            if shouldStop then
                print("[Auto Fish] Cycle complete, stopping now...")
                break
            end
        end
        
        print("[Auto Fish] Loop ended")
    end)
end

--====================================
-- UI CONTROLS
--====================================
FarmMain:Toggle({
    Title = "Auto Fishing",
    Desc = "Instant remote execution",
    Value = false,
    Callback = function(v)
        AutoFishEnabled = v
        
        if v then
            print("[Auto Fish] Starting...")
            print("[Auto Fish] Complete Delay:", CompleteDelay, "seconds")
            shouldStop = false
            hasCasted = false
            StartAutoFish()
        else
            print("[Auto Fish] Stop requested...")
            shouldStop = true
            AutoFishEnabled = false
            
            task.spawn(function()
                local waitTime = 0
                while hasCasted and waitTime < 5 do
                    task.wait(0.01)
                    waitTime = waitTime + 0.01
                end
                
                if loopThread then
                    task.cancel(loopThread)
                    loopThread = nil
                end
                
                task.wait(0.1)
                pcall(function()
                    RF_Cancel:InvokeServer({[1] = true})
                end)
                
                shouldStop = false
                hasCasted = false
                
                print("[Auto Fish] Stopped safely!")
            end)
        end
    end
})

FarmMain:Input({
    Title = "Complete Delay",
    Desc = "Delay sebelum complete (detik)",
    Value = tostring(CompleteDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 0 then
            CompleteDelay = n
            print("[Settings] Complete Delay set to:", CompleteDelay, "seconds")
        end
    end
})

FarmTab:Divider()

local FarmInfo = FarmTab:Section({
    Title = "How It Works",
    Opened = true
})

FarmInfo:Paragraph({
    Title = "Speed Test Mode",
    Desc = "• All remotes execute INSTANTLY\n• No delay between remote calls\n• Only delay: wait for fish to be catchable\n• Safe stop: waits for current cycle\n\nPress RIGHT CTRL to toggle GUI!"
})

FarmTab:Divider()

local FarmUtil = FarmTab:Section({
    Title = "Utility",
    Opened = true
})

FarmUtil:Button({
    Title = "Sell All Items",
    Callback = function()
        pcall(function()
            RF_SellAll:InvokeServer()
            print("[Utility] Sold all items!")
        end)
    end
})

FarmUtil:Button({
    Title = "Complete Current Fish",
    Callback = function()
        pcall(function()
            RF_Complete:InvokeServer()
            RF_Complete:InvokeServer()
            print("[Utility] Completed current fish!")
        end)
    end
})

FarmUtil:Button({
    Title = "Cancel Fishing",
    Callback = function()
        pcall(function()
            RF_Cancel:InvokeServer({[1] = true})
            print("[Utility] Cancelled fishing!")
        end)
    end
})

FarmTab:Divider()

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

local LocationSection = TeleportTab:Section({
    Title = "Location Teleport",
    Opened = true
})

local Locations = {
    ["Fisherman Island"] = CFrame.new(34, 28, 2776),
    ["Jungle"] = CFrame.new(1483, 13, -300),
    ["Ancient Ruin"] = CFrame.new(6085, -584, 4639),
    ["Crater Island"] = CFrame.new(1013, 25, 5079),
    ["Christmas Island"] = CFrame.new(1135, 26, 1563),
    ["Christmas Cafe"] = CFrame.new(580, -579, 8930),
    ["Coral"] = CFrame.new(-3029, 5, 2260),
    ["Kohana"] = CFrame.new(-635, 18, 603),
    ["Volcano"] = CFrame.new(-597, 65, 106),
    ["Esetoric Depth"] = CFrame.new(3203, -1301, 1415),
    ["Sisyphus Statue"] = CFrame.new(-3712, -133, -1013),
    ["Treasure"] = CFrame.new(-3566, -277, -1681),
    ["Tropical"] = CFrame.new(-2093, 8, 3699),
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
-- EVENT TELEPORT
--====================================
local EventSection = TeleportTab:Section({
    Title = "Event Teleport",
    Opened = true
})

local EventNames = {
    "Megalodon Hunt",
    "Shark Hunt",
    "Ghost Shark Hunt",
}

local SelectedEvents = {}
local EventTeleportEnabled = false
local SavedCFrame = nil
local TeleportedToEvent = false

EventSection:Dropdown({
    Title = "Select Event",
    Desc = "Teleport once when event appears",
    Values = EventNames,
    Multi = true,
    Callback = function(v)
        SelectedEvents = v
    end
})

EventSection:Toggle({
    Title = "Enable Event Teleport",
    Desc = "Auto teleport once & return after event ends",
    Value = false,
    Callback = function(v)
        EventTeleportEnabled = v

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
        
        Lighting.GlobalShadows = false
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ShadowSoftness = 0
        Lighting.Brightness = 5

        Lighting.FogStart = 0
        Lighting.FogEnd = 100
        Lighting.FogColor = Color3.fromRGB(255, 5, 5)

        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end

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

        if workspace:FindFirstChildOfClass("Terrain") then
            local Terrain = workspace.Terrain
            Terrain:SetMaterialColor(Enum.Material.Grass, Color3.new(0,0,0))
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
        end
        
        task.spawn(function()
            for i = 1, 60 do
                if LocalPlayer then
                    LocalPlayer.CameraMaxZoomDistance = 1000
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
-- NO ANIMATIONS
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

    for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
        track:Stop()
    end

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

LocalPlayer.CharacterAdded:Connect(function(char)
    if NoAnimationEnabled then
        task.wait(1)
        ApplyNoAnimation(char)
    end
end)

--====================================
-- NO NOTIFICATION
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

--====================================
-- TAB: SETTINGS
--====================================
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "sliders"
})

local UISection = SettingsTab:Section({
    Title = "UI Settings",
    Opened = true
})

UISection:Paragraph({
    Title = "Toggle GUI Keybind",
    Desc = "Press RIGHT CTRL to show/hide GUI\n\nYou can change the keybind below."
})

UISection:Keybind({
    Title = "Toggle GUI Key",
    Default = Enum.KeyCode.RightControl,
    Callback = function(key)
        -- WindUI akan otomatis update keybind
        print("[Settings] GUI toggle key changed to:", key.Name)
    end
})

SettingsTab:Divider()

--====================================
-- OVERHEAD TABLE
--====================================
task.spawn(function()
    task.wait(2)
    pcall(function()
        local targetChar = workspace.Characters:FindFirstChild(LocalPlayer.Name)
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
                            task.wait(0.02)
                        end
                    end)
                end
            end
        end
    end)
end)

print("========================================")
print("[KREINXY] Script loaded successfully!")
print("[INFO] Press RIGHT CTRL to toggle GUI")
print("[INFO] All features ready to use")
print("========================================")