--====================================
-- LOAD RAYFIELD
--====================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "Blatant Script",
    LoadingTitle = "Loading Blatant...",
    LoadingSubtitle = "by Alif",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BlatantConfigs",
        FileName = "Config"
    },
    Discord = { Enabled = false },
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

--====================================
-- REMOTES
--====================================
local RF_Charge   = Net:WaitForChild("RF/ChargeFishingRod")
local RF_Request  = Net:WaitForChild("RF/RequestFishingMinigameStarted")
local RF_Cancel   = Net:WaitForChild("RF/CancelFishingInputs")
local RE_Complete = Net:WaitForChild("RE/FishingCompleted")
local RF_SellAll  = Net:WaitForChild("RF/SellAllItems")

--====================================
-- STATE
--====================================
local running = false
local CompleteDelay = 2
local CancelDelay = 2
local lastStep123 = 0
local lastStep4 = 0
local phase = "STEP123"

--====================================
-- FORCE FUNCTIONS
--====================================
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

--====================================
-- LOOP BLATANT
--====================================
task.spawn(function()
    while true do
        task.wait(0.03)
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
local BlatantTab = Window:CreateTab("Blatant")

BlatantTab:CreateToggle({
    Name = "Blatant On/Off",
    CurrentValue = false,
    Flag = "BlatantToggle",
    Callback = function(value)
        running = value
        if not value then ForceCancel() end
    end
})

BlatantTab:CreateInput({
    Name = "Complete Delay",
    PlaceholderText = "Seconds",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num then CompleteDelay = math.max(0,num) end
    end
})

BlatantTab:CreateInput({
    Name = "Cancel Delay",
    PlaceholderText = "Seconds",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local num = tonumber(text)
        if num then CancelDelay = math.max(0,num) end
    end
})

BlatantTab:CreateButton({
    Name = "Sell All",
    Callback = function()
        pcall(function()
            RF_SellAll:InvokeServer()
        end)
    end
})

--====================================
-- TAB: TELEPORT
--====================================
local TeleportTab = Window:CreateTab("Teleport")

-- Daftar lokasi teleport
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

-- Pilihan teleport default
local selectedTeleport = "Fisherman Island"

-- Dropdown untuk memilih lokasi
TeleportTab:CreateDropdown({
    Name = "Select Location",
    Options = {
        "Fisherman Island","Jungle","Ancient Ruin","Crater Island",
        "Christmas Island","Christmas Cafe","Kohana","Volcano",
        "Esetoric Depth","Sisyphus Statue","Treasure","Tropical"
    },
    CurrentOption = selectedTeleport,
    Flag = "TeleportDrop",
    Callback = function(option)
        selectedTeleport = option
    end
})

-- Tombol teleport
TeleportTab:CreateButton({
    Name = "Teleport",
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
local MiscTab = Window:CreateTab("Misc")

MiscTab:CreateButton({
    Name = "Boost FPS (Aggressive)",
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
        print("âš¡ Aggressive FPS Boost Applied!")
    end
})

-- Toggle Hide Notifications
MiscTab:CreateToggle({
    Name = "Hide Notifications",
    CurrentValue = false,
    Flag = "HideNotif",
    Callback = function(value)
        local notif = LocalPlayer.PlayerGui:FindFirstChild("Small Notification")
        if notif and notif:FindFirstChild("Display") then
            notif.Display.Visible = not value
        end
    end
})

-- Toggle No Fishing Animations
MiscTab:CreateToggle({
    Name = "No Fishing Animations",
    CurrentValue = false,
    Flag = "NoFishingAnim",
    Callback = function(value)
        -- Matikan semua AnimationTracks dari Rod/Character
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            for _, anim in pairs(LocalPlayer.Character.Humanoid:GetPlayingAnimationTracks()) do
                if value then
                    anim:Stop()
                else
                    anim:Play()
                end
            end
        end
    end
})

print("ðŸ”¥ Blatant Script Loaded with Rayfield UI + Teleport")
