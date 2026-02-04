--==================================================
-- SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

pcall(function()
	game.CoreGui.FinalAimlockGUI:Destroy()
	game.CoreGui.AimlockToggleButton:Destroy()
end)

--==================================================
-- SETTINGS
--==================================================
local CFG = {
	Aimlock = false,
	ESP = false,
	Skeleton = false,
	Highlight = false,
	TeamCheck = false,
	WallCheck = false,
	FOVEnabled = false,
	FOVRadius = 120,
	Smooth = 25,
	Target = "Head",
	HeadOffset = Vector3.new(0, 0.15, 0),
	Prediction = false,
	PredictionAmount = 0.005,
	AutoFire = false,
	DynamicFOV = false,
	LockedFOV = 50,
	ScriptEnabled = true,
	
	-- Colors
	FOVColor = Color3.fromRGB(0, 255, 170),
	ESPColor = Color3.fromRGB(255, 0, 0),
	ESPTeamColor = Color3.fromRGB(0, 255, 0),
	SkeletonColor = Color3.fromRGB(255, 255, 255),
	HighlightColor = Color3.fromRGB(255, 0, 255),
	
	-- RGB
	RGBEnabled = false,
	FPSBoost = false,
	
	-- ESP Display Options
	ShowName = true,
	ShowDistance = true,
	ShowHealth = true,
	ShowTargetInfo = true,
	
	-- Keybinds
	Keybinds = {
		ToggleAimlock = Enum.KeyCode.E,
		ToggleESP = Enum.KeyCode.T,
		ToggleFOV = Enum.KeyCode.Y,
		ToggleGUI = Enum.KeyCode.LeftAlt,
		ToggleSkeleton = Enum.KeyCode.L,
		ToggleHighlight = Enum.KeyCode.K,
		ToggleWallCheck = Enum.KeyCode.Z,
		ToggleTeamCheck = Enum.KeyCode.V,
		ToggleAutoFire = Enum.KeyCode.X,
		CycleTarget = Enum.KeyCode.C
	}
}

local LockedTarget = nil
local ESPObjects = {}

--==================================================
-- DEVICE DETECTION
--==================================================
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
local isTablet = UserInputService.TouchEnabled and UserInputService.MouseEnabled

--==================================================
-- NOTIFICATION SYSTEM
--==================================================
local function Notify(title, message, duration, soundEnabled)
	pcall(function()
		local NotifGui = Instance.new("ScreenGui")
		NotifGui.Name = "NotificationGui"
		NotifGui.ResetOnSpawn = false
		NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		NotifGui.Parent = game.CoreGui
		
		local NotifFrame = Instance.new("Frame")
		NotifFrame.Size = UDim2.fromOffset(300, 80)
		NotifFrame.Position = UDim2.new(1, -320, 0, 20)
		NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		NotifFrame.BorderSizePixel = 0
		NotifFrame.Parent = NotifGui
		
		Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 10)
		
		local NotifStroke = Instance.new("UIStroke", NotifFrame)
		NotifStroke.Color = Color3.fromRGB(0, 255, 170)
		NotifStroke.Thickness = 1.5
		
		local TitleLabel = Instance.new("TextLabel", NotifFrame)
		TitleLabel.Size = UDim2.new(1, -20, 0, 25)
		TitleLabel.Position = UDim2.fromOffset(10, 10)
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Text = title
		TitleLabel.Font = Enum.Font.GothamBold
		TitleLabel.TextSize = 14
		TitleLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
		TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
		
		local MessageLabel = Instance.new("TextLabel", NotifFrame)
		MessageLabel.Size = UDim2.new(1, -20, 0, 35)
		MessageLabel.Position = UDim2.fromOffset(10, 40)
		MessageLabel.BackgroundTransparency = 1
		MessageLabel.Text = message
		MessageLabel.Font = Enum.Font.Gotham
		MessageLabel.TextSize = 12
		MessageLabel.TextColor3 = Color3.new(1, 1, 1)
		MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
		MessageLabel.TextWrapped = true
		
		TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -320, 0, 20)
		}):Play()
		
		task.wait(duration or 3)
		
		TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 50, 0, 20)
		}):Play()
		
		task.wait(0.3)
		NotifGui:Destroy()
	end)
end

--==================================================
-- SOUND SYSTEM
--==================================================
local function PlaySound(soundId, volume, pitch)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. soundId
		sound.Volume = volume or 0.5
		sound.Pitch = pitch or 1
		sound.Parent = SoundService
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end)
end

local function PlayClickSound()
	PlaySound("8394620892", 0.7, 1)
end

local function PlayToggleSound()
	PlaySound("8394620892", 0.7, 1)
end

local function PlayCloseSound()
	PlaySound("8394620892", 0.7, 1)
end

--==================================================
-- FOV CIRCLE
--==================================================
local FOVCircle = nil
local FOVCreated = false

pcall(function()
	FOVCircle = Drawing.new("Circle")
	FOVCircle.Visible = false
	FOVCircle.Thickness = 1
	FOVCircle.NumSides = 64
	FOVCircle.Radius = 140
	FOVCircle.Filled = false
	FOVCircle.Transparency = 1
	FOVCircle.Color = CFG.FOVColor
	FOVCircle.Position = Vector2.new(500, 500)
	FOVCreated = true
end)

if not FOVCreated then
	local FOVGui = Instance.new("ScreenGui")
	FOVGui.Name = "FOVCircle"
	FOVGui.IgnoreGuiInset = true
	FOVGui.Parent = game.CoreGui
	
	FOVCircle = Instance.new("Frame")
	FOVCircle.Name = "Circle"
	FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	FOVCircle.BackgroundTransparency = 1
	FOVCircle.Size = UDim2.fromOffset(280, 280)
	FOVCircle.Position = UDim2.fromScale(0.5, 0.5)
	FOVCircle.Visible = false
	FOVCircle.Parent = FOVGui
	
	Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
	
	local Stroke = Instance.new("UIStroke", FOVCircle)
	Stroke.Color = CFG.FOVColor
	Stroke.Thickness = 1
	
	FOVCreated = true
end

--==================================================
-- TARGET INFO DISPLAY
--==================================================
local TargetInfoGui = Instance.new("ScreenGui")
TargetInfoGui.Name = "TargetInfo"
TargetInfoGui.ResetOnSpawn = false
TargetInfoGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
TargetInfoGui.Parent = game.CoreGui

local TargetInfoFrame = Instance.new("Frame", TargetInfoGui)
TargetInfoFrame.Size = UDim2.fromOffset(250, 80)
TargetInfoFrame.Position = UDim2.new(0.5, -125, 0.15, 0)
TargetInfoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
TargetInfoFrame.BackgroundTransparency = 0.3
TargetInfoFrame.BorderSizePixel = 0
TargetInfoFrame.Visible = false

Instance.new("UICorner", TargetInfoFrame).CornerRadius = UDim.new(0, 8)

local TargetInfoStroke = Instance.new("UIStroke", TargetInfoFrame)
TargetInfoStroke.Color = Color3.fromRGB(0, 255, 170)
TargetInfoStroke.Thickness = 2

local TargetNameLabel = Instance.new("TextLabel", TargetInfoFrame)
TargetNameLabel.Size = UDim2.new(1, -20, 0, 25)
TargetNameLabel.Position = UDim2.fromOffset(10, 5)
TargetNameLabel.BackgroundTransparency = 1
TargetNameLabel.Text = "Target: PlayerName"
TargetNameLabel.Font = Enum.Font.GothamBold
TargetNameLabel.TextSize = 14
TargetNameLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
TargetNameLabel.TextXAlignment = Enum.TextXAlignment.Left

local TargetHealthLabel = Instance.new("TextLabel", TargetInfoFrame)
TargetHealthLabel.Size = UDim2.new(1, -20, 0, 20)
TargetHealthLabel.Position = UDim2.fromOffset(10, 30)
TargetHealthLabel.BackgroundTransparency = 1
TargetHealthLabel.Text = "HP: 100/100"
TargetHealthLabel.Font = Enum.Font.Gotham
TargetHealthLabel.TextSize = 12
TargetHealthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
TargetHealthLabel.TextXAlignment = Enum.TextXAlignment.Left

local TargetDistanceLabel = Instance.new("TextLabel", TargetInfoFrame)
TargetDistanceLabel.Size = UDim2.new(1, -20, 0, 20)
TargetDistanceLabel.Position = UDim2.fromOffset(10, 52)
TargetDistanceLabel.BackgroundTransparency = 1
TargetDistanceLabel.Text = "Distance: 50m"
TargetDistanceLabel.Font = Enum.Font.Gotham
TargetDistanceLabel.TextSize = 12
TargetDistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left

--==================================================
-- LOCK INDICATOR
--==================================================
local LockIndicator = Drawing.new("Circle")
LockIndicator.Visible = false
LockIndicator.Thickness = 3
LockIndicator.NumSides = 32
LockIndicator.Radius = 30
LockIndicator.Filled = false
LockIndicator.Transparency = 1
LockIndicator.Color = Color3.fromRGB(255, 0, 0)

--==================================================
-- TOGGLE BUTTON GUI (FIX - CREATE BEFORE USING)
--==================================================
local ToggleButtonGui = Instance.new("ScreenGui")
ToggleButtonGui.Name = "AimlockToggleButton"
ToggleButtonGui.ResetOnSpawn = false
ToggleButtonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleButtonGui.Parent = game.CoreGui

--==================================================
-- TOGGLE BUTTON (FLOATING)
--==================================================
local ToggleButton = Instance.new("TextButton", ToggleButtonGui)
if isMobile then
	ToggleButton.Size = UDim2.fromOffset(50, 50)
else
	ToggleButton.Size = UDim2.fromOffset(45, 45)
end
ToggleButton.Position = UDim2.new(0, 15, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
ToggleButton.BackgroundTransparency = 0.15
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "◎"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextSize = 24
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Active = true
ToggleButton.Draggable = true

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local ToggleStroke = Instance.new("UIStroke", ToggleButton)
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Transparency = 0.7

-- Pulse animation
task.spawn(function()
	while task.wait(1) do
		TweenService:Create(ToggleStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.3
		}):Play()
		task.wait(0.8)
		TweenService:Create(ToggleStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.7
		}):Play()
	end
end)

--==================================================
-- MAIN GUI (RESPONSIVE)
--==================================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "FinalAimlockGUI"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Enabled = true
GUI.Parent = game.CoreGui

local Main = Instance.new("Frame", GUI)

if isMobile then
	Main.Size = UDim2.new(0.45, 0, 0.75, 0)
	Main.Position = UDim2.new(0.025, 0, 0.1, 0)
elseif isTablet then
	Main.Size = UDim2.new(0.7, 0, 0.75, 0)
	Main.Position = UDim2.new(0.15, 0, 0.125, 0)
else
	Main.Size = UDim2.fromOffset(480, 540)
	Main.Position = UDim2.new(0.5, -240, 0.5, -270)
end

Main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
Main.BackgroundTransparency = 0.15
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true

-- Make draggable for PC only
if not isMobile then
	Main.Draggable = true
else
	Main.Draggable = false
	local dragging = false
	local dragStart = nil
	local startPos = nil
	
	Main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end)
	
	Main.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

-- ANIMATED RAINBOW BORDER
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(100, 100, 255)
MainStroke.Thickness = 2
MainStroke.Transparency = 0

-- Border animation (rainbow)
task.spawn(function()
	local hue = 0
	while task.wait(0.05) do
		hue = (hue + 0.01) % 1
		MainStroke.Color = Color3.fromHSV(hue, 0.6, 1)
	end
end)

-- BLUR BACKGROUND (Glassmorphism effect)
local Blur = Instance.new("ImageLabel", Main)
Blur.Size = UDim2.fromScale(1, 1)
Blur.Position = UDim2.fromScale(0, 0)
Blur.BackgroundTransparency = 1
Blur.Image = "rbxassetid://8992230677"
Blur.ImageColor3 = Color3.fromRGB(12, 12, 15)
Blur.ImageTransparency = 0.3
Blur.ScaleType = Enum.ScaleType.Slice
Blur.SliceCenter = Rect.new(100, 100, 100, 100)
Blur.ZIndex = 0

--==================================================
-- HEADER (MINIMALIST)
--==================================================
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0, isMobile and 50 or 45)
Header.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Header.BackgroundTransparency = 0.3
Header.BorderSizePixel = 0

Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)

local HeaderLine = Instance.new("Frame", Header)
HeaderLine.Size = UDim2.new(1, -20, 0, 1)
HeaderLine.Position = UDim2.new(0, 10, 1, -1)
HeaderLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderLine.BackgroundTransparency = 0.9
HeaderLine.BorderSizePixel = 0

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.fromOffset(20, 0)
Title.BackgroundTransparency = 1
Title.Text = "AIMLOCK"
Title.Font = Enum.Font.GothamBold
Title.TextSize = isMobile and 16 or 14
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local Version = Instance.new("TextLabel", Header)
Version.Size = UDim2.fromOffset(60, 20)
Version.Position = UDim2.new(0, 100, 0.5, -10)
Version.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Version.BackgroundTransparency = 0.95
Version.Text = "v3.0"
Version.Font = Enum.Font.GothamBold
Version.TextSize = 9
Version.TextColor3 = Color3.fromRGB(200, 200, 200)

Instance.new("UICorner", Version).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.fromOffset(isMobile and 35 or 32, isMobile and 35 or 32)
CloseBtn.Position = UDim2.new(1, isMobile and -42 or -38, 0.5, isMobile and -17.5 or -16)
CloseBtn.Text = "×"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = isMobile and 22 or 20
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.95
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BorderSizePixel = 0

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

CloseBtn.MouseEnter:Connect(function()
	TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.8,
		TextColor3 = Color3.fromRGB(255, 50, 50)
	}):Play()
end)

CloseBtn.MouseLeave:Connect(function()
	TweenService:Create(CloseBtn, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.95,
		TextColor3 = Color3.fromRGB(255, 80, 80)
	}):Play()
end)

local MinBtn = Instance.new("TextButton", Header)
MinBtn.Size = UDim2.fromOffset(isMobile and 35 or 32, isMobile and 35 or 32)
MinBtn.Position = UDim2.new(1, isMobile and -82 or -74, 0.5, isMobile and -17.5 or -16)
MinBtn.Text = "−"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = isMobile and 22 or 20
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.BackgroundTransparency = 0.95
MinBtn.TextColor3 = Color3.fromRGB(255, 200, 100)
MinBtn.BorderSizePixel = 0

Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

MinBtn.MouseEnter:Connect(function()
	TweenService:Create(MinBtn, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.8
	}):Play()
end)

MinBtn.MouseLeave:Connect(function()
	TweenService:Create(MinBtn, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.95
	}):Play()
end)

--==================================================
-- TAB SYSTEM (MINIMALIST VERTICAL)
--==================================================
local TabContainer = Instance.new("ScrollingFrame", Main)
TabContainer.Size = UDim2.new(0, isMobile and 65 or 60, 1, isMobile and -120 or -110)
TabContainer.Position = UDim2.fromOffset(10, isMobile and 60 or 55)
TabContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TabContainer.BackgroundTransparency = 0.97
TabContainer.BorderSizePixel = 0
TabContainer.ScrollBarThickness = 2
TabContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
TabContainer.ScrollBarImageTransparency = 0.7
TabContainer.CanvasSize = UDim2.fromOffset(0, 0)
TabContainer.ScrollingDirection = Enum.ScrollingDirection.Y

Instance.new("UICorner", TabContainer).CornerRadius = UDim.new(0, 12)

local TabPadding = Instance.new("UIPadding", TabContainer)
TabPadding.PaddingTop = UDim.new(0, 8)
TabPadding.PaddingBottom = UDim.new(0, 8)
TabPadding.PaddingLeft = UDim.new(0, 6)
TabPadding.PaddingRight = UDim.new(0, 6)

local TabList = Instance.new("UIListLayout", TabContainer)
TabList.FillDirection = Enum.FillDirection.Vertical
TabList.Padding = UDim.new(0, 8)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

TabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	TabContainer.CanvasSize = UDim2.fromOffset(0, TabList.AbsoluteContentSize.Y + 16)
end)

local ContentContainer = Instance.new("Frame", Main)
ContentContainer.Size = UDim2.new(1, isMobile and -85 or -80, 1, isMobile and -120 or -110)
ContentContainer.Position = UDim2.fromOffset(isMobile and 80 or 75, isMobile and 60 or 55)
ContentContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ContentContainer.BackgroundTransparency = 0.97
ContentContainer.BorderSizePixel = 0

Instance.new("UICorner", ContentContainer).CornerRadius = UDim.new(0, 12)

local Tabs = {}
local TabPages = {}
local CurrentTab = nil

local function CreateTab(name, icon)
	local TabButton = Instance.new("TextButton")
	TabButton.Size = UDim2.fromOffset(isMobile and 48 or 44, isMobile and 48 or 44)
	TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabButton.BackgroundTransparency = 0.95
	TabButton.BorderSizePixel = 0
	TabButton.Text = icon
	TabButton.Font = Enum.Font.GothamBold
	TabButton.TextSize = isMobile and 18 or 16
	TabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	TabButton.AutoButtonColor = false
	TabButton.Parent = TabContainer
	
	Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 12)
	
	local Tooltip = Instance.new("TextLabel", TabButton)
	Tooltip.Size = UDim2.fromOffset(70, 24)
	Tooltip.Position = UDim2.new(1, 8, 0.5, -12)
	Tooltip.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	Tooltip.BackgroundTransparency = 0.1
	Tooltip.Text = name
	Tooltip.Font = Enum.Font.Gotham
	Tooltip.TextSize = 10
	Tooltip.TextColor3 = Color3.fromRGB(255, 255, 255)
	Tooltip.Visible = false
	Tooltip.ZIndex = 100
	
	Instance.new("UICorner", Tooltip).CornerRadius = UDim.new(0, 8)
	
	TabButton.MouseEnter:Connect(function()
		Tooltip.Visible = true
		if TabButton.BackgroundTransparency ~= 0.5 then
			TweenService:Create(TabButton, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.9
			}):Play()
		end
	end)
	
	TabButton.MouseLeave:Connect(function()
		Tooltip.Visible = false
		if TabButton.BackgroundTransparency ~= 0.5 then
			TweenService:Create(TabButton, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.95
			}):Play()
		end
	end)
	
	local TabPage = Instance.new("ScrollingFrame")
	TabPage.Size = UDim2.fromScale(1, 1)
	TabPage.BackgroundTransparency = 1
	TabPage.BorderSizePixel = 0
	TabPage.ScrollBarThickness = isMobile and 4 or 3
	TabPage.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	TabPage.ScrollBarImageTransparency = 0.7
	TabPage.CanvasSize = UDim2.fromOffset(0, 0)
	TabPage.Visible = false
	TabPage.Parent = ContentContainer
	
	local PagePadding = Instance.new("UIPadding", TabPage)
	PagePadding.PaddingTop = UDim.new(0, 12)
	PagePadding.PaddingBottom = UDim.new(0, 12)
	PagePadding.PaddingLeft = UDim.new(0, 12)
	PagePadding.PaddingRight = UDim.new(0, 12)
	
	local PageList = Instance.new("UIListLayout", TabPage)
	PageList.Padding = UDim.new(0, 10)
	PageList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	
	PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabPage.CanvasSize = UDim2.fromOffset(0, PageList.AbsoluteContentSize.Y + 24)
	end)
	
	TabButton.MouseButton1Click:Connect(function()
		PlayClickSound()
		
		for _, btn in pairs(Tabs) do
			TweenService:Create(btn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.95,
				TextColor3 = Color3.fromRGB(200, 200, 200)
			}):Play()
		end
		
		for _, page in pairs(TabPages) do
			page.Visible = false
		end
		
		TweenService:Create(TabButton, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.5,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}):Play()
		
		TabPage.Visible = true
		CurrentTab = TabPage
	end)
	
	table.insert(Tabs, TabButton)
	table.insert(TabPages, TabPage)
	
	return TabPage
end

--==================================================
-- UI COMPONENTS
--==================================================
local function CreateSection(parent, text)
	local Section = Instance.new("Frame")
	Section.Size = UDim2.new(1, 0, 0, isMobile and 32 or 28)
	Section.BackgroundTransparency = 1
	Section.Parent = parent
	
	local SectionLabel = Instance.new("TextLabel", Section)
	SectionLabel.Size = UDim2.fromScale(1, 1)
	SectionLabel.BackgroundTransparency = 1
	SectionLabel.Text = text
	SectionLabel.Font = Enum.Font.GothamBold
	SectionLabel.TextSize = isMobile and 11 or 10
	SectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	SectionLabel.TextTransparency = 0.3
	SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
	
	local Line = Instance.new("Frame", Section)
	Line.Size = UDim2.new(1, 0, 0, 1)
	Line.Position = UDim2.fromScale(0, 1)
	Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Line.BackgroundTransparency = 0.9
	Line.BorderSizePixel = 0
	
	return Section
end

local function CreateButton(parent, text, callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, 0, 0, isMobile and 40 or 32)
	Button.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Button.BorderSizePixel = 0
	Button.Text = text
	Button.Font = Enum.Font.Gotham
	Button.TextSize = isMobile and 12 or 10
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.AutoButtonColor = false
	Button.Parent = parent
	
	Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
	
	local Stroke = Instance.new("UIStroke", Button)
	Stroke.Color = Color3.fromRGB(60, 60, 65)
	Stroke.Thickness = 1
	
	Button.MouseButton1Click:Connect(function()
		PlayClickSound()
		if callback then callback() end
	end)
	
	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 55)}):Play()
	end)
	
	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
	end)
	
	return Button
end

local function CreateToggle(parent, text, default, callback)
	local Toggle = Instance.new("Frame")
	Toggle.Size = UDim2.new(1, 0, 0, isMobile and 40 or 32)
	Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Toggle.BorderSizePixel = 0
	Toggle.Parent = parent
	
	Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)
	
	local Label = Instance.new("TextLabel", Toggle)
	Label.Size = UDim2.new(1, -60, 1, 0)
	Label.Position = UDim2.fromOffset(10, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = isMobile and 11 or 10
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	
	local ToggleButton = Instance.new("TextButton", Toggle)
	ToggleButton.Size = UDim2.fromOffset(isMobile and 50 or 40, isMobile and 25 or 20)
	ToggleButton.Position = UDim2.new(1, isMobile and -55 or -45, 0.5, isMobile and -12.5 or -10)
	ToggleButton.BackgroundColor3 = default and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(60, 60, 65)
	ToggleButton.BackgroundTransparency = 0
	ToggleButton.BorderSizePixel = 0
	ToggleButton.Text = ""
	
	Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)
	
	local Indicator = Instance.new("Frame", ToggleButton)
	Indicator.Size = UDim2.fromOffset(isMobile and 20 or 16, isMobile and 20 or 16)
	Indicator.Position = default and UDim2.new(1, isMobile and -22 or -18, 0.5, isMobile and -10 or -8) or UDim2.fromOffset(2.5, 2.5)
	Indicator.BackgroundColor3 = Color3.new(1, 1, 1)
	Indicator.BorderSizePixel = 0
	
	Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
	
	local toggled = default
	
	ToggleButton.MouseButton1Click:Connect(function()
		toggled = not toggled
		PlayToggleSound()
		
		TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
			BackgroundColor3 = toggled and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(60, 60, 65)
		}):Play()
		
		TweenService:Create(Indicator, TweenInfo.new(0.2), {
			Position = toggled and UDim2.new(1, isMobile and -22 or -18, 0.5, isMobile and -10 or -8) or UDim2.fromOffset(2.5, 2.5)
		}):Play()
		
		if callback then callback(toggled) end
	end)
	
	return Toggle, function() return toggled end, function(val)
		toggled = val
		TweenService:Create(ToggleButton, TweenInfo.new(0.2), {
			BackgroundColor3 = toggled and Color3.fromRGB(0, 180, 90) or Color3.fromRGB(60, 60, 65)
		}):Play()
		TweenService:Create(Indicator, TweenInfo.new(0.2), {
			Position = toggled and UDim2.new(1, isMobile and -22 or -18, 0.5, isMobile and -10 or -8) or UDim2.fromOffset(2.5, 2.5)
		}):Play()
	end
end

local function CreateSlider(parent, text, min, max, default, callback)
	local Slider = Instance.new("Frame")
	Slider.Size = UDim2.new(1, 0, 0, isMobile and 60 or 50)
	Slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Slider.BorderSizePixel = 0
	Slider.Parent = parent
	
	Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 6)
	
	local Label = Instance.new("TextLabel", Slider)
	Label.Size = UDim2.new(1, -20, 0, 20)
	Label.Position = UDim2.fromOffset(10, 5)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = isMobile and 11 or 10
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	
	local ValueLabel = Instance.new("TextLabel", Slider)
	ValueLabel.Size = UDim2.fromOffset(50, 20)
	ValueLabel.Position = UDim2.new(1, -60, 0, 5)
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.Text = tostring(default)
	ValueLabel.Font = Enum.Font.GothamBold
	ValueLabel.TextSize = isMobile and 11 or 10
	ValueLabel.TextColor3 = Color3.fromRGB(0, 255, 170)
	ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
	
	local SliderBar = Instance.new("Frame", Slider)
	SliderBar.Size = UDim2.new(1, -20, 0, isMobile and 6 or 4)
	SliderBar.Position = UDim2.fromOffset(10, isMobile and 40 or 35)
	SliderBar.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	SliderBar.BorderSizePixel = 0
	
	Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
	
	local SliderFill = Instance.new("Frame", SliderBar)
	SliderFill.Size = UDim2.fromScale((default - min) / (max - min), 1)
	SliderFill.BackgroundColor3 = Color3.fromRGB(0, 255, 170)
	SliderFill.BorderSizePixel = 0
	
	Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
	
	local SliderButton = Instance.new("TextButton", SliderBar)
	SliderButton.Size = UDim2.fromOffset(isMobile and 20 or 16, isMobile and 20 or 16)
	SliderButton.Position = UDim2.fromScale((default - min) / (max - min), 0.5)
	SliderButton.AnchorPoint = Vector2.new(0.5, 0.5)
	SliderButton.BackgroundColor3 = Color3.new(1, 1, 1)
	SliderButton.BorderSizePixel = 0
	SliderButton.Text = ""
	
	Instance.new("UICorner", SliderButton).CornerRadius = UDim.new(1, 0)
	
	local dragging = false
	local value = default
	
	local function UpdateSlider(input)
		local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
		value = math.floor(min + (max - min) * pos)
		
		ValueLabel.Text = tostring(value)
		SliderFill.Size = UDim2.fromScale(pos, 1)
		SliderButton.Position = UDim2.fromScale(pos, 0.5)
		
		if callback then callback(value) end
	end
	
	SliderButton.MouseButton1Down:Connect(function()
		dragging = true
		PlayClickSound()
	end)
	
	SliderButton.TouchTap:Connect(function()
		dragging = true
		PlayClickSound()
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			UpdateSlider(input)
		end
	end)
	
	SliderBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			UpdateSlider(input)
		end
	end)
	
	return Slider, function() return value end
end

local function CreateColorPicker(parent, text, default, callback)
	local Picker = Instance.new("Frame")
	Picker.Size = UDim2.new(1, 0, 0, isMobile and 40 or 32)
	Picker.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Picker.BorderSizePixel = 0
	Picker.Parent = parent
	
	Instance.new("UICorner", Picker).CornerRadius = UDim.new(0, 6)
	
	local Label = Instance.new("TextLabel", Picker)
	Label.Size = UDim2.new(1, -80, 1, 0)
	Label.Position = UDim2.fromOffset(10, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = isMobile and 11 or 10
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	
	local ColorDisplay = Instance.new("TextButton", Picker)
	ColorDisplay.Size = UDim2.fromOffset(isMobile and 70 or 60, isMobile and 28 or 22)
	ColorDisplay.Position = UDim2.new(1, isMobile and -75 or -70, 0.5, isMobile and -14 or -11)
	ColorDisplay.BackgroundColor3 = default
	ColorDisplay.BorderSizePixel = 0
	ColorDisplay.Text = ""
	
	Instance.new("UICorner", ColorDisplay).CornerRadius = UDim.new(0, 4)
	
	local ColorStroke = Instance.new("UIStroke", ColorDisplay)
	ColorStroke.Color = Color3.fromRGB(255, 255, 255)
	ColorStroke.Thickness = 1
	
	ColorDisplay.MouseButton1Click:Connect(function()
		PlayClickSound()
		local colors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 127, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(255, 255, 255)
		}
		
		local currentColor = ColorDisplay.BackgroundColor3
		local nextIndex = 1
		
		for i, color in ipairs(colors) do
			if color == currentColor then
				nextIndex = (i % #colors) + 1
				break
			end
		end
		
		ColorDisplay.BackgroundColor3 = colors[nextIndex]
		if callback then callback(colors[nextIndex]) end
	end)
	
	return Picker, function() return ColorDisplay.BackgroundColor3 end
end

local WaitingForKey = nil
local WaitingForCallback = nil
local KeyNames = {
	[Enum.KeyCode.E] = "E",
	[Enum.KeyCode.R] = "R",
	[Enum.KeyCode.J] = "J",
	[Enum.KeyCode.T] = "T",
	[Enum.KeyCode.F] = "F",
	[Enum.KeyCode.H] = "H",
	[Enum.KeyCode.Q] = "Q",
	[Enum.KeyCode.X] = "X",
	[Enum.KeyCode.C] = "C",
	[Enum.KeyCode.V] = "V",
	[Enum.KeyCode.Z] = "Z",
	[Enum.KeyCode.B] = "B",
	[Enum.KeyCode.G] = "G",
	[Enum.KeyCode.K] = "K",
	[Enum.KeyCode.L] = "L",
	[Enum.KeyCode.M] = "M",
	[Enum.KeyCode.N] = "N",
	[Enum.KeyCode.P] = "P",
	[Enum.KeyCode.Y] = "Y",
	[Enum.KeyCode.U] = "U",
	[Enum.KeyCode.LeftShift] = "LSHIFT",
	[Enum.KeyCode.RightShift] = "RSHIFT",
	[Enum.KeyCode.LeftControl] = "LCTRL",
	[Enum.KeyCode.RightControl] = "RCTRL",
	[Enum.KeyCode.LeftAlt] = "LALT",
	[Enum.KeyCode.RightAlt] = "RALT",
	[Enum.KeyCode.Insert] = "INSERT",
	[Enum.KeyCode.Home] = "HOME",
	[Enum.KeyCode.Delete] = "DELETE",
	[Enum.KeyCode.End] = "END",
	[Enum.KeyCode.PageUp] = "PGUP",
	[Enum.KeyCode.PageDown] = "PGDN"
}

local function CreateKeybind(parent, text, defaultKey, callback)
	local Keybind = Instance.new("Frame")
	Keybind.Size = UDim2.new(1, 0, 0, isMobile and 40 or 32)
	Keybind.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	Keybind.BorderSizePixel = 0
	Keybind.Parent = parent
	
	Instance.new("UICorner", Keybind).CornerRadius = UDim.new(0, 6)
	
	local Label = Instance.new("TextLabel", Keybind)
	Label.Size = UDim2.new(1, -95, 1, 0)
	Label.Position = UDim2.fromOffset(10, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = isMobile and 11 or 10
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	
	local KeyButton = Instance.new("TextButton", Keybind)
	KeyButton.Size = UDim2.fromOffset(isMobile and 85 or 70, isMobile and 30 or 24)
	KeyButton.Position = UDim2.new(1, isMobile and -90 or -75, 0.5, isMobile and -15 or -12)
	KeyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
	KeyButton.BorderSizePixel = 0
	KeyButton.Text = KeyNames[defaultKey] or tostring(defaultKey.Name)
	KeyButton.Font = Enum.Font.GothamBold
	KeyButton.TextSize = isMobile and 11 or 10
	KeyButton.TextColor3 = Color3.fromRGB(0, 255, 170)
	
	Instance.new("UICorner", KeyButton).CornerRadius = UDim.new(0, 4)
	
	local currentKey = defaultKey
	
	local function SetKey(key)
		currentKey = key
		KeyButton.Text = KeyNames[key] or tostring(key.Name)
		KeyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		if callback then callback(key) end
	end
	
	KeyButton.MouseButton1Click:Connect(function()
		PlayClickSound()
		WaitingForKey = KeyButton
		WaitingForCallback = SetKey
		KeyButton.Text = "..."
		KeyButton.BackgroundColor3 = Color3.fromRGB(255, 180, 60)
	end)
	
	return Keybind, function() return currentKey end, SetKey
end

--==================================================
-- CREATE TABS
--==================================================
local AimbotTab = CreateTab("Aim", "🎯")
local VisualsTab = CreateTab("ESP", "👁️")
local KeybindsTab = CreateTab("Keys", "⌨️")
local ColorsTab = CreateTab("Colors", "🎨")
local MiscTab = CreateTab("Misc", "🔧")
local SettingsTab = CreateTab("Info", "ℹ️")

Tabs[1].BackgroundTransparency = 0.5
Tabs[1].TextColor3 = Color3.new(1, 1, 1)
AimbotTab.Visible = true
CurrentTab = AimbotTab

--==================================================
-- AIMBOT TAB
--==================================================
CreateSection(AimbotTab, "🎯 Aimbot Settings")

local AimlockToggle, GetAimlockState, SetAimlockState = CreateToggle(AimbotTab, "Enable Aimlock", false, function(val)
	CFG.Aimlock = val
	if not val then 
		LockedTarget = nil
		if LockIndicator then LockIndicator.Visible = false end
	end
	Notify("Aimlock", val and "Enabled" or "Disabled", 2, true)
end)

CreateSlider(AimbotTab, "Smoothness", 1, 50, 25, function(val)
	CFG.Smooth = val
end)

CreateSlider(AimbotTab, "FOV Radius", 50, 500, 120, function(val)
	CFG.FOVRadius = val
end)

CreateSection(AimbotTab, "🎯 Target Settings")

local targetOptions = {"Head", "Body", "Legs"}
local currentTargetIndex = 1
local targetButton = nil

local function CycleTargetPart()
	currentTargetIndex = (currentTargetIndex % 3) + 1
	CFG.Target = targetOptions[currentTargetIndex]
	targetButton.Text = "🎯 Target: " .. CFG.Target:upper()
	Notify("Target Changed", "Now targeting: " .. CFG.Target, 2, true)
end

targetButton = CreateButton(AimbotTab, "🎯 Target: HEAD", function()
	CycleTargetPart()
end)

local WallCheckToggle, GetWallCheckState, SetWallCheckState = CreateToggle(AimbotTab, "Wall Check", false, function(val)
	CFG.WallCheck = val
	Notify("Wall Check", val and "Enabled" or "Disabled", 2, true)
end)

local TeamCheckToggle, GetTeamCheckState, SetTeamCheckState = CreateToggle(AimbotTab, "Team Check", false, function(val)
	CFG.TeamCheck = val
	Notify("Team Check", val and "Enabled" or "Disabled", 2, true)
end)

CreateSection(AimbotTab, "🎯 Advanced Settings")

CreateToggle(AimbotTab, "Prediction", false, function(val)
	CFG.Prediction = val
	Notify("Prediction", val and "Enabled" or "Disabled", 2, true)
end)

CreateSlider(AimbotTab, "Prediction Amount", 0, 50, 5, function(val)
	CFG.PredictionAmount = val / 100
end)

local AutoFireToggle, GetAutoFireState, SetAutoFireState = CreateToggle(AimbotTab, "Auto Fire", false, function(val)
	CFG.AutoFire = val
	Notify("Auto Fire", val and "Enabled" or "Disabled", 2, true)
end)

CreateToggle(AimbotTab, "Dynamic FOV", false, function(val)
	CFG.DynamicFOV = val
	Notify("Dynamic FOV", val and "FOV shrinks when locked" or "Static FOV", 2, true)
end)

CreateSlider(AimbotTab, "Locked FOV Size", 30, 140, 50, function(val)
	CFG.LockedFOV = val
end)

--==================================================
-- VISUALS TAB
--==================================================
CreateSection(VisualsTab, "👁️ ESP Settings")

local ESPToggle, GetESPState, SetESPState = CreateToggle(VisualsTab, "Enable Box ESP", false, function(val)
	CFG.ESP = val
	Notify("Box ESP", val and "Enabled" or "Disabled", 2, true)
end)

local SkeletonToggle, GetSkeletonState, SetSkeletonState = CreateToggle(VisualsTab, "Enable Skeleton ESP", false, function(val)
	CFG.Skeleton = val
	Notify("Skeleton ESP", val and "Enabled" or "Disabled", 2, true)
end)

local HighlightToggle, GetHighlightState, SetHighlightState = CreateToggle(VisualsTab, "Enable 3D Highlight", false, function(val)
	CFG.Highlight = val
	Notify("3D Highlight", val and "Enabled" or "Disabled", 2, true)
end)

local FOVToggle, GetFOVState, SetFOVState = CreateToggle(VisualsTab, "Show FOV Circle", false, function(val)
	CFG.FOVEnabled = val
	if FOVCircle then
		FOVCircle.Visible = val
	end
	Notify("FOV Circle", val and "Enabled" or "Disabled", 2, true)
end)

CreateSection(VisualsTab, "📏 Display Settings")

CreateToggle(VisualsTab, "Show Name", true, function(val)
	CFG.ShowName = val
	Notify("Show Name", val and "Enabled" or "Disabled", 2, true)
end)

CreateToggle(VisualsTab, "Show Distance", true, function(val)
	CFG.ShowDistance = val
	Notify("Show Distance", val and "Enabled" or "Disabled", 2, true)
end)

CreateToggle(VisualsTab, "Show Health", true, function(val)
	CFG.ShowHealth = val
	Notify("Show Health", val and "Enabled" or "Disabled", 2, true)
end)

CreateToggle(VisualsTab, "Show Target Info", true, function(val)
	CFG.ShowTargetInfo = val
	if not val then
		TargetInfoFrame.Visible = false
	end
	Notify("Target Info", val and "Enabled" or "Disabled", 2, true)
end)

--==================================================
-- MISC TAB
--==================================================
CreateSection(MiscTab, "🚀 Performance Boost")

local FPSBoostActive = false
local BoostConnection = nil

CreateToggle(MiscTab, "FPS Boost (Optimized)", false, function(val)
	CFG.FPSBoost = val
	FPSBoostActive = val
	
	if val then
		print("🚀 Starting Optimized FPS Boost...")
		
		pcall(function()
			local lighting = game:GetService("Lighting")
			lighting.GlobalShadows = false
			lighting.FogEnd = 9e9
			lighting.Brightness = 2.5
			lighting.Ambient = Color3.fromRGB(200, 200, 200)
			lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
			lighting.EnvironmentDiffuseScale = 0
			lighting.EnvironmentSpecularScale = 0
			lighting.ShadowSoftness = 0
			lighting.ClockTime = 14
			
			for _, v in pairs(lighting:GetChildren()) do
				if v:IsA("BloomEffect") or v:IsA("BlurEffect") or 
				   v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") or
				   v:IsA("SunRaysEffect") or v:IsA("Atmosphere") then
					v:Destroy()
				end
			end
		end)
		
		pcall(function()
			settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
		end)
		
		task.spawn(function()
			local stats = {textures = 0, particles = 0, lights = 0, parts = 0}
			print("🗑️ Cleaning workspace (one-time)...")
			
			local descendants = workspace:GetDescendants()
			local processed = 0
			
			for _, obj in pairs(descendants) do
				processed = processed + 1
				
				if processed % 1000 == 0 then
					task.wait()
				end
				
				pcall(function()
					if obj:IsDescendantOf(LocalPlayer.Character) then return end
					
					if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
						obj:Destroy()
						stats.textures = stats.textures + 1
					elseif obj:IsA("MeshPart") then
						obj.TextureID = ""
						obj.Material = Enum.Material.SmoothPlastic
						obj.Reflectance = 0
						obj.CastShadow = false
						stats.parts = stats.parts + 1
					elseif obj:IsA("SpecialMesh") then
						obj.TextureId = ""
					elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or 
					       obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
						obj:Destroy()
						stats.particles = stats.particles + 1
					elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
						obj:Destroy()
						stats.lights = stats.lights + 1
					elseif obj:IsA("BasePart") then
						obj.Material = Enum.Material.SmoothPlastic
						obj.Reflectance = 0
						obj.CastShadow = false
						stats.parts = stats.parts + 1
					end
				end)
			end
			
			print("✅ Cleanup complete!")
			print("   Textures: " .. stats.textures)
			print("   Particles: " .. stats.particles)
			print("   Lights: " .. stats.lights)
			print("   Parts: " .. stats.parts)
		end)
		
		if BoostConnection then
			BoostConnection:Disconnect()
		end
		
		BoostConnection = workspace.DescendantAdded:Connect(function(obj)
			if not FPSBoostActive then return end
			task.wait(0.2)
			
			task.spawn(function()
				pcall(function()
					if obj:IsDescendantOf(LocalPlayer.Character) then return end
					
					if obj:IsA("Decal") or obj:IsA("Texture") or obj:IsA("SurfaceAppearance") then
						obj:Destroy()
					elseif obj:IsA("MeshPart") then
						obj.TextureID = ""
						obj.Material = Enum.Material.SmoothPlastic
						obj.CastShadow = false
					elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or 
					       obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
						obj:Destroy()
					elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
						obj:Destroy()
					elseif obj:IsA("BasePart") then
						obj.Material = Enum.Material.SmoothPlastic
						obj.CastShadow = false
						obj.Reflectance = 0
					end
				end)
			end)
		end)
		
		task.wait(1)
		
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("🚀 OPTIMIZED FPS BOOST ACTIVE!")
		print("✅ Smooth performance")
		print("✅ No lag/stutter")
		print("✅ Proper brightness")
		print("✅ Auto-cleanup for NEW objects")
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		Notify("FPS Boost", "Enabled!", 3, true)
	else
		FPSBoostActive = false
		
		if BoostConnection then
			BoostConnection:Disconnect()
			BoostConnection = nil
		end
		
		pcall(function()
			local lighting = game:GetService("Lighting")
			lighting.GlobalShadows = true
			lighting.Brightness = 2
			lighting.Ambient = Color3.fromRGB(127, 127, 127)
			lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)
		end)
		
		print("✅ FPS Boost Disabled")
		print("⚠️ Rejoin to restore all graphics")
		Notify("FPS Boost", "Disabled", 3, true)
	end
end)

--==================================================
-- KEYBINDS TAB
--==================================================
CreateSection(KeybindsTab, "⌨️ Keybind Configuration")

if not isMobile then
	local InfoBox = Instance.new("Frame")
	InfoBox.Size = UDim2.new(1, 0, 0, 45)
	InfoBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	InfoBox.BorderSizePixel = 0
	InfoBox.Parent = KeybindsTab
	
	Instance.new("UICorner", InfoBox).CornerRadius = UDim.new(0, 6)
	
	local InfoText = Instance.new("TextLabel", InfoBox)
	InfoText.Size = UDim2.fromScale(1, 1)
	InfoText.BackgroundTransparency = 1
	InfoText.Text = "ℹ️ Klik tombol keybind untuk mengganti\nTekan tombol keyboard untuk set keybind baru"
	InfoText.Font = Enum.Font.Gotham
	InfoText.TextSize = 9
	InfoText.TextColor3 = Color3.fromRGB(200, 200, 200)
	InfoText.TextWrapped = true
	
	local InfoPadding = Instance.new("UIPadding", InfoText)
	InfoPadding.PaddingLeft = UDim.new(0, 10)
	InfoPadding.PaddingRight = UDim.new(0, 10)
	
	CreateSection(KeybindsTab, "🎯 Combat Keybinds")
	
	CreateKeybind(KeybindsTab, "Toggle Aimlock", CFG.Keybinds.ToggleAimlock, function(key)
		CFG.Keybinds.ToggleAimlock = key
	end)
	
	CreateKeybind(KeybindsTab, "Toggle Auto Fire", CFG.Keybinds.ToggleAutoFire, function(key)
		CFG.Keybinds.ToggleAutoFire = key
	end)
	
	CreateKeybind(KeybindsTab, "Cycle Target Part", CFG.Keybinds.CycleTarget, function(key)
		CFG.Keybinds.CycleTarget = key
	end)
	
	CreateSection(KeybindsTab, "🛡️ Check Keybinds")
	
	CreateKeybind(KeybindsTab, "Toggle Wall Check", CFG.Keybinds.ToggleWallCheck, function(key)
		CFG.Keybinds.ToggleWallCheck = key
	end)
	
	CreateKeybind(KeybindsTab, "Toggle Team Check", CFG.Keybinds.ToggleTeamCheck, function(key)
		CFG.Keybinds.ToggleTeamCheck = key
	end)
	
	CreateSection(KeybindsTab, "👁️ Visual Keybinds")
	
	CreateKeybind(KeybindsTab, "Toggle ESP", CFG.Keybinds.ToggleESP, function(key)
		CFG.Keybinds.ToggleESP = key
	end)
	
	CreateKeybind(KeybindsTab, "Toggle Skeleton", CFG.Keybinds.ToggleSkeleton, function(key)
		CFG.Keybinds.ToggleSkeleton = key
	end)
	
	CreateKeybind(KeybindsTab, "Toggle Highlight", CFG.Keybinds.ToggleHighlight, function(key)
		CFG.Keybinds.ToggleHighlight = key
	end)
	
	CreateKeybind(KeybindsTab, "Toggle FOV Circle", CFG.Keybinds.ToggleFOV, function(key)
		CFG.Keybinds.ToggleFOV = key
	end)
	
	CreateSection(KeybindsTab, "⚙️ UI Keybinds")
	
	CreateKeybind(KeybindsTab, "Toggle GUI", CFG.Keybinds.ToggleGUI, function(key)
		CFG.Keybinds.ToggleGUI = key
	end)
else
	local MobileInfo = Instance.new("TextLabel")
	MobileInfo.Size = UDim2.new(1, 0, 0, 100)
	MobileInfo.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	MobileInfo.BorderSizePixel = 0
	MobileInfo.Text = "📱 MOBILE MODE\n\nKeybinds tidak tersedia di mobile.\nGunakan toggle button dan tombol di GUI untuk kontrol."
	MobileInfo.Font = Enum.Font.Gotham
	MobileInfo.TextSize = 11
	MobileInfo.TextColor3 = Color3.fromRGB(200, 200, 200)
	MobileInfo.TextWrapped = true
	MobileInfo.Parent = KeybindsTab
	
	Instance.new("UICorner", MobileInfo).CornerRadius = UDim.new(0, 6)
	
	local MobilePadding = Instance.new("UIPadding", MobileInfo)
	MobilePadding.PaddingTop = UDim.new(0, 10)
	MobilePadding.PaddingLeft = UDim.new(0, 10)
	MobilePadding.PaddingRight = UDim.new(0, 10)
end

--==================================================
-- COLORS TAB
--==================================================
CreateSection(ColorsTab, "🎨 Color Customization")

CreateToggle(ColorsTab, "RGB Mode (Animated)", false, function(val)
	CFG.RGBEnabled = val
end)

CreateColorPicker(ColorsTab, "FOV Circle Color", CFG.FOVColor, function(color)
	CFG.FOVColor = color
	if FOVCircle then
		if FOVCircle.Color then
			FOVCircle.Color = color
		else
			local stroke = FOVCircle:FindFirstChild("UIStroke")
			if stroke then stroke.Color = color end
		end
	end
end)

CreateColorPicker(ColorsTab, "ESP Box Color", CFG.ESPColor, function(color)
	CFG.ESPColor = color
end)

CreateColorPicker(ColorsTab, "ESP Team Color", CFG.ESPTeamColor, function(color)
	CFG.ESPTeamColor = color
end)

CreateColorPicker(ColorsTab, "Skeleton Color", CFG.SkeletonColor, function(color)
	CFG.SkeletonColor = color
end)

CreateColorPicker(ColorsTab, "Highlight Color", CFG.HighlightColor, function(color)
	CFG.HighlightColor = color
end)

--==================================================
-- SETTINGS TAB
--==================================================
CreateSection(SettingsTab, "⚙️ General Settings")

CreateButton(SettingsTab, "Reset All Settings", function()
	CFG.Aimlock = false
	CFG.ESP = false
	CFG.Skeleton = false
	CFG.Highlight = false
	CFG.FOVEnabled = false
	CFG.TeamCheck = false
	CFG.WallCheck = false
	CFG.RGBEnabled = false
	
	SetAimlockState(false)
	SetESPState(false)
	SetSkeletonState(false)
	SetHighlightState(false)
	SetFOVState(false)
	
	print("✅ Settings Reset!")
	PlayToggleSound()
end)

CreateSection(SettingsTab, "ℹ️ Information")

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, isMobile and 140 or 120)
InfoLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
InfoLabel.BorderSizePixel = 0
InfoLabel.Text = string.format([[
🎯 AIMLOCK PRO V3.0
Version: 3.0.0 %s
Creator: AI Assistant
Status: PREMIUM
Features:
✅ Advanced Aimbot
✅ ESP (Box, Skeleton, Highlight)
✅ Customizable Keybinds
✅ Customizable Colors
✅ RGB Mode
✅ Sound Effects
✅ Full Mobile Support
]], isMobile and "(MOBILE)" or isTablet and "(TABLET)" or "(PC)")
InfoLabel.Font = Enum.Font.Code
InfoLabel.TextSize = isMobile and 10 or 9
InfoLabel.TextColor3 = Color3.new(1, 1, 1)
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = SettingsTab

Instance.new("UICorner", InfoLabel).CornerRadius = UDim.new(0, 6)

local InfoPadding2 = Instance.new("UIPadding", InfoLabel)
InfoPadding2.PaddingTop = UDim.new(0, 10)
InfoPadding2.PaddingLeft = UDim.new(0, 10)
InfoPadding2.PaddingRight = UDim.new(0, 10)

--==================================================
-- KEYBIND SYSTEM (PC ONLY)
--==================================================
if not isMobile then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if not GUI or not GUI.Parent then
			return
		end
		
		if WaitingForKey and WaitingForCallback then
			local keyCode = input.KeyCode
			if keyCode ~= Enum.KeyCode.Unknown and keyCode ~= Enum.KeyCode.Escape then
				PlayToggleSound()
				WaitingForCallback(keyCode)
				WaitingForKey = nil
				WaitingForCallback = nil
			elseif keyCode == Enum.KeyCode.Escape then
				WaitingForKey.Text = KeyNames[CFG.Keybinds.ToggleAimlock] or "..."
				WaitingForKey.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
				WaitingForKey = nil
				WaitingForCallback = nil
				PlayClickSound()
			end
			return
		end
		
		if CFG.Keybinds.ToggleAimlock and input.KeyCode == CFG.Keybinds.ToggleAimlock then
			CFG.Aimlock = not CFG.Aimlock
			SetAimlockState(CFG.Aimlock)
			PlayToggleSound()
			Notify("Aimlock", CFG.Aimlock and "ON" or "OFF", 1.5, true)
			if not CFG.Aimlock then
				LockedTarget = nil
				if LockIndicator then LockIndicator.Visible = false end
			end
		elseif CFG.Keybinds.ToggleESP and input.KeyCode == CFG.Keybinds.ToggleESP then
			CFG.ESP = not CFG.ESP
			SetESPState(CFG.ESP)
			PlayToggleSound()
			Notify("ESP", CFG.ESP and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.ToggleSkeleton and input.KeyCode == CFG.Keybinds.ToggleSkeleton then
			CFG.Skeleton = not CFG.Skeleton
			SetSkeletonState(CFG.Skeleton)
			PlayToggleSound()
			Notify("Skeleton", CFG.Skeleton and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.ToggleHighlight and input.KeyCode == CFG.Keybinds.ToggleHighlight then
			CFG.Highlight = not CFG.Highlight
			SetHighlightState(CFG.Highlight)
			PlayToggleSound()
			Notify("Highlight", CFG.Highlight and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.ToggleFOV and input.KeyCode == CFG.Keybinds.ToggleFOV then
			CFG.FOVEnabled = not CFG.FOVEnabled
			SetFOVState(CFG.FOVEnabled)
			if FOVCircle then
				FOVCircle.Visible = CFG.FOVEnabled
			end
			PlayToggleSound()
			Notify("FOV", CFG.FOVEnabled and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.ToggleWallCheck and input.KeyCode == CFG.Keybinds.ToggleWallCheck then
			CFG.WallCheck = not CFG.WallCheck
			SetWallCheckState(CFG.WallCheck)
			PlayToggleSound()
			Notify("Wall Check", CFG.WallCheck and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.ToggleTeamCheck and input.KeyCode == CFG.Keybinds.ToggleTeamCheck then
			CFG.TeamCheck = not CFG.TeamCheck
			SetTeamCheckState(CFG.TeamCheck)
			PlayToggleSound()
			Notify("Team Check", CFG.TeamCheck and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.ToggleAutoFire and input.KeyCode == CFG.Keybinds.ToggleAutoFire then
			CFG.AutoFire = not CFG.AutoFire
			SetAutoFireState(CFG.AutoFire)
			PlayToggleSound()
			Notify("Auto Fire", CFG.AutoFire and "ON" or "OFF", 1.5, true)
		elseif CFG.Keybinds.CycleTarget and input.KeyCode == CFG.Keybinds.CycleTarget then
			CycleTargetPart()
			PlayToggleSound()
		elseif CFG.Keybinds.ToggleGUI and input.KeyCode == CFG.Keybinds.ToggleGUI then
			GUI.Enabled = not GUI.Enabled
			PlayToggleSound()
			if GUI.Enabled then
				Main.Size = UDim2.fromOffset(0, 0)
				local targetSize = isMobile and UDim2.new(0.45, 0, 0.75, 0) or isTablet and UDim2.new(0.7, 0, 0.75, 0) or UDim2.fromOffset(480, 540)
				TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = targetSize
				}):Play()
			end
		end
	end)
end

--==================================================
-- BUTTON LOGIC
--==================================================
CloseBtn.MouseButton1Click:Connect(function()
	PlayCloseSound()
	
	CFG.ScriptEnabled = false
	
	CFG.Keybinds.ToggleAimlock = nil
	CFG.Keybinds.ToggleAutoFire = nil
	CFG.Keybinds.CycleTarget = nil
	CFG.Keybinds.ToggleESP = nil
	CFG.Keybinds.ToggleFOV = nil
	CFG.Keybinds.ToggleGUI = nil
	CFG.Keybinds.ToggleSkeleton = nil
	CFG.Keybinds.ToggleHighlight = nil
	CFG.Keybinds.ToggleWallCheck = nil
	CFG.Keybinds.ToggleTeamCheck = nil
	
	CFG.Aimlock = false
	CFG.Prediction = false
	CFG.AutoFire = false
	CFG.ESP = false
	CFG.Skeleton = false
	CFG.Highlight = false
	CFG.FOVEnabled = false
	CFG.WallCheck = false
	CFG.TeamCheck = false
	
	if FOVCircle then
		FOVCircle.Visible = false
		pcall(function()
			if FOVCircle.Remove then
				FOVCircle:Remove()
			else
				FOVCircle:Destroy()
			end
		end)
	end
	
	if LockIndicator then
		LockIndicator.Visible = false
		pcall(function()
			LockIndicator:Remove()
		end)
	end
	
	for player, esp in pairs(ESPObjects) do
		pcall(function()
			for _, obj in pairs(esp) do
				if type(obj) == "table" or type(obj) == "userdata" then
					pcall(function()
						if obj.ClassName == "Highlight" then
							obj.Enabled = false
							obj:Destroy()
						else
							obj.Visible = false
							obj:Remove()
						end
					end)
				end
			end
		end)
	end
	
	ESPObjects = {}
	
	TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.fromOffset(0, 0)
	}):Play()
	
	task.wait(0.3)
	
	pcall(function()
		GUI:Destroy()
	end)
	
	pcall(function()
		ToggleButtonGui:Destroy()
	end)
	
	pcall(function()
		TargetInfoGui:Destroy()
	end)
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🎯 AIMLOCK SCRIPT CLOSED")
	print("✅ All keybinds disabled")
	print("✅ All features disabled")
	print("✅ GUI destroyed")
	print("✅ Script terminated successfully")
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
end)

MinBtn.MouseButton1Click:Connect(function()
	PlayToggleSound()
	GUI.Enabled = false
end)

ToggleButton.MouseButton1Click:Connect(function()
	if not GUI or not GUI.Parent then
		print("⚠️ GUI sudah di-close! Execute script ulang untuk membuka.")
		return
	end
	
	PlayToggleSound()
	if not GUI.Enabled then
		GUI.Enabled = true
		Main.Size = UDim2.fromOffset(0, 0)
		local targetSize = isMobile and UDim2.new(0.95, 0, 0.8, 0) or isTablet and UDim2.new(0.7, 0, 0.75, 0) or UDim2.fromOffset(480, 540)
		
		TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = targetSize
		}):Play()
		
		CFG.ScriptEnabled = true
	else
		GUI.Enabled = false
	end
end)

--==================================================
-- ESP SYSTEM
--==================================================
local function CreateESP(player)
	if player == LocalPlayer then return end
	if ESPObjects[player] then return end
	
	local esp = {}
	
	esp.TopLine = Drawing.new("Line")
	esp.BottomLine = Drawing.new("Line")
	esp.LeftLine = Drawing.new("Line")
	esp.RightLine = Drawing.new("Line")
	esp.Tracer = Drawing.new("Line")
	
	esp.Head_Neck = Drawing.new("Line")
	esp.Neck_Torso = Drawing.new("Line")
	esp.Torso_LeftArm = Drawing.new("Line")
	esp.Torso_RightArm = Drawing.new("Line")
	esp.Torso_LeftLeg = Drawing.new("Line")
	esp.Torso_RightLeg = Drawing.new("Line")
	esp.LeftArm_LeftHand = Drawing.new("Line")
	esp.RightArm_RightHand = Drawing.new("Line")
	esp.LeftLeg_LeftFoot = Drawing.new("Line")
	esp.RightLeg_RightFoot = Drawing.new("Line")
	
	esp.Name = Drawing.new("Text")
	esp.Distance = Drawing.new("Text")
	esp.Health = Drawing.new("Text")
	
	for key, line in pairs(esp) do
		if line.ClassName == "Line" then
			line.Thickness = 1.5
			line.Transparency = 1
			line.Visible = false
		end
	end
	
	for _, text in pairs({esp.Name, esp.Distance, esp.Health}) do
		text.Size = 13
		text.Center = true
		text.Outline = true
		text.Font = 2
		text.Transparency = 1
		text.Color = Color3.fromRGB(255, 255, 255)
		text.Visible = false
	end
	
	esp.Highlight = Instance.new("Highlight")
	esp.Highlight.Enabled = false
	esp.Highlight.FillTransparency = 0.5
	esp.Highlight.OutlineTransparency = 0
	esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	
	ESPObjects[player] = esp
end

local function RemoveESP(player)
	if ESPObjects[player] then
		for _, obj in pairs(ESPObjects[player]) do
			pcall(function()
				if obj.ClassName == "Highlight" then
					obj:Destroy()
				else
					obj:Remove()
				end
			end)
		end
		ESPObjects[player] = nil
	end
end

local function UpdateESP()
	if not CFG.ScriptEnabled then
		for _, esp in pairs(ESPObjects) do
			for _, obj in pairs(esp) do
				if type(obj) == "table" or type(obj) == "userdata" then
					pcall(function()
						if obj.ClassName == "Highlight" then
							obj.Enabled = false
						else
							obj.Visible = false
						end
					end)
				end
			end
		end
		return
	end
	
	for player, esp in pairs(ESPObjects) do
		pcall(function()
			if not player or player == LocalPlayer or not player.Character then
				for _, obj in pairs(esp) do
					if type(obj) == "table" or type(obj) == "userdata" then
						pcall(function()
							if obj.ClassName == "Highlight" then
								obj.Enabled = false
							else
								obj.Visible = false
							end
						end)
					end
				end
				return
			end
			
			local char = player.Character
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local head = char:FindFirstChild("Head")
			local hum = char:FindFirstChildOfClass("Humanoid")
			
			if not hrp or not head or not hum or hum.Health <= 0 then
				for _, obj in pairs(esp) do
					if type(obj) == "table" or type(obj) == "userdata" then
						pcall(function()
							if obj.ClassName == "Highlight" then
								obj.Enabled = false
							else
								obj.Visible = false
							end
						end)
					end
				end
				return
			end
			
			local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
			local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
			
			if not headVis or headPos.Z <= 0 then
				for _, obj in pairs(esp) do
					if type(obj) == "table" or type(obj) == "userdata" then
						pcall(function()
							if obj.ClassName == "Highlight" then
								obj.Enabled = false
							else
								obj.Visible = false
							end
						end)
					end
				end
				return
			end
			
			local color = CFG.ESPColor
			if CFG.TeamCheck and player.Team == LocalPlayer.Team then
				color = CFG.ESPTeamColor
			end
			
			if CFG.ESP then
				local height = math.abs(headPos.Y - legPos.Y)
				local width = height / 2
				
				local topLeft = Vector2.new(headPos.X - width / 2, headPos.Y)
				local topRight = Vector2.new(headPos.X + width / 2, headPos.Y)
				local bottomLeft = Vector2.new(legPos.X - width / 2, legPos.Y)
				local bottomRight = Vector2.new(legPos.X + width / 2, legPos.Y)
				
				esp.TopLine.From = topLeft
				esp.TopLine.To = topRight
				esp.TopLine.Color = color
				esp.TopLine.Visible = true
				
				esp.BottomLine.From = bottomLeft
				esp.BottomLine.To = bottomRight
				esp.BottomLine.Color = color
				esp.BottomLine.Visible = true
				
				esp.LeftLine.From = topLeft
				esp.LeftLine.To = bottomLeft
				esp.LeftLine.Color = color
				esp.LeftLine.Visible = true
				
				esp.RightLine.From = topRight
				esp.RightLine.To = bottomRight
				esp.RightLine.Color = color
				esp.RightLine.Visible = true
				
				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, 0)
				esp.Tracer.To = Vector2.new(headPos.X, headPos.Y)
				esp.Tracer.Color = color
				esp.Tracer.Visible = true
				
				if CFG.ShowName then
					esp.Name.Text = player.Name
					esp.Name.Position = Vector2.new(headPos.X, topLeft.Y - 18)
					esp.Name.Visible = true
				else
					esp.Name.Visible = false
				end
				
				if CFG.ShowHealth then
					local healthPercent = hum.Health / hum.MaxHealth
					esp.Health.Text = "HP: " .. math.floor(hum.Health)
					esp.Health.Position = Vector2.new(headPos.X, bottomLeft.Y + 3)
					esp.Health.Color = Color3.fromHSV(healthPercent * 0.33, 1, 1)
					esp.Health.Visible = true
				else
					esp.Health.Visible = false
				end
				
				if CFG.ShowDistance then
					if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
						esp.Distance.Text = math.floor(distance) .. "m"
						esp.Distance.Position = Vector2.new(headPos.X, bottomLeft.Y + 18)
						esp.Distance.Visible = true
					else
						esp.Distance.Visible = false
					end
				else
					esp.Distance.Visible = false
				end
			else
				esp.TopLine.Visible = false
				esp.BottomLine.Visible = false
				esp.LeftLine.Visible = false
				esp.RightLine.Visible = false
				esp.Tracer.Visible = false
				esp.Name.Visible = false
				esp.Health.Visible = false
				esp.Distance.Visible = false
			end
			
			-- SKELETON ESP
			if CFG.Skeleton then
				local function GetPos(partName)
					local part = char:FindFirstChild(partName)
					if part then
						local pos, vis = Camera:WorldToViewportPoint(part.Position)
						if vis and pos.Z > 0 then
							return Vector2.new(pos.X, pos.Y)
						end
					end
					return nil
				end
				
				local positions = {
					Head = GetPos("Head"),
					UpperTorso = GetPos("UpperTorso") or GetPos("Torso"),
					LowerTorso = GetPos("LowerTorso") or GetPos("Torso"),
					LeftUpperArm = GetPos("LeftUpperArm") or GetPos("Left Arm"),
					RightUpperArm = GetPos("RightUpperArm") or GetPos("Right Arm"),
					LeftLowerArm = GetPos("LeftLowerArm") or GetPos("Left Arm"),
					RightLowerArm = GetPos("RightLowerArm") or GetPos("Right Arm"),
					LeftHand = GetPos("LeftHand") or GetPos("Left Arm"),
					RightHand = GetPos("RightHand") or GetPos("Right Arm"),
					LeftUpperLeg = GetPos("LeftUpperLeg") or GetPos("Left Leg"),
					RightUpperLeg = GetPos("RightUpperLeg") or GetPos("Right Leg"),
					LeftLowerLeg = GetPos("LeftLowerLeg") or GetPos("Left Leg"),
					RightLowerLeg = GetPos("RightLowerLeg") or GetPos("Right Leg"),
					LeftFoot = GetPos("LeftFoot") or GetPos("Left Leg"),
					RightFoot = GetPos("RightFoot") or GetPos("Right Leg")
				}
				
				local skeletonColor = CFG.SkeletonColor
				
				if positions.Head and positions.UpperTorso then
					esp.Head_Neck.From = positions.Head
					esp.Head_Neck.To = positions.UpperTorso
					esp.Head_Neck.Color = skeletonColor
					esp.Head_Neck.Visible = true
				else
					esp.Head_Neck.Visible = false
				end
				
				if positions.UpperTorso and positions.LowerTorso then
					esp.Neck_Torso.From = positions.UpperTorso
					esp.Neck_Torso.To = positions.LowerTorso
					esp.Neck_Torso.Color = skeletonColor
					esp.Neck_Torso.Visible = true
				else
					esp.Neck_Torso.Visible = false
				end
				
				if positions.UpperTorso and positions.LeftUpperArm then
					esp.Torso_LeftArm.From = positions.UpperTorso
					esp.Torso_LeftArm.To = positions.LeftUpperArm
					esp.Torso_LeftArm.Color = skeletonColor
					esp.Torso_LeftArm.Visible = true
				else
					esp.Torso_LeftArm.Visible = false
				end
				
				if positions.UpperTorso and positions.RightUpperArm then
					esp.Torso_RightArm.From = positions.UpperTorso
					esp.Torso_RightArm.To = positions.RightUpperArm
					esp.Torso_RightArm.Color = skeletonColor
					esp.Torso_RightArm.Visible = true
				else
					esp.Torso_RightArm.Visible = false
				end
				
				if positions.LowerTorso and positions.LeftUpperLeg then
					esp.Torso_LeftLeg.From = positions.LowerTorso
					esp.Torso_LeftLeg.To = positions.LeftUpperLeg
					esp.Torso_LeftLeg.Color = skeletonColor
					esp.Torso_LeftLeg.Visible = true
				else
					esp.Torso_LeftLeg.Visible = false
				end
				
				if positions.LowerTorso and positions.RightUpperLeg then
					esp.Torso_RightLeg.From = positions.LowerTorso
					esp.Torso_RightLeg.To = positions.RightUpperLeg
					esp.Torso_RightLeg.Color = skeletonColor
					esp.Torso_RightLeg.Visible = true
				else
					esp.Torso_RightLeg.Visible = false
				end
				
				if positions.LeftLowerArm and positions.LeftHand then
					esp.LeftArm_LeftHand.From = positions.LeftLowerArm
					esp.LeftArm_LeftHand.To = positions.LeftHand
					esp.LeftArm_LeftHand.Color = skeletonColor
					esp.LeftArm_LeftHand.Visible = true
				else
					esp.LeftArm_LeftHand.Visible = false
				end
				
				if positions.RightLowerArm and positions.RightHand then
					esp.RightArm_RightHand.From = positions.RightLowerArm
					esp.RightArm_RightHand.To = positions.RightHand
					esp.RightArm_RightHand.Color = skeletonColor
					esp.RightArm_RightHand.Visible = true
				else
					esp.RightArm_RightHand.Visible = false
				end
				
				if positions.LeftLowerLeg and positions.LeftFoot then
					esp.LeftLeg_LeftFoot.From = positions.LeftLowerLeg
					esp.LeftLeg_LeftFoot.To = positions.LeftFoot
					esp.LeftLeg_LeftFoot.Color = skeletonColor
					esp.LeftLeg_LeftFoot.Visible = true
				else
					esp.LeftLeg_LeftFoot.Visible = false
				end
				
				if positions.RightLowerLeg and positions.RightFoot then
					esp.RightLeg_RightFoot.From = positions.RightLowerLeg
					esp.RightLeg_RightFoot.To = positions.RightFoot
					esp.RightLeg_RightFoot.Color = skeletonColor
					esp.RightLeg_RightFoot.Visible = true
				else
					esp.RightLeg_RightFoot.Visible = false
				end
			else
				esp.Head_Neck.Visible = false
				esp.Neck_Torso.Visible = false
				esp.Torso_LeftArm.Visible = false
				esp.Torso_RightArm.Visible = false
				esp.Torso_LeftLeg.Visible = false
				esp.Torso_RightLeg.Visible = false
				esp.LeftArm_LeftHand.Visible = false
				esp.RightArm_RightHand.Visible = false
				esp.LeftLeg_LeftFoot.Visible = false
				esp.RightLeg_RightFoot.Visible = false
			end
			
			-- 3D HIGHLIGHT
			if CFG.Highlight then
				if esp.Highlight.Parent ~= char then
					esp.Highlight.Parent = char
				end
				esp.Highlight.Enabled = true
				esp.Highlight.FillColor = CFG.HighlightColor
				esp.Highlight.OutlineColor = CFG.HighlightColor
			else
				esp.Highlight.Enabled = false
			end
		end)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	CreateESP(player)
end

Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

--==================================================
-- AIMLOCK HELPERS
--==================================================
local function IsVisible(part)
	if not CFG.WallCheck then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
	local result = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
	return result == nil
end

local function GetTargetPart(char)
	if CFG.Target == "Head" then
		return char:FindFirstChild("Head")
	elseif CFG.Target == "Body" then
		return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	else
		local leftLeg = char:FindFirstChild("LeftFoot") or char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Leg")
		local rightLeg = char:FindFirstChild("RightFoot") or char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Leg")
		return leftLeg or rightLeg or char:FindFirstChild("HumanoidRootPart")
	end
end

local function IsValidTarget(model)
	if not model or not model.Parent then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local targetPart = GetTargetPart(model)
	
	if not hum or hum.Health <= 0 or not targetPart then return false end
	
	local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
	if not onScreen then return false end
	
	local dist = (Vector2.new(pos.X, pos.Y) - Camera.ViewportSize / 2).Magnitude
	if dist > CFG.FOVRadius then return false end
	
	if not IsVisible(targetPart) then return false end
	
	return true
end

local function FindTarget()
	local best, shortest = nil, math.huge
	local center = Camera.ViewportSize / 2
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			if CFG.TeamCheck and player.Team == LocalPlayer.Team then continue end
			
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			local targetPart = GetTargetPart(player.Character)
			
			if hum and hum.Health > 0 and targetPart then
				local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local d = (Vector2.new(pos.X, pos.Y) - center).Magnitude
					if d < CFG.FOVRadius and d < shortest and IsVisible(targetPart) then
						shortest = d
						best = player.Character
					end
				end
			end
		end
	end
	
	return best
end

--==================================================
-- RGB RAINBOW EFFECT
--==================================================
local hue = 0
task.spawn(function()
	while task.wait(0.03) do
		if CFG.RGBEnabled then
			hue = (hue + 0.01) % 1
			local rainbow = Color3.fromHSV(hue, 1, 1)
			
			if FOVCircle then
				if FOVCircle.Color then
					FOVCircle.Color = rainbow
				else
					local stroke = FOVCircle:FindFirstChild("UIStroke")
					if stroke then stroke.Color = rainbow end
				end
			end
			
			MainStroke.Color = rainbow
			ToggleStroke.Color = rainbow
		end
	end
end)

--==================================================
-- MAIN LOOP
--==================================================
RunService.RenderStepped:Connect(function(dt)
	if not CFG.ScriptEnabled then
		if FOVCircle then
			FOVCircle.Visible = false
		end
		if LockIndicator then
			LockIndicator.Visible = false
		end
		if TargetInfoFrame then
			TargetInfoFrame.Visible = false
		end
		return
	end
	
	if FOVCircle then
		pcall(function()
			local centerX = Camera.ViewportSize.X / 2
			local centerY = Camera.ViewportSize.Y / 2
			
			if FOVCircle.Position then
				FOVCircle.Position = Vector2.new(centerX, centerY)
				
				local currentFOV = CFG.FOVRadius
				if CFG.DynamicFOV and LockedTarget then
					currentFOV = CFG.LockedFOV
				end
				
				FOVCircle.Radius = currentFOV
				FOVCircle.Visible = CFG.FOVEnabled
				if not CFG.RGBEnabled then
					FOVCircle.Color = CFG.FOVColor
				end
			end
			
			if FOVCircle.Size then
				local diameter = CFG.FOVRadius * 2
				FOVCircle.Size = UDim2.fromOffset(diameter, diameter)
				local stroke = FOVCircle:FindFirstChild("UIStroke")
				if stroke then
					stroke.Transparency = CFG.FOVEnabled and 0 or 1
					if not CFG.RGBEnabled then
						stroke.Color = CFG.FOVColor
					end
				end
			end
		end)
	end
	
	UpdateESP()
	
	if not CFG.Aimlock then
		LockedTarget = nil
		
		if TargetInfoFrame then
			TargetInfoFrame.Visible = false
		end
		
		if LockIndicator then
			LockIndicator.Visible = false
		end
		
		return
	end
	
	Camera.CameraType = Enum.CameraType.Custom
	
	if not IsValidTarget(LockedTarget) then
		LockedTarget = FindTarget()
	end
	
	if LockedTarget then
		local targetPart = GetTargetPart(LockedTarget)
		if targetPart then
			local camPos = Camera.CFrame.Position
			local targetPos = targetPart.Position + CFG.HeadOffset
			
			if CFG.Prediction then
				local targetHRP = LockedTarget:FindFirstChild("HumanoidRootPart")
				if targetHRP then
					local velocity = targetHRP.AssemblyLinearVelocity or targetHRP.Velocity
					targetPos = targetPos + (velocity * CFG.PredictionAmount)
				end
			end
			
			local desired = CFrame.new(camPos, targetPos)
			local alpha = 1 - math.exp(-CFG.Smooth * dt)
			Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
			
			if CFG.AutoFire then
				pcall(function()
					mouse1press()
					task.wait()
					mouse1release()
				end)
			end
			
			if CFG.ShowTargetInfo and TargetInfoFrame then
				local player = Players:GetPlayerFromCharacter(LockedTarget)
				if player then
					local hum = LockedTarget:FindFirstChildOfClass("Humanoid")
					local hrp = LockedTarget:FindFirstChild("HumanoidRootPart")
					
					if hum and hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
						TargetNameLabel.Text = "🎯 " .. player.Name
						
						local healthPercent = hum.Health / hum.MaxHealth
						TargetHealthLabel.Text = "❤️ HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
						TargetHealthLabel.TextColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
						
						local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
						TargetDistanceLabel.Text = "📏 Distance: " .. math.floor(distance) .. "m"
						
						TargetInfoFrame.Visible = true
						
						if LockIndicator then
							local headPos, headVis = Camera:WorldToViewportPoint(targetPart.Position)
							if headVis then
								LockIndicator.Position = Vector2.new(headPos.X, headPos.Y)
								LockIndicator.Visible = true
							else
								LockIndicator.Visible = false
							end
						end
					else
						TargetInfoFrame.Visible = false
						if LockIndicator then LockIndicator.Visible = false end
					end
				else
					TargetInfoFrame.Visible = false
					if LockIndicator then LockIndicator.Visible = false end
				end
			else
				TargetInfoFrame.Visible = false
				if LockIndicator then LockIndicator.Visible = false end
			end
		end
	else
		if TargetInfoFrame then
			TargetInfoFrame.Visible = false
		end
		if LockIndicator then
			LockIndicator.Visible = false
		end
	end
	
	if (not CFG.Aimlock or not CFG.ShowTargetInfo) and TargetInfoFrame then
		TargetInfoFrame.Visible = false
	end
	
	if not CFG.Aimlock and LockIndicator then
		LockIndicator.Visible = false
	end
end)

Notify("Welcome!", "Aimlock Pro V3.0 loaded!", 5, false)

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎯 AIMLOCK PRO V3.0 LOADED!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ All Functions Working")
print("✅ Notification System Active")
print("✅ ESP Objects Initialized")
print("✅ Lock Indicator Fixed")
print("✅ Toggle Button Fixed")
print("✅ Mobile Support Active")
print("✅ Minimalist GUI Loaded")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
