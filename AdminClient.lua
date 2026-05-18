--------------------------------------------------------------------------------
-- AdminClient (LocalScript) - PREMIUM EDITION v2.0
-- Ultra-Clean Admin Panel | Glass Morphism | Spring Animations | Sidebar Nav
-- Production-ready, sale-optimized. Zero compromises.
--------------------------------------------------------------------------------

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SERVICES
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DESIGN SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local THEME = {
	-- Background Layers (true dark, layered depth)
	bg = Color3.fromRGB(10, 10, 14),
	bgElevated = Color3.fromRGB(14, 15, 20),
	surface = Color3.fromRGB(20, 22, 30),
	surfaceHover = Color3.fromRGB(28, 31, 42),
	surfaceActive = Color3.fromRGB(36, 40, 54),
	surfaceBright = Color3.fromRGB(44, 48, 64),

	-- Accent (mutable at runtime)
	accent = Color3.fromRGB(99, 102, 241),
	accentHover = Color3.fromRGB(129, 132, 255),
	accentDim = Color3.fromRGB(55, 56, 130),
	accentGhost = Color3.fromRGB(99, 102, 241), -- used at high transparency

	-- Text Hierarchy
	text = Color3.fromRGB(245, 247, 255),
	textSub = Color3.fromRGB(160, 168, 190),
	textMuted = Color3.fromRGB(90, 98, 120),
	textOnAccent = Color3.fromRGB(255, 255, 255),

	-- Semantic Colors
	success = Color3.fromRGB(34, 197, 94),
	successDim = Color3.fromRGB(15, 60, 35),
	danger = Color3.fromRGB(239, 68, 68),
	dangerDim = Color3.fromRGB(70, 20, 20),
	warning = Color3.fromRGB(234, 179, 8),
	warningDim = Color3.fromRGB(60, 50, 8),
	info = Color3.fromRGB(59, 130, 246),
	infoDim = Color3.fromRGB(18, 38, 75),

	-- Borders
	border = Color3.fromRGB(40, 44, 60),
	borderSubtle = Color3.fromRGB(30, 33, 46),

	-- Category Accents
	catModeration = Color3.fromRGB(239, 68, 68),
	catPlayer = Color3.fromRGB(59, 130, 246),
	catMovement = Color3.fromRGB(34, 197, 94),
	catFun = Color3.fromRGB(234, 179, 8),
	catServer = Color3.fromRGB(168, 85, 247),
}

local FONT = {
	bold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	semi = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
	medium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	regular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
	mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Medium),
}

local SIZE = {
	panelW = 640,
	panelH = 500,
	sidebar = 54,
	header = 46,
	radius = 12,
	radiusMd = 8,
	radiusSm = 6,
	radiusXs = 4,
	pad = 16,
	padSm = 10,
	padXs = 6,
	btnH = 32,
	inputH = 36,
	rowH = 42,
	toast = 290,
}

local CATEGORY_COLORS = {
	Moderation = THEME.catModeration,
	Player = THEME.catPlayer,
	Movement = THEME.catMovement,
	Fun = THEME.catFun,
	Server = THEME.catServer,
}

local ACCENT_PRESETS = {
	{name = "Indigo", color = Color3.fromRGB(99, 102, 241)},
	{name = "Violet", color = Color3.fromRGB(139, 92, 246)},
	{name = "Emerald", color = Color3.fromRGB(16, 185, 129)},
	{name = "Rose", color = Color3.fromRGB(244, 63, 94)},
	{name = "Amber", color = Color3.fromRGB(245, 158, 11)},
	{name = "Cyan", color = Color3.fromRGB(6, 182, 212)},
	{name = "Pink", color = Color3.fromRGB(236, 72, 153)},
	{name = "Sky", color = Color3.fromRGB(14, 165, 233)},
}

local TOGGLE_KEYS = {
	[Enum.KeyCode.LeftBracket] = true,
	[Enum.KeyCode.RightBracket] = true,
	[Enum.KeyCode.Semicolon] = true,
	[Enum.KeyCode.Quote] = true,
	[Enum.KeyCode.Backquote] = true,
	[Enum.KeyCode.Slash] = true,
	[Enum.KeyCode.F2] = true,
	[Enum.KeyCode.F4] = true,
}

local CHAT_PREFIXES = { ["!"] = true, [";"] = true }

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- STATE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local canOpenUI = false
local myRank = "guest"
local flying = false
local noclip = false
local activeTab = "Dashboard"
local panelOpen = false
local panelDragging = false
local panelDragStart, panelDragOffset = nil, nil

local FLY_SPEED = 54
local FLY_BOOST = 102
local FLY_RESPONSE = 0.14
local FLY_DRAG = 8.8

local flyAttachment, flyLinearVelocity, flyAlignOrientation = nil, nil, nil
local flyVelocitySmooth = Vector3.zero
local flyLastCamCFrame = CFrame.identity
local flySavedAutoRotate = true

local commandLogs = {}
local MAX_LOGS = 100
local announcementToken = 0
local totalCommandsRun = 0

local collapsedCategories = {}
local playerRows = {}
local accentElements = {}
local commandHistory = {}
local historyIndex = 0
local MAX_HISTORY = 30
local quickBarOpen = false

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMAND REGISTRY
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local COMMANDS = {
	-- Moderation
	{token="kick", display="kick <player> <reason>", desc="Kick a player", params={{name="Player",ph="Player name"},{name="Reason",ph="Reason",trailing=true}}, cat="Moderation"},
	{token="ban", display="ban <player> <min> <reason>", desc="Temp-ban a player", params={{name="Player",ph="Player name"},{name="Minutes",ph="60"},{name="Reason",ph="Reason",trailing=true}}, cat="Moderation"},
	{token="jail", display="jail <player> <sec>", desc="Jail a player", params={{name="Player",ph="Player name"},{name="Seconds",ph="30"}}, cat="Moderation"},
	{token="unjail", display="unjail <player>", desc="Release from jail", params={{name="Player",ph="Player name"}}, cat="Moderation"},
	{token="freeze", display="freeze <player>", desc="Freeze in place", params={{name="Player",ph="Player name"}}, cat="Moderation"},
	{token="unfreeze", display="unfreeze <player>", desc="Unfreeze player", params={{name="Player",ph="Player name"}}, cat="Moderation"},
	{token="freezeall", display="freezeall", desc="Freeze all (Admin+)", params={}, cat="Moderation"},
	{token="unfreezeall", display="unfreezeall", desc="Unfreeze all (Admin+)", params={}, cat="Moderation"},

	-- Player
	{token="rank", display="rank <player> <rank>", desc="Set player rank", params={{name="Player",ph="Player name"},{name="Rank",ph="owner/admin/staff..."}}, cat="Player"},
	{token="money", display="money <player> <amount>", desc="Give money", params={{name="Player",ph="Player name"},{name="Amount",ph="Amount"}}, cat="Player"},
	{token="namechanger", display="namechanger <player> <name>", desc="Change display name", params={{name="Player",ph="Player name"},{name="Name",ph="New name",trailing=true}}, cat="Player"},
	{token="resetname", display="resetname <player>", desc="Reset display name", params={{name="Player",ph="Player name"}}, cat="Player"},
	{token="speed", display="speed <player> <val>", desc="Set walk speed", params={{name="Player",ph="Player name"},{name="Speed",ph="16"}}, cat="Player"},
	{token="jump", display="jump <player> <val>", desc="Set jump power", params={{name="Player",ph="Player name"},{name="Jump",ph="50"}}, cat="Player"},
	{token="heal", display="heal <player>", desc="Heal to max", params={{name="Player",ph="Player name"}}, cat="Player"},
	{token="kill", display="kill <player>", desc="Kill player", params={{name="Player",ph="Player name"}}, cat="Player"},
	{token="sit", display="sit <player>", desc="Force sit", params={{name="Player",ph="Player name"}}, cat="Player"},
	{token="unsit", display="unsit <player>", desc="Force stand", params={{name="Player",ph="Player name"}}, cat="Player"},

	-- Movement
	{token="fly", display="fly", desc="Enable fly (Shift=Boost)", params={}, cat="Movement"},
	{token="unfly", display="unfly", desc="Disable fly", params={}, cat="Movement"},
	{token="noclip", display="noclip", desc="Enable noclip", params={}, cat="Movement"},
	{token="clip", display="clip", desc="Disable noclip", params={}, cat="Movement"},
	{token="bring", display="bring <player>", desc="Bring player to you", params={{name="Player",ph="Player name"}}, cat="Movement"},
	{token="to", display="to <player>", desc="Teleport to player", params={{name="Player",ph="Player name"}}, cat="Movement"},

	-- Fun
	{token="event", display="event <type>", desc="Start event (120s)", params={{name="Type",ph="tacos/brazil/dance..."}}, cat="Fun"},
	{token="hack", display="hack", desc="Destroy map (Hacker+)", params={}, cat="Fun"},
	{token="laser", display="laser", desc="Fire laser (Hacker+)", params={}, cat="Fun"},
	{token="smite", display="smite <player>", desc="Lightning strike (Admin+)", params={{name="Player",ph="Player name"}}, cat="Fun"},
	{token="nuke", display="nuke", desc="Drop nuke (Hacker+)", params={}, cat="Fun"},
	{token="meteor", display="meteor", desc="Meteor shower (Hacker+)", params={}, cat="Fun"},
	{token="snap", display="snap", desc="All chaos (Admin+)", params={}, cat="Fun"},
	{token="virus", display="virus [player/all]", desc="Fake Trojan effect", params={{name="Player",ph="all"}}, cat="Fun"},

	-- Server
	{token="shutdown", display="shutdown <reason>", desc="Shutdown server", params={{name="Reason",ph="Reason",trailing=true}}, cat="Server"},
	{token="lobbyannouncement", display="lobbyannouncement <text>", desc="Lobby announcement", params={{name="Text",ph="Message",trailing=true}}, cat="Server"},
	{token="globalannouncement", display="globalannouncement <text>", desc="Global announcement", params={{name="Text",ph="Message",trailing=true}}, cat="Server"},
	{token="lobby", display="lobby <text>", desc="Lobby announce (alias)", params={{name="Text",ph="Message",trailing=true}}, cat="Server"},
	{token="global", display="global <text>", desc="Global announce (alias)", params={{name="Text",ph="Message",trailing=true}}, cat="Server"},
	{token="monitor", display="monitor", desc="Open monitor panel", params={}, cat="Server"},
	{token="unbanid", display="unbanid <userId>", desc="Unban by user ID", params={{name="UserId",ph="User ID"}}, cat="Server"},
}

-- Build fast-lookup structures
local cmdNames = {}
local cmdLookup = {}
for _, def in ipairs(COMMANDS) do
	if not cmdLookup[def.token] then
		cmdLookup[def.token] = def
		table.insert(cmdNames, def.token)
	end
end
table.sort(cmdNames)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- REMOTE SETUP
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local remote = ReplicatedStorage:WaitForChild("AdminCommandRemote", 10)
if not remote or not remote:IsA("RemoteEvent") then return end

local monitorToggle = ReplicatedStorage:FindFirstChild("AdminMonitorToggle")
if not monitorToggle then
	monitorToggle = Instance.new("BindableEvent")
	monitorToggle.Name = "AdminMonitorToggle"
	monitorToggle.Parent = ReplicatedStorage
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UTILITIES
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function split(text)
	local out = {}
	for word in string.gmatch(text, "%S+") do table.insert(out, word) end
	return out
end

local function joinFrom(parts, i)
	local t = {}
	for idx = i, #parts do t[#t+1] = parts[idx] end
	return table.concat(t, " ")
end

local function getRoot()
	local ch = player.Character
	if not ch then return nil, nil end
	return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

local function lerp(a, b, t) return a + (b - a) * t end

local function lerpColor(c1, c2, t)
	return Color3.new(lerp(c1.R, c2.R, t), lerp(c1.G, c2.G, t), lerp(c1.B, c2.B, t))
end

local function tweenTo(obj, props, dur, style, dir)
	local tw = TweenService:Create(obj,
		TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- UI COMPONENT LIBRARY (Clean, Reusable)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local UI = {}

function UI.corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or SIZE.radiusMd)
	c.Parent = parent
	return c
end

function UI.stroke(parent, color, thick, alpha)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.border
	s.Thickness = thick or 1
	s.Transparency = alpha or 0.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

function UI.pad(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or SIZE.pad)
	p.PaddingBottom = UDim.new(0, b or SIZE.pad)
	p.PaddingLeft = UDim.new(0, l or SIZE.pad)
	p.PaddingRight = UDim.new(0, r or SIZE.pad)
	p.Parent = parent
	return p
end

function UI.list(parent, gap, dir, hAlign, vAlign)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap or 6)
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

function UI.label(p)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = p.size or UDim2.new(1, 0, 0, 18)
	l.Position = p.pos or UDim2.new(0, 0, 0, 0)
	l.AnchorPoint = p.anchor or Vector2.zero
	l.FontFace = p.font or FONT.medium
	l.TextSize = p.ts or 13
	l.TextColor3 = p.color or THEME.text
	l.TextXAlignment = p.xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = p.yAlign or Enum.TextYAlignment.Center
	l.TextTruncate = p.truncate or Enum.TextTruncate.None
	l.Text = p.text or ""
	l.RichText = p.rich or false
	l.LayoutOrder = p.order or 0
	l.TextWrapped = p.wrap or false
	if p.autoY then l.AutomaticSize = Enum.AutomaticSize.Y end
	if p.parent then l.Parent = p.parent end
	return l
end

function UI.frame(p)
	local f = Instance.new("Frame")
	f.Name = p.name or "Frame"
	f.Size = p.size or UDim2.new(1, 0, 0, 40)
	f.Position = p.pos or UDim2.new(0, 0, 0, 0)
	f.AnchorPoint = p.anchor or Vector2.zero
	f.BackgroundColor3 = p.bg or THEME.surface
	f.BackgroundTransparency = p.alpha or 0
	f.BorderSizePixel = 0
	f.LayoutOrder = p.order or 0
	f.Visible = p.visible ~= false
	f.ClipsDescendants = p.clip or false
	f.AutomaticSize = p.autoSize or Enum.AutomaticSize.None
	f.ZIndex = p.zIndex or 1
	if p.parent then f.Parent = p.parent end
	return f
end

function UI.btn(p)
	local b = Instance.new("TextButton")
	b.Name = p.name or "Btn"
	b.Size = p.size or UDim2.new(0, 80, 0, SIZE.btnH)
	b.Position = p.pos or UDim2.new(0, 0, 0, 0)
	b.AnchorPoint = p.anchor or Vector2.zero
	b.BackgroundColor3 = p.bg or THEME.accent
	b.BackgroundTransparency = p.alpha or 0
	b.FontFace = p.font or FONT.semi
	b.TextSize = p.ts or 12
	b.TextColor3 = p.textColor or THEME.textOnAccent
	b.Text = p.text or ""
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.LayoutOrder = p.order or 0
	if p.parent then b.Parent = p.parent end
	UI.corner(b, p.radius or SIZE.radiusSm)

	-- Micro-interaction: hover + press
	local normal = p.bg or THEME.accent
	local hover = p.hover or lerpColor(normal, THEME.text, 0.12)
	local press = p.press or lerpColor(normal, THEME.bg, 0.15)

	b.MouseEnter:Connect(function() tweenTo(b, {BackgroundColor3 = hover}, 0.12) end)
	b.MouseLeave:Connect(function() tweenTo(b, {BackgroundColor3 = normal}, 0.15) end)
	b.MouseButton1Down:Connect(function()
		tweenTo(b, {BackgroundColor3 = press}, 0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
	b.MouseButton1Up:Connect(function() tweenTo(b, {BackgroundColor3 = hover}, 0.1) end)

	return b
end

function UI.input(p)
	local box = Instance.new("TextBox")
	box.Name = p.name or "Input"
	box.Size = p.size or UDim2.new(1, 0, 0, SIZE.inputH)
	box.Position = p.pos or UDim2.new(0, 0, 0, 0)
	box.BackgroundColor3 = p.bg or THEME.surface
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = p.clear or false
	box.FontFace = p.font or FONT.medium
	box.TextSize = p.ts or 13
	box.TextColor3 = p.textColor or THEME.text
	box.PlaceholderText = p.placeholder or ""
	box.PlaceholderColor3 = p.phColor or THEME.textMuted
	box.Text = p.text or ""
	box.TextXAlignment = p.xAlign or Enum.TextXAlignment.Left
	box.LayoutOrder = p.order or 0
	if p.parent then box.Parent = p.parent end
	UI.corner(box, p.radius or SIZE.radiusSm)
	UI.pad(box, 0, 0, 12, 12)

	local stroke = UI.stroke(box, THEME.borderSubtle, 1, 0.65)
	box.Focused:Connect(function() tweenTo(stroke, {Color = THEME.accent, Transparency = 0.15}, 0.2) end)
	box.FocusLost:Connect(function() tweenTo(stroke, {Color = THEME.borderSubtle, Transparency = 0.65}, 0.2) end)

	return box
end

function UI.scroll(p)
	local s = Instance.new("ScrollingFrame")
	s.Name = p.name or "Scroll"
	s.Size = p.size or UDim2.new(1, 0, 1, 0)
	s.Position = p.pos or UDim2.new(0, 0, 0, 0)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = p.bar or 3
	s.ScrollBarImageColor3 = THEME.accent
	s.ScrollBarImageTransparency = 0.5
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.LayoutOrder = p.order or 0
	if p.parent then s.Parent = p.parent end
	return s
end

function UI.badge(p)
	local f = Instance.new("Frame")
	f.Size = p.size or UDim2.new(0, 56, 0, 18)
	f.BackgroundColor3 = p.bg or THEME.accentDim
	f.BackgroundTransparency = p.alpha or 0.35
	f.BorderSizePixel = 0
	if p.parent then f.Parent = p.parent end
	UI.corner(f, 4)
	local t = UI.label({text = p.text or "", font = FONT.semi, ts = 9, color = p.textColor or THEME.text, xAlign = Enum.TextXAlignment.Center, size = UDim2.new(1, 0, 1, 0), parent = f})
	return f, t
end

function UI.sep(parent, order)
	local s = Instance.new("Frame")
	s.Size = UDim2.new(1, 0, 0, 1)
	s.BackgroundColor3 = THEME.border
	s.BackgroundTransparency = 0.7
	s.BorderSizePixel = 0
	s.LayoutOrder = order or 0
	s.Parent = parent
	return s
end



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- RANK SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local RANK_ALLOWED = {helper=true, support=true, trialstaff=true, staff=true, seniorstaff=true, admin=true, owner=true, hacker=true}

local function applyRank(rankName)
	myRank = string.lower(tostring(rankName or "guest"))
	canOpenUI = RANK_ALLOWED[myRank] == true
end

local function rankColor(rank)
	local r = string.lower(tostring(rank or "guest"))
	if r == "owner" or r == "hacker" then return THEME.danger end
	if r == "admin" or r == "seniorstaff" then return THEME.warning end
	if r == "staff" or r == "trialstaff" then return THEME.accent end
	if r == "support" or r == "helper" then return THEME.success end
	return THEME.textMuted
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TOAST NOTIFICATION SYSTEM (Stacked, Auto-dismiss, Slide-in)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local toastContainer -- forward ref

local function notify(title, msg, ntype, duration)
	duration = duration or 3.5
	ntype = ntype or "info"

	if not toastContainer then
		pcall(function() StarterGui:SetCore("SendNotification", {Title=title, Text=msg, Duration=duration}) end)
		return
	end

	local styles = {
		info = {bg = THEME.infoDim, accent = THEME.info, icon = "i"},
		success = {bg = THEME.successDim, accent = THEME.success, icon = "✓"},
		warning = {bg = THEME.warningDim, accent = THEME.warning, icon = "!"},
		error = {bg = THEME.dangerDim, accent = THEME.danger, icon = "✕"},
	}
	local s = styles[ntype] or styles.info

	local toast = UI.frame({name="Toast", size=UDim2.new(1, 0, 0, 54), bg=s.bg, alpha=0.08, parent=toastContainer})
	UI.corner(toast, SIZE.radiusSm)
	UI.stroke(toast, s.accent, 1, 0.45)

	-- Left accent line
	local line = Instance.new("Frame")
	line.Size = UDim2.new(0, 2.5, 1, -10)
	line.Position = UDim2.new(0, 5, 0, 5)
	line.BackgroundColor3 = s.accent
	line.BorderSizePixel = 0
	line.Parent = toast
	UI.corner(line, 2)

	-- Icon
	UI.label({text=s.icon, font=FONT.bold, ts=14, color=s.accent, size=UDim2.new(0,20,0,20), pos=UDim2.new(0,14,0,8), xAlign=Enum.TextXAlignment.Center, parent=toast})
	-- Title
	UI.label({text=title or "", font=FONT.semi, ts=11, color=THEME.text, size=UDim2.new(1,-48,0,14), pos=UDim2.new(0,38,0,7), parent=toast})
	-- Message
	UI.label({text=msg or "", font=FONT.regular, ts=10, color=THEME.textSub, size=UDim2.new(1,-48,0,14), pos=UDim2.new(0,38,0,24), truncate=Enum.TextTruncate.AtEnd, parent=toast})

	-- Progress bar
	local prog = Instance.new("Frame")
	prog.Size = UDim2.new(1, -10, 0, 2)
	prog.Position = UDim2.new(0, 5, 1, -5)
	prog.BackgroundColor3 = s.accent
	prog.BackgroundTransparency = 0.4
	prog.BorderSizePixel = 0
	prog.Parent = toast
	UI.corner(prog, 1)

	-- Animate in
	toast.Position = UDim2.new(1, 30, 0, 0)
	toast.BackgroundTransparency = 1
	tweenTo(toast, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.08}, 0.35, Enum.EasingStyle.Back)
	tweenTo(prog, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

	-- Auto dismiss
	task.delay(duration, function()
		if not toast or not toast.Parent then return end
		local tw = tweenTo(toast, {Position = UDim2.new(1, 30, 0, 0), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw.Completed:Once(function() if toast and toast.Parent then toast:Destroy() end end)
	end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SCREEN GUI
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local screen = Instance.new("ScreenGui")
screen.Name = "AdminPanelPro"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 10
screen.Parent = playerGui

-- Toast Container (bottom-right, stacked upward)
toastContainer = UI.frame({name="Toasts", size=UDim2.new(0, SIZE.toast, 0, 320), pos=UDim2.new(1, -(SIZE.toast+14), 1, -14), anchor=Vector2.new(0, 1), bg=THEME.bg, alpha=1, parent=screen})
UI.list(toastContainer, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FAB (Floating Action Button) - Toggle
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local fab = Instance.new("TextButton")
fab.Name = "FAB"
fab.Size = UDim2.new(0, 40, 0, 40)
fab.Position = UDim2.new(1, -52, 0, 12)
fab.AnchorPoint = Vector2.new(1, 0)
fab.BackgroundColor3 = THEME.surface
fab.BackgroundTransparency = 0.05
fab.Text = ""
fab.AutoButtonColor = false
fab.Visible = false
fab.ZIndex = 2
fab.Parent = screen
UI.corner(fab, 11)
local fabStroke = UI.stroke(fab, THEME.accent, 1.5, 0.6)

-- Glow ring
local fabGlow = Instance.new("Frame")
fabGlow.Size = UDim2.new(1, 6, 1, 6)
fabGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
fabGlow.AnchorPoint = Vector2.new(0.5, 0.5)
fabGlow.BackgroundTransparency = 1
fabGlow.Parent = fab
UI.corner(fabGlow, 13)
local fabGlowStroke = UI.stroke(fabGlow, THEME.accent, 2, 0.85)

local fabIcon = UI.label({text="A", font=FONT.bold, ts=16, color=THEME.accent, size=UDim2.new(1,0,1,0), xAlign=Enum.TextXAlignment.Center, parent=fab})

-- Pulse when closed
task.spawn(function()
	local up = true
	while true do
		if not panelOpen and fab.Visible then
			tweenTo(fabGlowStroke, {Transparency = up and 0.45 or 0.85}, 1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			up = not up
		end
		task.wait(1.8)
	end
end)

fab.MouseEnter:Connect(function() tweenTo(fab, {BackgroundTransparency = 0}, 0.12); tweenTo(fabStroke, {Transparency = 0.2}, 0.12) end)
fab.MouseLeave:Connect(function() if not panelOpen then tweenTo(fab, {BackgroundTransparency = 0.05}, 0.15); tweenTo(fabStroke, {Transparency = 0.6}, 0.15) end end)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- MAIN PANEL
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local panel = UI.frame({
	name = "Panel",
	size = UDim2.new(0, SIZE.panelW, 0, SIZE.panelH),
	pos = UDim2.new(0.5, 0, 0.5, 0),
	anchor = Vector2.new(0.5, 0.5),
	bg = THEME.bg,
	alpha = 0.01,
	clip = true,
	parent = screen,
})
panel.Visible = false
panel.Active = true
UI.corner(panel, SIZE.radius)
local panelStroke = UI.stroke(panel, THEME.border, 1, 0.35)

-- Subtle top gradient (glass feel)
local glassTop = Instance.new("Frame")
glassTop.Name = "GlassSheen"
glassTop.Size = UDim2.new(1, 0, 0, 100)
glassTop.BackgroundTransparency = 0.97
glassTop.BackgroundColor3 = THEME.accent
glassTop.BorderSizePixel = 0
glassTop.ZIndex = 0
glassTop.Parent = panel
UI.corner(glassTop, SIZE.radius)



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HEADER (Drag Handle + Info + Controls)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local header = UI.frame({name="Header", size=UDim2.new(1, 0, 0, SIZE.header), bg=THEME.bgElevated, alpha=0.4, parent=panel})
header.Active = true

-- Drag System
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		panelDragging = true
		panelDragStart = input.Position
		panelDragOffset = panel.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if not panelDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local d = input.Position - panelDragStart
		panel.Position = UDim2.new(panelDragOffset.X.Scale, panelDragOffset.X.Offset + d.X, panelDragOffset.Y.Scale, panelDragOffset.Y.Offset + d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then panelDragging = false end
end)

-- Logo
local logo = Instance.new("Frame")
logo.Size = UDim2.new(0, 26, 0, 26)
logo.Position = UDim2.new(0, 14, 0.5, -13)
logo.BackgroundColor3 = THEME.accent
logo.BackgroundTransparency = 0.82
logo.BorderSizePixel = 0
logo.Parent = header
UI.corner(logo, 7)
table.insert(accentElements, {obj=logo, prop="BackgroundColor3", alpha=0.82})

UI.label({text="A", font=FONT.bold, ts=13, color=THEME.accent, size=UDim2.new(1,0,1,0), xAlign=Enum.TextXAlignment.Center, parent=logo})

UI.label({text="Admin Panel", font=FONT.bold, ts=13, color=THEME.text, size=UDim2.new(0,90,1,0), pos=UDim2.new(0,48,0,0), parent=header})

-- Rank badge
local hdrBadge, hdrBadgeText = UI.badge({text=string.upper(myRank), bg=rankColor(myRank), textColor=THEME.text, alpha=0.65, size=UDim2.new(0,58,0,18), parent=header})
hdrBadge.Position = UDim2.new(0, 145, 0.5, -9)

-- Player count
local playerCountLbl = UI.label({text=tostring(#Players:GetPlayers()).." online", font=FONT.regular, ts=10, color=THEME.textSub, size=UDim2.new(0,65,1,0), pos=UDim2.new(0,210,0,0), parent=header})

-- Window controls
local closeBtn = UI.btn({name="Close", size=UDim2.new(0,28,0,28), pos=UDim2.new(1,-38,0.5,-14), bg=THEME.surface, hover=THEME.danger, textColor=THEME.textSub, text="×", ts=18, font=FONT.medium, radius=7, parent=header})
local minBtn = UI.btn({name="Min", size=UDim2.new(0,28,0,28), pos=UDim2.new(1,-72,0.5,-14), bg=THEME.surface, hover=THEME.surfaceHover, textColor=THEME.textSub, text="—", ts=12, font=FONT.medium, radius=7, parent=header})

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SIDEBAR NAVIGATION
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local sidebar = UI.frame({name="Sidebar", size=UDim2.new(0, SIZE.sidebar, 1, -SIZE.header), pos=UDim2.new(0, 0, 0, SIZE.header), bg=THEME.bgElevated, alpha=0.5, parent=panel})

local TABS = {
	{name="Dashboard", icon="◆"},
	{name="Commands", icon="▶"},
	{name="Players", icon="●"},
	{name="Settings", icon="⚙"},
	{name="Logs", icon="≡"},
}

local tabBtns = {}
local tabFrames = {}

local sideLayout = UI.list(sidebar, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
sideLayout.Padding = UDim.new(0, 3)
UI.pad(sidebar, 10, 10, 0, 0)

-- Active indicator bar
local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.Size = UDim2.new(0, 3, 0, 26)
indicator.Position = UDim2.new(0, 0, 0, 12)
indicator.BackgroundColor3 = THEME.accent
indicator.BorderSizePixel = 0
indicator.ZIndex = 5
indicator.Parent = sidebar
UI.corner(indicator, 2)
table.insert(accentElements, {obj=indicator, prop="BackgroundColor3"})

for i, tab in ipairs(TABS) do
	local btn = Instance.new("TextButton")
	btn.Name = tab.name
	btn.Size = UDim2.new(0, 42, 0, 42)
	btn.BackgroundColor3 = THEME.surface
	btn.BackgroundTransparency = (tab.name == activeTab) and 0.3 or 1
	btn.Text = tab.icon
	btn.FontFace = FONT.medium
	btn.TextSize = 17
	btn.TextColor3 = (tab.name == activeTab) and THEME.accent or THEME.textMuted
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.LayoutOrder = i
	btn.Parent = sidebar
	UI.corner(btn, SIZE.radiusSm)

	-- Tooltip
	local tip = Instance.new("TextLabel")
	tip.Size = UDim2.new(0, 0, 0, 22)
	tip.AutomaticSize = Enum.AutomaticSize.X
	tip.Position = UDim2.new(1, 8, 0.5, -11)
	tip.BackgroundColor3 = THEME.surfaceBright
	tip.BackgroundTransparency = 0.05
	tip.FontFace = FONT.medium
	tip.TextSize = 10
	tip.TextColor3 = THEME.text
	tip.Text = "  "..tab.name.."  "
	tip.Visible = false
	tip.ZIndex = 20
	tip.Parent = btn
	UI.corner(tip, 4)

	btn.MouseEnter:Connect(function()
		tip.Visible = true
		if tab.name ~= activeTab then tweenTo(btn, {BackgroundTransparency = 0.45, TextColor3 = THEME.textSub}, 0.1) end
	end)
	btn.MouseLeave:Connect(function()
		tip.Visible = false
		if tab.name ~= activeTab then tweenTo(btn, {BackgroundTransparency = 1, TextColor3 = THEME.textMuted}, 0.12) end
	end)

	tabBtns[tab.name] = btn
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CONTENT AREA + TAB FRAMES
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local content = UI.frame({name="Content", size=UDim2.new(1, -SIZE.sidebar, 1, -SIZE.header), pos=UDim2.new(0, SIZE.sidebar, 0, SIZE.header), bg=THEME.bg, alpha=1, clip=true, parent=panel})

for _, tab in ipairs(TABS) do
	local f = UI.frame({name=tab.name, size=UDim2.new(1,0,1,0), bg=THEME.bg, alpha=1, parent=content})
	f.Visible = (tab.name == activeTab)
	tabFrames[tab.name] = f
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB SWITCHING (Smooth Slide Animation)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function tabIndex(name)
	for i, t in ipairs(TABS) do if t.name == name then return i end end
	return 1
end

local function switchTab(name)
	if name == activeTab then return end
	local oldIdx, newIdx = tabIndex(activeTab), tabIndex(name)
	local dir = (newIdx > oldIdx) and 1 or -1

	-- Old button → dim
	local oldBtn = tabBtns[activeTab]
	if oldBtn then tweenTo(oldBtn, {BackgroundTransparency = 1, TextColor3 = THEME.textMuted}, 0.2) end

	-- Old frame → slide out
	local oldF = tabFrames[activeTab]
	if oldF then
		tweenTo(oldF, {Position = UDim2.new(-dir * 0.08, 0, 0, 0)}, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.18, function() if oldF then oldF.Visible = false; oldF.Position = UDim2.new(0,0,0,0) end end)
	end

	activeTab = name

	-- New button → active
	local newBtn = tabBtns[name]
	if newBtn then tweenTo(newBtn, {BackgroundTransparency = 0.3, TextColor3 = THEME.accent}, 0.2) end

	-- Indicator slide
	local btnPos = newBtn and newBtn.AbsolutePosition or Vector2.zero
	local sidePos = sidebar.AbsolutePosition
	local relY = btnPos.Y - sidePos.Y + 8
	tweenTo(indicator, {Position = UDim2.new(0, 0, 0, relY)}, 0.3, Enum.EasingStyle.Quint)

	-- New frame → slide in
	local newF = tabFrames[name]
	if newF then
		newF.Position = UDim2.new(dir * 0.08, 0, 0, 0)
		newF.Visible = true
		tweenTo(newF, {Position = UDim2.new(0,0,0,0)}, 0.3, Enum.EasingStyle.Quint)
	end
end

for _, tab in ipairs(TABS) do
	tabBtns[tab.name].MouseButton1Click:Connect(function() switchTab(tab.name) end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PANEL OPEN / CLOSE
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function openPanel()
	if panelOpen then return end
	panelOpen = true
	panel.Visible = true
	panel.Size = UDim2.new(0, SIZE.panelW * 0.93, 0, SIZE.panelH * 0.93)
	panel.BackgroundTransparency = 0.6
	tweenTo(panel, {Size = UDim2.new(0, SIZE.panelW, 0, SIZE.panelH), BackgroundTransparency = 0.01}, 0.35, Enum.EasingStyle.Back)
	tweenTo(panelStroke, {Transparency = 0.35}, 0.35)
	tweenTo(fab, {BackgroundColor3 = THEME.accent, BackgroundTransparency = 0}, 0.2)
	tweenTo(fabIcon, {TextColor3 = THEME.textOnAccent}, 0.2)
end

local function closePanel()
	if not panelOpen then return end
	panelOpen = false
	local tw = tweenTo(panel, {Size = UDim2.new(0, SIZE.panelW*0.96, 0, SIZE.panelH*0.96), BackgroundTransparency = 0.7}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw.Completed:Once(function() panel.Visible = false; panel.Position = UDim2.new(0.5,0,0.5,0) end)
	tweenTo(fab, {BackgroundColor3 = THEME.surface, BackgroundTransparency = 0.05}, 0.2)
	tweenTo(fabIcon, {TextColor3 = THEME.accent}, 0.2)
end

local function togglePanel() if panelOpen then closePanel() else openPanel() end end

fab.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(closePanel)
minBtn.MouseButton1Click:Connect(closePanel)



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMAND MODAL (Backdrop + Scale Animation)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local backdrop = Instance.new("TextButton")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.Text = ""
backdrop.AutoButtonColor = false
backdrop.Visible = false
backdrop.ZIndex = 50
backdrop.Parent = screen

local modal = UI.frame({name="Modal", size=UDim2.new(0,380,0,0), pos=UDim2.new(0.5,0,0.5,0), anchor=Vector2.new(0.5,0.5), bg=THEME.bgElevated, autoSize=Enum.AutomaticSize.Y, parent=screen, zIndex=55})
modal.Visible = false
modal.Active = true
UI.corner(modal, SIZE.radius)
UI.stroke(modal, THEME.border, 1, 0.35)
UI.pad(modal, 20, 20, 20, 20)
UI.list(modal, 12)

local modalTitle = UI.label({text="", font=FONT.bold, ts=14, color=THEME.text, size=UDim2.new(1,0,0,20), parent=modal, order=1})
local modalDesc = UI.label({text="", font=FONT.regular, ts=11, color=THEME.textSub, size=UDim2.new(1,0,0,14), parent=modal, order=2})

local modalFields = UI.frame({name="Fields", size=UDim2.new(1,0,0,0), bg=THEME.bg, alpha=1, autoSize=Enum.AutomaticSize.Y, parent=modal, order=3})
UI.list(modalFields, 10)

local modalBtnRow = UI.frame({name="BtnRow", size=UDim2.new(1,0,0,34), bg=THEME.bg, alpha=1, parent=modal, order=4})

local modalCancel = UI.btn({name="Cancel", size=UDim2.new(0,85,0,30), pos=UDim2.new(1,-192,0,2), bg=THEME.surface, hover=THEME.surfaceHover, textColor=THEME.textSub, text="Cancel", ts=11, radius=6, parent=modalBtnRow})
local modalExec = UI.btn({name="Execute", size=UDim2.new(0,98,0,30), pos=UDim2.new(1,-98,0,2), bg=THEME.accent, textColor=THEME.textOnAccent, text="Execute", ts=11, font=FONT.semi, radius=6, parent=modalBtnRow})
table.insert(accentElements, {obj=modalExec, prop="BackgroundColor3"})

local currentModalCmd = nil
local modalInputs = {}

local function closeModal()
	currentModalCmd = nil
	modalInputs = {}
	tweenTo(backdrop, {BackgroundTransparency = 1}, 0.2)
	tweenTo(modal, {BackgroundTransparency = 0.7}, 0.15)
	task.delay(0.2, function()
		backdrop.Visible = false
		modal.Visible = false
		modal.BackgroundTransparency = 0
		for _, c in ipairs(modalFields:GetChildren()) do if c.Name == "Field" then c:Destroy() end end
	end)
end

local function buildModalText()
	local parts = {}
	for _, inp in ipairs(modalInputs) do
		local v = inp.Text ~= "" and inp.Text or inp.PlaceholderText
		if v ~= "" then parts[#parts+1] = v end
	end
	return currentModalCmd.token .. (next(parts) and " " .. table.concat(parts, " ") or "")
end

local function openModal(def, prefill)
	currentModalCmd = def
	modalTitle.Text = def.display
	modalDesc.Text = def.desc or ""
	for _, c in ipairs(modalFields:GetChildren()) do if c.Name == "Field" then c:Destroy() end end
	modalInputs = {}

	for idx, param in ipairs(def.params) do
		local row = UI.frame({name="Field", size=UDim2.new(1,0,0,52), bg=THEME.bg, alpha=1, order=idx, parent=modalFields})
		UI.label({text=param.name, font=FONT.medium, ts=10, color=THEME.textMuted, size=UDim2.new(1,0,0,12), parent=row})
		local inp = UI.input({size=UDim2.new(1,0,0,32), pos=UDim2.new(0,0,0,16), placeholder=param.ph or param.name, parent=row})
		if prefill and idx == 1 and param.name:lower() == "player" then inp.Text = prefill end
		table.insert(modalInputs, inp)
	end

	backdrop.Visible = true
	backdrop.BackgroundTransparency = 1
	modal.Visible = true
	modal.BackgroundTransparency = 0.6
	tweenTo(backdrop, {BackgroundTransparency = 0.5}, 0.25)
	tweenTo(modal, {BackgroundTransparency = 0}, 0.25, Enum.EasingStyle.Back)
end

backdrop.MouseButton1Click:Connect(closeModal)
modalCancel.MouseButton1Click:Connect(closeModal)
modalExec.MouseButton1Click:Connect(function()
	if not currentModalCmd then return end
	local text = buildModalText()
	closeModal()
	task.defer(function() runCommand(text) end)
end)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LOGS SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local logsScroll -- forward ref

local function addLog(text, success)
	table.insert(commandLogs, 1, {time = os.date("%H:%M:%S"), text = text, ok = success ~= false})
	if #commandLogs > MAX_LOGS then table.remove(commandLogs) end

	if not logsScroll then return end
	for _, c in ipairs(logsScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for idx, entry in ipairs(commandLogs) do
		local row = UI.frame({name="L"..idx, size=UDim2.new(1,0,0,30), bg=THEME.surface, alpha=0.7, order=idx, parent=logsScroll})
		UI.corner(row, SIZE.radiusXs)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0,5,0,5)
		dot.Position = UDim2.new(0,8,0.5,-2)
		dot.BackgroundColor3 = entry.ok and THEME.success or THEME.danger
		dot.BorderSizePixel = 0
		dot.Parent = row
		UI.corner(dot, 3)

		UI.label({text=entry.time, font=FONT.mono, ts=9, color=THEME.textMuted, size=UDim2.new(0,50,1,0), pos=UDim2.new(0,18,0,0), parent=row})
		UI.label({text=entry.text, font=FONT.medium, ts=11, color=THEME.textSub, size=UDim2.new(1,-80,1,0), pos=UDim2.new(0,72,0,0), truncate=Enum.TextTruncate.AtEnd, parent=row})
	end
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DASHBOARD TAB
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local dashFrame = tabFrames["Dashboard"]
UI.pad(dashFrame, SIZE.pad, SIZE.pad, SIZE.pad, SIZE.pad)
UI.list(dashFrame, 14)

-- Welcome Card
local welcome = UI.frame({name="Welcome", size=UDim2.new(1,0,0,72), bg=THEME.surface, alpha=0.35, order=1, parent=dashFrame})
UI.corner(welcome, SIZE.radiusMd)
UI.stroke(welcome, THEME.borderSubtle, 1, 0.7)

UI.label({text="Welcome back,", font=FONT.regular, ts=11, color=THEME.textSub, size=UDim2.new(1,-20,0,14), pos=UDim2.new(0,16,0,14), parent=welcome})
local welcomeName = UI.label({text=player.DisplayName, font=FONT.bold, ts=17, color=THEME.text, size=UDim2.new(1,-20,0,22), pos=UDim2.new(0,16,0,32), parent=welcome})

local dashBadge, dashBadgeText = UI.badge({text=string.upper(myRank), bg=rankColor(myRank), textColor=THEME.text, alpha=0.6, size=UDim2.new(0,64,0,18), parent=welcome})
dashBadge.Position = UDim2.new(1, -80, 0, 14)
dashBadge.Visible = false

-- Stats Row
local stats = UI.frame({name="Stats", size=UDim2.new(1,0,0,62), bg=THEME.bg, alpha=1, order=2, parent=dashFrame})

local function statCard(label, value, color, xOff, w)
	local card = UI.frame({name="S_"..label, size=UDim2.new(0, w or 125, 0, 56), pos=UDim2.new(0, xOff, 0, 0), bg=THEME.surface, alpha=0.4, parent=stats})
	UI.corner(card, SIZE.radiusSm)
	UI.stroke(card, THEME.borderSubtle, 1, 0.7)
	local val = UI.label({text=value, font=FONT.bold, ts=18, color=color or THEME.accent, size=UDim2.new(1,-14,0,22), pos=UDim2.new(0,10,0,8), parent=card})
	UI.label({text=label, font=FONT.regular, ts=9, color=THEME.textMuted, size=UDim2.new(1,-14,0,12), pos=UDim2.new(0,10,0,34), parent=card})
	return card, val
end

local statOnline, statOnlineVal = statCard("ONLINE", tostring(#Players:GetPlayers()), THEME.success, 0, 130)
local statCmds, statCmdsVal = statCard("COMMANDS", "0", THEME.accent, 138, 130)
local statRank, statRankVal = statCard("YOUR RANK", string.upper(myRank), rankColor(myRank), 276, 130)

-- Quick Actions
UI.label({text="Quick Actions", font=FONT.semi, ts=11, color=THEME.textSub, size=UDim2.new(1,0,0,16), order=3, parent=dashFrame})

local qaRow = UI.frame({name="QA", size=UDim2.new(1,0,0,36), bg=THEME.bg, alpha=1, order=4, parent=dashFrame})
UI.list(qaRow, 8, Enum.FillDirection.Horizontal)

local quickActions = {
	{text="Fly", cmd="fly", color=THEME.catMovement},
	{text="Noclip", cmd="noclip", color=THEME.catMovement},
	{text="Freeze All", cmd="freezeall", color=THEME.catModeration},
	{text="Unfreeze All", cmd="unfreezeall", color=THEME.catModeration},
}

for i, qa in ipairs(quickActions) do
	local btn = UI.btn({name="QA_"..qa.text, size=UDim2.new(0,92,0,30), bg=qa.color, textColor=THEME.textOnAccent, text=qa.text, ts=10, radius=6, order=i, parent=qaRow})
	btn.BackgroundTransparency = 0.2
	btn.MouseButton1Click:Connect(function() task.defer(function() runCommand(qa.cmd) end) end)
end

-- Recent Commands
UI.label({text="Recent Commands", font=FONT.semi, ts=11, color=THEME.textSub, size=UDim2.new(1,0,0,16), order=5, parent=dashFrame})

local recentFrame = UI.frame({name="Recent", size=UDim2.new(1,0,0,100), bg=THEME.surface, alpha=0.5, order=6, parent=dashFrame})
UI.corner(recentFrame, SIZE.radiusSm)
UI.pad(recentFrame, 8, 8, 8, 8)
UI.list(recentFrame, 4)

local recentEmpty = UI.label({text="No commands executed yet", font=FONT.regular, ts=10, color=THEME.textMuted, size=UDim2.new(1,0,0,80), xAlign=Enum.TextXAlignment.Center, yAlign=Enum.TextYAlignment.Center, parent=recentFrame})

-- Dynamic player count
local function updatePlayerCount()
	local count = #Players:GetPlayers()
	playerCountLbl.Text = tostring(count) .. " online"
	for _, c in ipairs(statOnline:GetChildren()) do
		if c:IsA("TextLabel") and c.TextSize == 18 then c.Text = tostring(count) break end
	end
end
Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(function() task.defer(updatePlayerCount) end)



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMANDS TAB
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local cmdFrame = tabFrames["Commands"]
UI.pad(cmdFrame, SIZE.padSm, SIZE.padSm, SIZE.pad, SIZE.pad)
UI.list(cmdFrame, 8)

-- Search
local searchRow = UI.frame({name="Search", size=UDim2.new(1,0,0,SIZE.inputH), bg=THEME.bg, alpha=1, order=1, parent=cmdFrame})
local searchBox = UI.input({size=UDim2.new(1,0,0,SIZE.inputH), placeholder="Search commands...", parent=searchRow})

-- Commands Scroll
local cmdScroll = UI.scroll({name="CmdScroll", size=UDim2.new(1,0,1,-(SIZE.inputH+14)), order=2, parent=cmdFrame})
UI.list(cmdScroll, 3)

local catOrder = {"Moderation", "Player", "Movement", "Fun", "Server"}
local cmdsByCat = {}
for _, c in ipairs(catOrder) do cmdsByCat[c] = {} end
for _, def in ipairs(COMMANDS) do
	local cat = def.cat or "Server"
	if cmdsByCat[cat] then table.insert(cmdsByCat[cat], def) end
end

local catHeaders = {}
local cmdRowElems = {}

local function buildCmdsUI()
	for _, c in ipairs(cmdScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	catHeaders = {}
	cmdRowElems = {}

	local order = 0
	for _, catName in ipairs(catOrder) do
		local cmds = cmdsByCat[catName]
		local catColor = CATEGORY_COLORS[catName] or THEME.accent
		local collapsed = collapsedCategories[catName] or false

		-- Header
		local hdr = UI.frame({name="H_"..catName, size=UDim2.new(1,0,0,30), bg=THEME.bg, alpha=1, order=order, parent=cmdScroll})
		order += 1

		local hdrBtn = Instance.new("TextButton")
		hdrBtn.Size = UDim2.new(1,0,1,0)
		hdrBtn.BackgroundTransparency = 1
		hdrBtn.Text = ""
		hdrBtn.AutoButtonColor = false
		hdrBtn.Parent = hdr

		-- Color bar
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0,3,0,16)
		bar.Position = UDim2.new(0,0,0.5,-8)
		bar.BackgroundColor3 = catColor
		bar.BorderSizePixel = 0
		bar.Parent = hdr
		UI.corner(bar, 2)

		local arrow = UI.label({text=collapsed and "+" or "−", font=FONT.medium, ts=13, color=THEME.textMuted, size=UDim2.new(0,14,1,0), pos=UDim2.new(0,10,0,0), xAlign=Enum.TextXAlignment.Center, parent=hdr})
		UI.label({text=catName, font=FONT.semi, ts=11, color=catColor, size=UDim2.new(0,90,1,0), pos=UDim2.new(0,26,0,0), parent=hdr})
		UI.label({text=tostring(#cmds), font=FONT.regular, ts=9, color=THEME.textMuted, size=UDim2.new(0,20,1,0), pos=UDim2.new(1,-24,0,0), xAlign=Enum.TextXAlignment.Right, parent=hdr})

		catHeaders[catName] = {frame=hdr, arrow=arrow, rows={}}

		-- Command rows
		for _, def in ipairs(cmds) do
			local row = UI.frame({name="C_"..def.token, size=UDim2.new(1,0,0,36), bg=THEME.surface, alpha=0.7, order=order, parent=cmdScroll})
			row.Visible = not collapsed
			UI.corner(row, SIZE.radiusSm)
			order += 1

			row.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement then tweenTo(row, {BackgroundTransparency = 0.3}, 0.08) end end)
			row.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement then tweenTo(row, {BackgroundTransparency = 0.7}, 0.1) end end)

			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0,4,0,4)
			dot.Position = UDim2.new(0,8,0.5,-2)
			dot.BackgroundColor3 = catColor
			dot.BorderSizePixel = 0
			dot.Parent = row
			UI.corner(dot, 2)

			UI.label({text=def.token, font=FONT.semi, ts=11, color=THEME.text, size=UDim2.new(0,90,1,0), pos=UDim2.new(0,18,0,0), parent=row})
			UI.label({text=def.desc, font=FONT.regular, ts=10, color=THEME.textMuted, size=UDim2.new(1,-185,1,0), pos=UDim2.new(0,110,0,0), truncate=Enum.TextTruncate.AtEnd, parent=row})

			local runBtn = UI.btn({name="Run", size=UDim2.new(0,48,0,22), pos=UDim2.new(1,-56,0.5,-11), bg=THEME.surface, hover=THEME.accent, textColor=THEME.textSub, text="Run", ts=10, radius=5, parent=row})
			UI.stroke(runBtn, THEME.borderSubtle, 1, 0.7)

			runBtn.MouseButton1Click:Connect(function()
				if #def.params == 0 then
					task.defer(function() runCommand(def.token) end)
				else
					openModal(def)
				end
			end)

			table.insert(catHeaders[catName].rows, row)
			table.insert(cmdRowElems, {frame=row, def=def})
		end

		hdrBtn.MouseButton1Click:Connect(function()
			collapsedCategories[catName] = not collapsedCategories[catName]
			arrow.Text = collapsedCategories[catName] and "+" or "−"
			for _, r in ipairs(catHeaders[catName].rows) do r.Visible = not collapsedCategories[catName] end
		end)
	end
end
buildCmdsUI()

-- Search filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(searchBox.Text or "")
	if q == "" then
		for catName, data in pairs(catHeaders) do
			data.frame.Visible = true
			for _, r in ipairs(data.rows) do r.Visible = not (collapsedCategories[catName] or false) end
		end
		return
	end
	for _, data in pairs(catHeaders) do
		local any = false
		for _, r in ipairs(data.rows) do
			local def
			for _, e in ipairs(cmdRowElems) do if e.frame == r then def = e.def break end end
			if def then
				local m = string.find(def.token, q, 1, true) or string.find(string.lower(def.desc), q, 1, true)
				r.Visible = m ~= nil
				if m then any = true end
			end
		end
		data.frame.Visible = any
	end
end)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- PLAYERS TAB
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local plrFrame = tabFrames["Players"]
UI.pad(plrFrame, SIZE.padSm, SIZE.padSm, SIZE.pad, SIZE.pad)

local plrScroll = UI.scroll({name="PlrScroll", size=UDim2.new(1,0,1,0), parent=plrFrame})
UI.list(plrScroll, 6)

local function addPlayerRow(target)
	if playerRows[target.UserId] then return end

	local row = UI.frame({name="P_"..target.UserId, size=UDim2.new(1,0,0,54), bg=THEME.surface, alpha=0.5, parent=plrScroll})
	UI.corner(row, SIZE.radiusMd)

	row.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement then tweenTo(row, {BackgroundTransparency = 0.2}, 0.1) end end)
	row.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement then tweenTo(row, {BackgroundTransparency = 0.5}, 0.12) end end)

	-- Avatar
	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(0,36,0,36)
	avatar.Position = UDim2.new(0,10,0.5,-18)
	avatar.BackgroundColor3 = THEME.surfaceHover
	avatar.BorderSizePixel = 0
	avatar.Image = ""
	avatar.Parent = row
	UI.corner(avatar, 18)

	task.spawn(function()
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		if ok and url and avatar.Parent then avatar.Image = url end
	end)

	UI.label({text=target.DisplayName, font=FONT.semi, ts=12, color=THEME.text, size=UDim2.new(0,110,0,16), pos=UDim2.new(0,54,0,10), truncate=Enum.TextTruncate.AtEnd, parent=row})
	UI.label({text="@"..target.Name, font=FONT.regular, ts=9, color=THEME.textMuted, size=UDim2.new(0,110,0,12), pos=UDim2.new(0,54,0,28), truncate=Enum.TextTruncate.AtEnd, parent=row})

	-- Quick actions
	local acts = {
		{t="K", c=THEME.danger, cmd="kick"},
		{t="B", c=THEME.danger, cmd="ban"},
		{t="→", c=THEME.accent, cmd="to"},
		{t="←", c=THEME.accent, cmd="bring"},
		{t="❄", c=THEME.info, cmd="freeze"},
	}
	for i, a in ipairs(acts) do
		local ab = UI.btn({size=UDim2.new(0,26,0,26), pos=UDim2.new(1, -34*(6-i), 0.5, -13), bg=a.c, textColor=THEME.textOnAccent, text=a.t, ts=11, radius=6, parent=row})
		ab.BackgroundTransparency = 0.7
		ab.MouseEnter:Connect(function() tweenTo(ab, {BackgroundTransparency = 0.15}, 0.1) end)
		ab.MouseLeave:Connect(function() tweenTo(ab, {BackgroundTransparency = 0.7}, 0.12) end)
		ab.MouseButton1Click:Connect(function()
			local def = cmdLookup[a.cmd]
			if def then
				if #def.params <= 1 then
					task.defer(function() runCommand(a.cmd.." "..target.Name) end)
				else
					openModal(def, target.Name)
				end
			end
		end)
	end

	playerRows[target.UserId] = row
end

local function removePlayerRow(target)
	if playerRows[target.UserId] then playerRows[target.UserId]:Destroy() end
	playerRows[target.UserId] = nil
end

for _, p in ipairs(Players:GetPlayers()) do addPlayerRow(p) end
Players.PlayerAdded:Connect(addPlayerRow)
Players.PlayerRemoving:Connect(removePlayerRow)



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SETTINGS TAB
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local setFrame = tabFrames["Settings"]
UI.pad(setFrame, SIZE.pad, SIZE.pad, SIZE.pad, SIZE.pad)

local setScroll = UI.scroll({name="SetScroll", size=UDim2.new(1,0,1,0), parent=setFrame})
UI.list(setScroll, 10)

local function settingSection(text, order)
	UI.label({text=text, font=FONT.semi, ts=11, color=THEME.textSub, size=UDim2.new(1,0,0,20), order=order, parent=setScroll})
end

local function settingSlider(label, min, max, default, order, onChange)
	local c = UI.frame({name="Sl_"..label, size=UDim2.new(1,0,0,40), bg=THEME.bg, alpha=1, order=order, parent=setScroll})
	UI.label({text=label, font=FONT.medium, ts=11, color=THEME.textSub, size=UDim2.new(0,130,0,16), parent=c})
	local valLbl = UI.label({text=tostring(default), font=FONT.semi, ts=11, color=THEME.text, size=UDim2.new(0,36,0,16), pos=UDim2.new(1,-36,0,0), xAlign=Enum.TextXAlignment.Right, parent=c})

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -8, 0, 4)
	track.Position = UDim2.new(0, 4, 0, 28)
	track.BackgroundColor3 = THEME.surface
	track.BorderSizePixel = 0
	track.Parent = c
	UI.corner(track, 2)

	local pct = (default - min) / (max - min)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct, 0, 1, 0)
	fill.BackgroundColor3 = THEME.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	UI.corner(fill, 2)
	table.insert(accentElements, {obj=fill, prop="BackgroundColor3"})

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(pct, 0, 0.5, 0)
	knob.BackgroundColor3 = THEME.accent
	knob.BorderSizePixel = 0
	knob.Parent = track
	UI.corner(knob, 6)
	table.insert(accentElements, {obj=knob, prop="BackgroundColor3"})

	-- Drag (with proper connection tracking)
	local dragging = false
	local knobBtn = Instance.new("TextButton")
	knobBtn.Size = UDim2.new(0,22,0,22)
	knobBtn.Position = UDim2.new(0.5,-11,0.5,-11)
	knobBtn.BackgroundTransparency = 1
	knobBtn.Text = ""
	knobBtn.Parent = knob

	local moveConn, upConn

	knobBtn.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moveConn = UserInputService.InputChanged:Connect(function(moved)
				if not dragging then return end
				if moved.UserInputType == Enum.UserInputType.MouseMovement or moved.UserInputType == Enum.UserInputType.Touch then
					local tPos = track.AbsolutePosition.X
					local tSize = track.AbsoluteSize.X
					local rel = math.clamp((moved.Position.X - tPos) / tSize, 0, 1)
					knob.Position = UDim2.new(rel, 0, 0.5, 0)
					fill.Size = UDim2.new(rel, 0, 1, 0)
					local val = math.floor(min + rel * (max - min) + 0.5)
					valLbl.Text = tostring(val)
					if onChange then onChange(val) end
				end
			end)
			upConn = UserInputService.InputEnded:Connect(function(ended)
				if ended.UserInputType == Enum.UserInputType.MouseButton1 or ended.UserInputType == Enum.UserInputType.Touch then
					dragging = false
					if moveConn then moveConn:Disconnect(); moveConn = nil end
					if upConn then upConn:Disconnect(); upConn = nil end
				end
			end)
		end
	end)

	return c
end

local function settingToggle(label, default, order, onChange)
	local c = UI.frame({name="Tg_"..label, size=UDim2.new(1,0,0,30), bg=THEME.bg, alpha=1, order=order, parent=setScroll})
	UI.label({text=label, font=FONT.medium, ts=11, color=THEME.textSub, size=UDim2.new(1,-56,1,0), parent=c})

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 36, 0, 18)
	bg.Position = UDim2.new(1, -40, 0.5, -9)
	bg.BackgroundColor3 = default and THEME.accent or THEME.surface
	bg.BorderSizePixel = 0
	bg.Parent = c
	UI.corner(bg, 9)
	if default then table.insert(accentElements, {obj=bg, prop="BackgroundColor3"}) end

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
	knob.BackgroundColor3 = THEME.text
	knob.BorderSizePixel = 0
	knob.Parent = bg
	UI.corner(knob, 7)

	local state = default
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1,0,1,0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = bg

	btn.MouseButton1Click:Connect(function()
		state = not state
		tweenTo(knob, {Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}, 0.2)
		tweenTo(bg, {BackgroundColor3 = state and THEME.accent or THEME.surface}, 0.2)
		if onChange then onChange(state) end
	end)

	return c
end

-- Build settings
settingSection("Fly Settings", 1)
settingSlider("Fly Speed", 10, 200, FLY_SPEED, 2, function(v) FLY_SPEED = v end)
settingSlider("Fly Boost", 50, 400, FLY_BOOST, 3, function(v) FLY_BOOST = v end)

settingSection("Movement", 4)
settingToggle("Noclip", noclip, 5, function(s)
	noclip = s
	notify("Movement", s and "Noclip enabled" or "Noclip disabled", s and "success" or "info")
end)

settingSection("Appearance", 6)

-- Accent Color Picker
local colorRow = UI.frame({name="Colors", size=UDim2.new(1,0,0,34), bg=THEME.bg, alpha=1, order=7, parent=setScroll})
UI.label({text="Accent Color", font=FONT.medium, ts=11, color=THEME.textSub, size=UDim2.new(0,85,1,0), parent=colorRow})

local colorData = {}
for i, opt in ipairs(ACCENT_PRESETS) do
	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 20, 0, 20)
	circle.Position = UDim2.new(0, 88 + (i-1)*28, 0.5, -10)
	circle.BackgroundColor3 = opt.color
	circle.BorderSizePixel = 0
	circle.Parent = colorRow
	UI.corner(circle, 10)

	local ring = UI.stroke(circle, THEME.text, (i==1) and 2 or 0, 0)

	local cBtn = Instance.new("TextButton")
	cBtn.Size = UDim2.new(1,0,1,0)
	cBtn.BackgroundTransparency = 1
	cBtn.Text = ""
	cBtn.Parent = circle

	cBtn.MouseButton1Click:Connect(function()
		for _, d in ipairs(colorData) do d.ring.Thickness = 0 end
		ring.Thickness = 2
		THEME.accent = opt.color
		THEME.accentHover = lerpColor(opt.color, THEME.text, 0.2)
		THEME.accentDim = lerpColor(opt.color, THEME.bg, 0.6)
		-- Update registered elements
		for _, elem in ipairs(accentElements) do
			if elem.obj and elem.obj.Parent then pcall(function() elem.obj[elem.prop] = opt.color end) end
		end
		fabIcon.TextColor3 = opt.color
		if not panelOpen then fabStroke.Color = opt.color end
		fabGlowStroke.Color = opt.color
		indicator.BackgroundColor3 = opt.color
		if tabBtns[activeTab] then tabBtns[activeTab].TextColor3 = opt.color end
	end)

	table.insert(colorData, {frame=circle, ring=ring})
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LOGS TAB
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local logFrame = tabFrames["Logs"]
UI.pad(logFrame, SIZE.padSm, SIZE.padSm, SIZE.pad, SIZE.pad)
UI.list(logFrame, 8)

local logHdr = UI.frame({name="LogHdr", size=UDim2.new(1,0,0,26), bg=THEME.bg, alpha=1, order=1, parent=logFrame})
UI.label({text="Command History", font=FONT.semi, ts=11, color=THEME.textSub, size=UDim2.new(0,130,1,0), parent=logHdr})

local clearBtn = UI.btn({name="Clear", size=UDim2.new(0,56,0,22), pos=UDim2.new(1,-56,0.5,-11), bg=THEME.surface, hover=THEME.danger, textColor=THEME.textMuted, text="Clear", ts=9, radius=5, parent=logHdr})
clearBtn.MouseButton1Click:Connect(function()
	commandLogs = {}
	if logsScroll then for _, c in ipairs(logsScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end end
	notify("Logs", "History cleared", "info")
end)

logsScroll = UI.scroll({name="LogScroll", size=UDim2.new(1,0,1,-34), order=2, parent=logFrame})
UI.list(logsScroll, 3)



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- QUICK COMMAND BAR (Premium Spotlight)
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local quickBar = UI.frame({name="QuickBar", size=UDim2.new(0,480,0,50), pos=UDim2.new(0.5,0,0,-60), anchor=Vector2.new(0.5,0), bg=THEME.bgElevated, alpha=0.04, clip=true, parent=screen})
UI.corner(quickBar, SIZE.radiusMd)
local qbStroke = UI.stroke(quickBar, THEME.borderSubtle, 1, 0.45)
local qbGlow = UI.stroke(quickBar, THEME.accent, 1.5, 1)

local cmdInput = UI.input({name="CmdInput", size=UDim2.new(1,-18,0,28), pos=UDim2.new(0,9,0,5), placeholder="Type a command... (TAB to autocomplete)", bg=THEME.surface, parent=quickBar})
local cmdHint = UI.label({text="", font=FONT.regular, ts=9, color=THEME.textMuted, size=UDim2.new(1,-20,0,12), pos=UDim2.new(0,10,0,36), parent=quickBar})

-- Suggestion Dropdown
local sugFrame = UI.frame({name="Sug", size=UDim2.new(0,480,0,0), pos=UDim2.new(0.5,0,0,58), anchor=Vector2.new(0.5,0), bg=THEME.bgElevated, alpha=0.04, autoSize=Enum.AutomaticSize.Y, clip=true, parent=screen})
sugFrame.Visible = false
UI.corner(sugFrame, SIZE.radiusSm)
UI.stroke(sugFrame, THEME.borderSubtle, 1, 0.5)
UI.pad(sugFrame, 4, 4, 4, 4)
UI.list(sugFrame, 2)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- AUTOCOMPLETE & SUGGESTIONS
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function getSuggestion(text)
	local first = (text or ""):match("^%s*(%S+)")
	if not first then return nil end
	local p = first:lower()
	if cmdLookup[p] then return p end
	for _, name in ipairs(cmdNames) do
		if name:sub(1, #p) == p then return name end
	end
	return nil
end

local function getMatches(text, max)
	max = max or 5
	local results = {}
	local p = (text or ""):lower()
	if p == "" then return results end
	for _, def in ipairs(COMMANDS) do
		if #results >= max then break end
		if def.token:find(p, 1, true) or def.desc:lower():find(p, 1, true) then
			results[#results+1] = def
		end
	end
	return results
end

local function updateSuggestions()
	for _, c in ipairs(sugFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if not quickBarOpen then sugFrame.Visible = false return end

	local cur = cmdInput.Text or ""
	if cur:find("%s") or cur == "" then sugFrame.Visible = false return end

	local matches = getMatches(cur, 5)
	if #matches == 0 then sugFrame.Visible = false return end

	sugFrame.Visible = true
	for i, def in ipairs(matches) do
		local row = UI.frame({name="S_"..def.token, size=UDim2.new(1,0,0,28), bg=THEME.surface, alpha=0.6, order=i, parent=sugFrame})
		UI.corner(row, 4)

		local rBtn = Instance.new("TextButton")
		rBtn.Size = UDim2.new(1,0,1,0)
		rBtn.BackgroundTransparency = 1
		rBtn.Text = ""
		rBtn.AutoButtonColor = false
		rBtn.Parent = row
		rBtn.MouseEnter:Connect(function() tweenTo(row, {BackgroundTransparency = 0.2}, 0.06) end)
		rBtn.MouseLeave:Connect(function() tweenTo(row, {BackgroundTransparency = 0.6}, 0.08) end)

		local catColor = CATEGORY_COLORS[def.cat] or THEME.accent
		local d = Instance.new("Frame")
		d.Size = UDim2.new(0,4,0,4)
		d.Position = UDim2.new(0,8,0.5,-2)
		d.BackgroundColor3 = catColor
		d.BorderSizePixel = 0
		d.Parent = row
		UI.corner(d, 2)

		UI.label({text=def.token, font=FONT.semi, ts=11, color=THEME.text, size=UDim2.new(0,90,1,0), pos=UDim2.new(0,18,0,0), parent=row})
		UI.label({text=def.desc, font=FONT.regular, ts=9, color=THEME.textMuted, size=UDim2.new(1,-120,1,0), pos=UDim2.new(0,110,0,0), truncate=Enum.TextTruncate.AtEnd, parent=row})

		rBtn.MouseButton1Click:Connect(function()
			cmdInput.Text = def.token .. " "
			cmdInput.CursorPosition = #cmdInput.Text + 1
			cmdInput:CaptureFocus()
			updateSuggestions()
		end)
	end
end

local function updateHint()
	if not quickBarOpen then cmdHint.Text = "" return end
	local cur = cmdInput.Text or ""
	local first = cur:match("^%s*(%S+)")
	if not first or first == "" then
		cmdHint.Text = "TAB: Autocomplete  |  ↑↓: History  |  Chat: ! or ;"
		return
	end
	if cur:find("%s") then cmdHint.Text = "" return end
	local sug = getSuggestion(first)
	if sug and sug ~= first:lower() then
		cmdHint.Text = "→ " .. sug .. "  (TAB)"
	else
		cmdHint.Text = ""
	end
end

cmdInput:GetPropertyChangedSignal("Text"):Connect(function() updateHint(); updateSuggestions() end)
cmdInput.Focused:Connect(function() updateHint(); tweenTo(qbGlow, {Transparency = 0.3}, 0.2) end)
cmdInput.FocusLost:Connect(function() tweenTo(qbGlow, {Transparency = 1}, 0.2) end)

local function openQuickBar()
	if quickBarOpen then return end
	quickBarOpen = true
	tweenTo(quickBar, {Position = UDim2.new(0.5, 0, 0, 12)}, 0.3, Enum.EasingStyle.Quint)
	tweenTo(qbStroke, {Transparency = 0.2}, 0.2)
	cmdInput:CaptureFocus()
	updateHint()
end

local function closeQuickBar()
	if not quickBarOpen then return end
	quickBarOpen = false
	tweenTo(quickBar, {Position = UDim2.new(0.5, 0, 0, -60)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenTo(qbStroke, {Transparency = 0.45}, 0.2)
	cmdInput:ReleaseFocus()
	cmdHint.Text = ""
	sugFrame.Visible = false
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- FLY / NOCLIP SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RunService.Stepped:Connect(function()
	if not noclip then return end
	local ch = player.Character
	if not ch then return end
	for _, part in ipairs(ch:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
end)

local function destroyFly()
	local function safe(inst) if typeof(inst) == "Instance" and inst.Parent then inst:Destroy() end end
	safe(flyLinearVelocity); flyLinearVelocity = nil
	safe(flyAlignOrientation); flyAlignOrientation = nil
	safe(flyAttachment); flyAttachment = nil
end

player.CharacterAdded:Connect(function()
	if flying then flying = false; flyVelocitySmooth = Vector3.zero; destroyFly() end
end)

local function setFly(enabled)
	flying = enabled
	local root, hum = getRoot()
	if not root or not hum then return end

	if enabled then
		destroyFly()
		flySavedAutoRotate = hum.AutoRotate
		hum.AutoRotate = false
		hum.PlatformStand = true

		flyAttachment = Instance.new("Attachment")
		flyAttachment.Name = "FlyAtt"
		flyAttachment.Parent = root

		flyLinearVelocity = Instance.new("LinearVelocity")
		flyLinearVelocity.Attachment0 = flyAttachment
		flyLinearVelocity.MaxForce = 1e6
		flyLinearVelocity.VectorVelocity = Vector3.zero
		flyLinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		flyLinearVelocity.Parent = root

		flyAlignOrientation = Instance.new("AlignOrientation")
		flyAlignOrientation.Attachment0 = flyAttachment
		flyAlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		flyAlignOrientation.Responsiveness = 13
		flyAlignOrientation.RigidityEnabled = false
		flyAlignOrientation.CFrame = workspace.CurrentCamera.CFrame
		flyAlignOrientation.Parent = root

		flyVelocitySmooth = root.AssemblyLinearVelocity
		flyLastCamCFrame = workspace.CurrentCamera.CFrame
		notify("Movement", "Fly enabled (Shift = Boost)", "success")
	else
		hum.PlatformStand = false
		hum.AutoRotate = flySavedAutoRotate
		destroyFly()
		flyVelocitySmooth = Vector3.zero
		notify("Movement", "Fly disabled", "info")
	end
end

RunService.RenderStepped:Connect(function(dt)
	dt = math.clamp(dt, 1/240, 1/24)
	if not flying or not flyLinearVelocity or not flyAlignOrientation then return end
	local root = flyAttachment and flyAttachment.Parent
	if not root then return end

	local cam = workspace.CurrentCamera
	local blocked = cmdInput:IsFocused()
	local move = Vector3.zero

	if not blocked then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then move -= Vector3.yAxis end
	end

	local boost = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	local speed = boost and FLY_BOOST or FLY_SPEED

	if move.Magnitude > 1e-4 then
		local target = move.Unit * speed
		local a = 1 - math.exp(-dt / math.max(FLY_RESPONSE, 1e-4))
		flyVelocitySmooth = flyVelocitySmooth:Lerp(target, math.clamp(a, 0, 1))
	else
		flyVelocitySmooth *= math.exp(-FLY_DRAG * dt)
	end

	flyLinearVelocity.VectorVelocity = flyVelocitySmooth

	local rotBlend = 1 - math.exp(-dt / 0.09)
	flyLastCamCFrame = flyLastCamCFrame:Lerp(cam.CFrame, math.clamp(rotBlend, 0, 1))
	flyAlignOrientation.CFrame = flyLastCamCFrame
end)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- COMMAND EXECUTION
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function fireServer(cmd, args)
	if not remote then notify("Error", "Remote not found", "error") return end
	remote:FireServer({command = cmd, args = args})
end

function runCommand(rawText)
	local text = rawText:gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return end

	local parts = split(text)
	local base = parts[1]:lower()

	-- Log & stats
	addLog(text, true)
	totalCommandsRun += 1
	for _, c in ipairs(statCmds:GetChildren()) do
		if c:IsA("TextLabel") and c.TextSize == 18 then c.Text = tostring(totalCommandsRun) break end
	end

	-- History
	table.insert(commandHistory, 1, text)
	if #commandHistory > MAX_HISTORY then table.remove(commandHistory) end
	historyIndex = 0

	-- Update dashboard recent
	if recentFrame then
		recentEmpty.Visible = false
		local children = {}
		for _, c in ipairs(recentFrame:GetChildren()) do if c:IsA("Frame") then children[#children+1] = c end end
		if #children >= 3 then children[#children]:Destroy() end
		local rRow = UI.frame({name="R", size=UDim2.new(1,0,0,22), bg=THEME.surfaceHover, alpha=0.5, order=-totalCommandsRun, parent=recentFrame})
		UI.corner(rRow, 4)
		UI.label({text="  "..text, font=FONT.mono, ts=10, color=THEME.textSub, size=UDim2.new(1,0,1,0), truncate=Enum.TextTruncate.AtEnd, parent=rRow})
	end

	-- Local commands
	if base == "fly" then setFly(true) return end
	if base == "unfly" then setFly(false) return end
	if base == "noclip" then noclip = true; notify("Movement", "Noclip enabled", "success") return end
	if base == "clip" then noclip = false; notify("Movement", "Noclip disabled", "info") return end
	if base == "monitor" then if monitorToggle then monitorToggle:Fire() end; notify("System", "Monitor requested", "info") return end

	-- Server commands dispatch
	local dispatch = {
		kick = function() fireServer("kick", {parts[2], joinFrom(parts,3)}) end,
		ban = function() fireServer("ban", {parts[2], tonumber(parts[3]) or 60, joinFrom(parts,4)}) end,
		jail = function() fireServer("jail", {parts[2], tonumber(parts[3]) or 30}) end,
		unjail = function() fireServer("unjail", {parts[2]}) end,
		freeze = function() fireServer("freeze", {parts[2]}) end,
		unfreeze = function() fireServer("unfreeze", {parts[2]}) end,
		freezeall = function() fireServer("freezeall", {}) end,
		unfreezeall = function() fireServer("unfreezeall", {}) end,
		rank = function() fireServer("rank", {parts[2], parts[3]}) end,
		money = function() fireServer("money", {parts[2], tonumber(parts[3]) or 0}) end,
		namechanger = function() fireServer("namechanger", {parts[2], joinFrom(parts,3)}) end,
		resetname = function() fireServer("resetname", {parts[2]}) end,
		speed = function() fireServer("speed", {parts[2], tonumber(parts[3]) or 16}) end,
		jump = function() fireServer("jump", {parts[2], tonumber(parts[3]) or 50}) end,
		heal = function() fireServer("heal", {parts[2]}) end,
		kill = function() fireServer("kill", {parts[2]}) end,
		sit = function() fireServer("sit", {parts[2]}) end,
		unsit = function() fireServer("unsit", {parts[2]}) end,
		bring = function() fireServer("bring", {parts[2]}) end,
		to = function() fireServer("to", {parts[2]}) end,
		event = function() fireServer("event", {parts[2], parts[3]}) end,
		hack = function() fireServer("hack", {}) end,
		laser = function() fireServer("laser", {}) end,
		smite = function() fireServer("smite", {parts[2]}) end,
		nuke = function() fireServer("nuke", {}) end,
		meteor = function() fireServer("meteor", {}) end,
		snap = function() fireServer("snap", {}) end,
		virus = function() fireServer("virus", {parts[2]}) end,
		shutdown = function() fireServer("shutdown", {joinFrom(parts,2)}) end,
		lobbyannouncement = function() fireServer("lobbyannouncement", {joinFrom(parts,2)}) end,
		globalannouncement = function() fireServer("globalannouncement", {joinFrom(parts,2)}) end,
		lobby = function() fireServer("lobby", {joinFrom(parts,2)}) end,
		global = function() fireServer("global", {joinFrom(parts,2)}) end,
		unbanid = function() fireServer("unbanid", {parts[2]}) end,
	}

	if dispatch[base] then
		dispatch[base]()
	else
		notify("Error", "Unknown command: " .. base, "error")
	end
end

-- Quick Bar submit
cmdInput.FocusLost:Connect(function(enter)
	if not enter then return end
	local text = cmdInput.Text
	cmdInput.Text = ""
	updateHint()
	sugFrame.Visible = false
	runCommand(text)
	closeQuickBar()
end)



--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ANNOUNCEMENT SYSTEM
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local annFrame = UI.frame({name="Announce", size=UDim2.new(0,500,0,0), pos=UDim2.new(0.5,0,0,-120), anchor=Vector2.new(0.5,0), bg=THEME.bgElevated, alpha=0.08, autoSize=Enum.AutomaticSize.Y, parent=screen})
annFrame.Visible = false
UI.corner(annFrame, SIZE.radiusMd)
UI.stroke(annFrame, THEME.accent, 1, 0.5)
UI.pad(annFrame, 16, 16, 22, 22)

local annText = UI.label({text="", font=FONT.bold, ts=18, color=THEME.text, size=UDim2.new(1,0,0,0), xAlign=Enum.TextXAlignment.Center, parent=annFrame, wrap=true, autoY=true})

local function showAnnouncement(text)
	annText.Text = string.upper(tostring(text or ""))
	announcementToken += 1
	local token = announcementToken
	annFrame.Visible = true
	annFrame.Position = UDim2.new(0.5, 0, 0, -40)
	tweenTo(annFrame, {Position = UDim2.new(0.5, 0, 0, 18)}, 0.4, Enum.EasingStyle.Quint)
	task.delay(5, function()
		if token ~= announcementToken then return end
		local tw = tweenTo(annFrame, {Position = UDim2.new(0.5, 0, 0, -160)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw.Completed:Once(function() if token == announcementToken then annFrame.Visible = false end end)
	end)
end

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SERVER COMMUNICATION
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
remote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end

	if payload.type == "admin_init" then
		applyRank(payload.rank or "guest")
		fab.Visible = canOpenUI
		hdrBadgeText.Text = string.upper(myRank)
		hdrBadge.BackgroundColor3 = rankColor(myRank)
		dashBadgeText.Text = string.upper(myRank)
		dashBadge.BackgroundColor3 = rankColor(myRank)
		dashBadge.Visible = true
		for _, c in ipairs(statRank:GetChildren()) do
			if c:IsA("TextLabel") and c.TextSize == 18 then c.Text = string.upper(myRank); c.TextColor3 = rankColor(myRank) break end
		end
		if canOpenUI then notify("System", "Admin loaded. Rank: "..(payload.rank or "guest"), "success", 4) end
		return
	end

	if payload.type == "announcement" then
		showAnnouncement(payload.text)
	end
end)

-- Init
remote:FireServer({type = "request_init"})
applyRank(player:GetAttribute("AdminRank"))
fab.Visible = canOpenUI

player:GetAttributeChangedSignal("AdminRank"):Connect(function()
	applyRank(player:GetAttribute("AdminRank"))
	fab.Visible = canOpenUI
end)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INPUT BINDINGS
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function toggleQuickBar()
	if not canOpenUI then notify("Admin", "No permission. Rank: "..myRank, "error") return end
	if quickBarOpen then closeQuickBar() else openQuickBar() end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if TOGGLE_KEYS[input.KeyCode] then toggleQuickBar() end

	if input.KeyCode == Enum.KeyCode.Escape then
		if modal.Visible then closeModal()
		elseif panelOpen then closePanel()
		elseif quickBarOpen then closeQuickBar() end
	end

	-- History nav
	if quickBarOpen and cmdInput:IsFocused() then
		if input.KeyCode == Enum.KeyCode.Up then
			historyIndex = math.min(historyIndex + 1, #commandHistory)
			if commandHistory[historyIndex] then cmdInput.Text = commandHistory[historyIndex]; cmdInput.CursorPosition = #cmdInput.Text + 1 end
		elseif input.KeyCode == Enum.KeyCode.Down then
			historyIndex = math.max(historyIndex - 1, 0)
			cmdInput.Text = historyIndex == 0 and "" or (commandHistory[historyIndex] or "")
			cmdInput.CursorPosition = #cmdInput.Text + 1
		end
	end
end)

-- TAB Autocomplete
ContextActionService:BindActionAtPriority("AdminTab", function(_, state, inp)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	if inp.KeyCode ~= Enum.KeyCode.Tab or not cmdInput:IsFocused() then return Enum.ContextActionResult.Pass end

	local cur = cmdInput.Text or ""
	if cur:find("%s") then return Enum.ContextActionResult.Sink end

	local sug = getSuggestion(cur)
	if sug and sug ~= cur:lower() then
		cmdInput.Text = sug .. " "
		cmdInput.CursorPosition = #cmdInput.Text + 1
		updateHint()
		updateSuggestions()
	end
	return Enum.ContextActionResult.Sink
end, false, 100002, Enum.KeyCode.Tab)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CHAT COMMAND PREFIX
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
player.Chatted:Connect(function(msg)
	local text = tostring(msg or "")
	if not CHAT_PREFIXES[text:sub(1, 1)] then return end
	if not canOpenUI then notify("Admin", "No permission for chat commands", "error") return end

	local raw = text:sub(2):gsub("^%s+", "")
	if raw == "" then return end

	local lower = raw:lower()
	if lower == "ui" or lower == "cmd" or lower == "cmdbox" then toggleQuickBar() return end

	runCommand(raw)
end)

--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- INIT
--━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
task.defer(function()
	task.wait(0.1)
	local btn = tabBtns[activeTab]
	if btn then
		local relY = btn.AbsolutePosition.Y - sidebar.AbsolutePosition.Y + 8
		indicator.Position = UDim2.new(0, 0, 0, relY)
	end
end)

-- End of AdminClient Premium v2.0
