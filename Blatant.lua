--====================================
-- LOAD WINDUI
--====================================
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Blatant Script",
    Icon = "door-open",
    Author = "by Alif",
    Folder = "BlatantScript",
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    KeySystem = false
})

--====================================
-- SERVICES
--====================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")

-- REMOTES
local RF_Charge   = Net:WaitForChild("RF/ChargeFishingRod")
local RF_Request  = Net:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_Cancel   = Net:WaitForChild("RF/CancelFishingInputs")
local RE_Complete = Net:WaitForChild("RE/FishingCompleted")
local RF_SellAll  = Net:WaitForChild("RF/SellAllItems")

-- STATE
local running = false
local CompleteDelay = 1.33
local CancelDelay = 0.32
local lastStep123 = 0
local lastStep4 = 0
local phase = "STEP123"

-- FORCE FUNCTIONS
local function ForceStep123()
    task.spawn(function()
        pcall(function()
            RF_Cancel:InvokeServer()
            RF_Charge:InvokeServer({ [1] = { os.clock() } })
            RF_Request:InvokeServer(1, 0, os.clock())
        end)
    end)
end

local function ForceStep4()
    task.spawn(function()
        pcall(function()
            RE_Complete:FireServer()
        end)
    end)
end

local function ForceCancel()
    task.spawn(function()
        pcall(function()
            RF_Cancel:InvokeServer()
        end)
    end)
end

-- LOOP BLATANT
task.spawn(function()
    while true do
        task.wait(0.001)
        if not running then continue end
        local now = os.clock()
        if phase == "STEP123" then
            ForceStep123()
            lastStep123 = now
            phase = "WAIT_COMPLETE"
        end
        if phase == "WAIT_COMPLETE" and (now - lastStep123) >= CompleteDelay then
            phase = "STEP4"
        end
        if phase == "STEP4" then
            ForceStep4()
            lastStep4 = now
            phase = "WAIT_CANCEL"
        end
        if phase == "WAIT_CANCEL" and (now - lastStep4) >= CancelDelay then
            phase = "STEP123"
        end
    end
end)

--====================================
-- TAB: BLATANT
--====================================
local BlatantTab = Window:Tab({Title = "Blatant", Icon = "fish"})

-- Toggle On/Off
BlatantTab:Toggle({
    Title = "Blatant On/Off",
    Desc = "Enable/Disable blatant fishing",
    Value = false,
    Callback = function(state)
        running = state
        if not state then ForceCancel() end
    end
})

-- Input Complete Delay
BlatantTab:Input({
    Title = "Complete Delay",
    Desc = "Delay in seconds for STEP123 -> STEP4",
    Value = tostring(CompleteDelay),
    Placeholder = "Seconds",
    Callback = function(text)
        local num = tonumber(text)
        if num then CompleteDelay = math.max(0,num) end
    end
})

-- Input Cancel Delay
BlatantTab:Input({
    Title = "Cancel Delay",
    Desc = "Delay in seconds for STEP4 -> STEP123",
    Value = tostring(CancelDelay),
    Placeholder = "Seconds",
    Callback = function(text)
        local num = tonumber(text)
        if num then CancelDelay = math.max(0,num) end
    end
})

-- Button Sell All
BlatantTab:Button({
    Title = "Sell All",
    Callback = function()
        pcall(function()
            RF_SellAll:InvokeServer()
        end)
    end
})

--====================================
-- TAB: TELEPORT
--====================================
local TeleportTab = Window:Tab({Title = "Teleport", Icon = "map"})

local teleportLocations = {
    ["Fisherman Island"] = CFrame.new(34, 26, 2776),
    ["Jungle"] = CFrame.new(1483, 11, -300),
    ["Ancient Ruin"] = CFrame.new(6085, -586, 4639),
    ["Crater Island"] = CFrame.new(1013, 23, 5079),
    ["Christmas Island"] = CFrame.new(1135, 24, 1563),
    ["Christmas Cafe"] = CFrame.new(580, -581, 8930),
    ["Kohana"] = CFrame.new(-635, 16, 603),
    ["Volcano"] = CFrame.new(-597, 59, 106),
    ["Esetoric Depth"] = CFrame.new(3203, -1303, 1415),
    ["Sisyphus Statue"] = CFrame.new(-3712, -135, -1013),
    ["Treasure"] = CFrame.new(-3566, -279, -1681),
    ["Tropical"] = CFrame.new(-2093, 6, 3699),
}

local selectedTeleport = "Fisherman Island"

-- Dropdown Lokasi
TeleportTab:Dropdown({
    Title = "Select Location",
    Desc = "Choose a location to teleport",
    Values = (function()
        local t = {}
        for k,_ in pairs(teleportLocations) do table.insert(t,k) end
        return t
    end)(),
    Value = selectedTeleport,
    Callback = function(option)
        selectedTeleport = option
    end
})

-- Button Teleport
TeleportTab:Button({
    Title = "Teleport",
    Callback = function()
        local targetCFrame = teleportLocations[selectedTeleport]
        if targetCFrame and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
            LocalPlayer.Character:SetPrimaryPartCFrame(targetCFrame)
        end
    end
})

--====================================
-- TAB: MISC
--====================================
local MiscTab = Window:Tab({Title = "Misc", Icon = "settings"})

-- Boost FPS
MiscTab:Button({
    Title = "Boost FPS (Aggressive)",
    Callback = function()
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then effect.Enabled = false end
        end
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        Lighting.Ambient = Color3.fromRGB(128,128,128)
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Explosion") or v:IsA("Smoke") then
                v:Destroy()
            elseif v:IsA("Texture") or v:IsA("Decal") then
                v:Destroy()
            elseif v:IsA("Shirt") or v:IsA("Pants") then
                v:Destroy()
            end
        end
        if Workspace:FindFirstChild("Terrain") then
            Workspace.Terrain.WaterWaveSize = 0
            Workspace.Terrain.WaterWaveSpeed = 0
            Workspace.Terrain.WaterReflectance = 0
            Workspace.Terrain.WaterTransparency = 0
        end
        print(" Aggressive FPS Boost Applied!")
    end
})

-- Hide Notifications
MiscTab:Toggle({
    Title = "Hide Notifications",
    Desc = "Hide the small notification display",
    Value = false,
    Callback = function(state)
        local notif = LocalPlayer.PlayerGui:FindFirstChild("Small Notification")
        if notif and notif:FindFirstChild("Display") then
            notif.Display.Visible = not state
        end
    end
})

-- No Fishing Animations
MiscTab:Toggle({
    Title = "No Fishing Animations",
    Desc = "Stop fishing animations",
    Value = false,
    Callback = function(state)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            for _, anim in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do
                if state then anim:Stop() else anim:Play() end
            end
        end
    end
})

print(" Blatant Script Loaded with WindUI!")
