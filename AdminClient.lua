--------------------------------------------------------------------------------
-- AdminClient (LocalScript) - PREMIUM UI REWRITE
-- Next-Gen Admin Panel with Sidebar Navigation, Glass Effects, Drag System
-- Built for sale-ready quality. 15+ years Luau/UI experience.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- SECTION 1: Services
--------------------------------------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

--------------------------------------------------------------------------------
-- SECTION 2: Theme & Design Constants
--------------------------------------------------------------------------------
local THEME = {
	-- Base colors (dark glass aesthetic)
	bg = Color3.fromRGB(12, 12, 18),
	bgGlass = Color3.fromRGB(16, 17, 24),
	surface = Color3.fromRGB(22, 24, 32),
	surfaceElevated = Color3.fromRGB(28, 31, 42),
	surfaceHover = Color3.fromRGB(36, 40, 54),
	surfaceActive = Color3.fromRGB(44, 48, 64),

	-- Accent (mutable)
	accent = Color3.fromRGB(99, 102, 255),
	accentSoft = Color3.fromRGB(99, 102, 255),
	accentGlow = Color3.fromRGB(120, 130, 255),
	accentDim = Color3.fromRGB(60, 62, 140),

	-- Text hierarchy
	textPrimary = Color3.fromRGB(240, 242, 255),
	textSecondary = Color3.fromRGB(155, 162, 185),
	textMuted = Color3.fromRGB(95, 102, 125),
	textOnAccent = Color3.fromRGB(255, 255, 255),

	-- Semantic
	success = Color3.fromRGB(52, 211, 153),
	successDim = Color3.fromRGB(20, 80, 60),
	danger = Color3.fromRGB(248, 85, 85),
	dangerDim = Color3.fromRGB(80, 25, 25),
	warning = Color3.fromRGB(251, 191, 36),
	warningDim = Color3.fromRGB(80, 60, 10),
	info = Color3.fromRGB(96, 165, 250),
	infoDim = Color3.fromRGB(20, 40, 80),

	-- Border / Stroke
	border = Color3.fromRGB(45, 50, 68),
	borderSubtle = Color3.fromRGB(35, 38, 52),
	borderGlow = Color3.fromRGB(99, 102, 255),

	-- Category colors
	catModeration = Color3.fromRGB(248, 85, 85),
	catPlayer = Color3.fromRGB(96, 165, 250),
	catMovement = Color3.fromRGB(52, 211, 153),
	catFun = Color3.fromRGB(251, 191, 36),
	catServer = Color3.fromRGB(168, 130, 255),

	-- Shadows (via ImageLabel workaround or just darker bg layers)
	shadow = Color3.fromRGB(0, 0, 0),
}

local FONTS = {
	heading = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	subheading = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
	body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	bodyLight = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular),
	mono = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.Regular),
}

local SIZES = {
	panelWidth = 620,
	panelHeight = 480,
	sidebarWidth = 56,
	headerHeight = 48,
	cornerLg = 14,
	cornerMd = 10,
	cornerSm = 7,
	cornerXs = 4,
	padding = 14,
	paddingSm = 8,
	paddingXs = 4,
	buttonHeight = 34,
	inputHeight = 36,
	rowHeight = 42,
	iconSize = 20,
	badgeHeight = 20,
	toastWidth = 280,
}

local CATEGORY_COLORS = {
	Moderation = THEME.catModeration,
	Player = THEME.catPlayer,
	Movement = THEME.catMovement,
	Fun = THEME.catFun,
	Server = THEME.catServer,
}

local ACCENT_OPTIONS = {
	{name = "Indigo", color = Color3.fromRGB(99, 102, 255)},
	{name = "Violet", color = Color3.fromRGB(168, 85, 247)},
	{name = "Emerald", color = Color3.fromRGB(52, 211, 153)},
	{name = "Rose", color = Color3.fromRGB(244, 63, 94)},
	{name = "Amber", color = Color3.fromRGB(245, 158, 11)},
	{name = "Cyan", color = Color3.fromRGB(34, 211, 238)},
	{name = "Pink", color = Color3.fromRGB(236, 72, 153)},
	{name = "Sky", color = Color3.fromRGB(56, 189, 248)},
}

local TOGGLE_KEYS = {
	Enum.KeyCode.LeftBracket,
	Enum.KeyCode.RightBracket,
	Enum.KeyCode.Semicolon,
	Enum.KeyCode.Quote,
	Enum.KeyCode.Backquote,
	Enum.KeyCode.Slash,
	Enum.KeyCode.F2,
	Enum.KeyCode.F4,
}

local CHAT_PREFIXES = {
	["!"] = true,
	[";"] = true,
}

--------------------------------------------------------------------------------
-- SECTION 3: State Variables
--------------------------------------------------------------------------------
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local canOpenUI = false
local myRank = "guest"
local flying = false
local noclip = false
local activeTab = "Dashboard"
local panelOpen = false
local panelDragging = false
local panelDragStart = nil
local panelDragOffset = nil

local FLY_SPEED = 54
local FLY_BOOST_SPEED = 102
local FLY_RESPONSE = 0.14
local FLY_DRAG = 8.8

local flyAttachment = nil
local flyLinearVelocity = nil
local flyAlignOrientation = nil
local flyVelocitySmooth = Vector3.zero
local flyLastCamCFrame = CFrame.identity
local flySavedAutoRotate = true

local commandLogs = {}
local MAX_LOGS = 100
local announcementTweenToken = 0

local collapsedCategories = {}
local playerRows = {}
local accentElements = {}
local toastQueue = {}

local quickBarOpen = false
local commandHistory = {}
local historyIndex = 0
local MAX_HISTORY = 30

--------------------------------------------------------------------------------
-- SECTION 4: Command Definitions
--------------------------------------------------------------------------------
local COMMAND_DEFINITIONS = {
	-- Moderation
	{token = "kick", display = "kick <player> <reason>", description = "Kick a player with reason", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Reason", placeholder = "Reason for kick", trailing = true},
	}, category = "Moderation"},
	{token = "ban", display = "ban <player> <minutes> <reason>", description = "Ban a player temporarily", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Minutes", placeholder = "60"},
		{name = "Reason", placeholder = "Reason for ban", trailing = true},
	}, category = "Moderation"},
	{token = "jail", display = "jail <player> <seconds>", description = "Jail a player for a duration", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Seconds", placeholder = "30"},
	}, category = "Moderation"},
	{token = "unjail", display = "unjail <player>", description = "Release a player from jail", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Moderation"},
	{token = "freeze", display = "freeze <player>", description = "Freeze a player in place", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Moderation"},
	{token = "unfreeze", display = "unfreeze <player>", description = "Unfreeze a player", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Moderation"},
	{token = "freezeall", display = "freezeall", description = "Freeze all players (Admin+)", params = {}, category = "Moderation"},
	{token = "unfreezeall", display = "unfreezeall", description = "Unfreeze all players (Admin+)", params = {}, category = "Moderation"},

	-- Player
	{token = "rank", display = "rank <player> <rank>", description = "Set player rank", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Rank", placeholder = "owner/admin/staff/helper..."},
	}, category = "Player"},
	{token = "money", display = "money <player> <amount>", description = "Give money to a player", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Amount", placeholder = "Amount"},
	}, category = "Player"},
	{token = "namechanger", display = "namechanger <player> <name>", description = "Change display name", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Display Name", placeholder = "New display name", trailing = true},
	}, category = "Player"},
	{token = "resetname", display = "resetname <player>", description = "Reset display name", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Player"},
	{token = "speed", display = "speed <player> <value>", description = "Set walk speed", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Speed", placeholder = "16"},
	}, category = "Player"},
	{token = "jump", display = "jump <player> <value>", description = "Set jump power", params = {
		{name = "Player", placeholder = "Player name"},
		{name = "Jump", placeholder = "50"},
	}, category = "Player"},
	{token = "heal", display = "heal <player>", description = "Heal to max health", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Player"},
	{token = "kill", display = "kill <player>", description = "Kill a player", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Player"},
	{token = "sit", display = "sit <player>", description = "Force player to sit", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Player"},
	{token = "unsit", display = "unsit <player>", description = "Force player to stand", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Player"},

	-- Movement
	{token = "fly", display = "fly", description = "Enable fly mode (Shift = Boost)", params = {}, category = "Movement"},
	{token = "unfly", display = "unfly", description = "Disable fly mode", params = {}, category = "Movement"},
	{token = "noclip", display = "noclip", description = "Enable noclip", params = {}, category = "Movement"},
	{token = "clip", display = "clip", description = "Disable noclip", params = {}, category = "Movement"},
	{token = "bring", display = "bring <player>", description = "Bring a player to you", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Movement"},
	{token = "to", display = "to <player>", description = "Teleport to a player", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Movement"},

	-- Fun
	{token = "event", display = "event <type>", description = "Start event (120s)", params = {
		{name = "Event Type", placeholder = "tacos/brazil/coco/dance/arabic/jumpscare"},
	}, category = "Fun"},
	{token = "hack", display = "hack", description = "Destroy the map (Hacker+)", params = {}, category = "Fun"},
	{token = "laser", display = "laser", description = "Fire destructive laser (Hacker+)", params = {}, category = "Fun"},
	{token = "smite", display = "smite <player>", description = "Strike with lightning (Admin+)", params = {
		{name = "Player", placeholder = "Player name"},
	}, category = "Fun"},
	{token = "nuke", display = "nuke", description = "Drop a nuke (Hacker+)", params = {}, category = "Fun"},
	{token = "meteor", display = "meteor", description = "Meteor shower (Hacker+)", params = {}, category = "Fun"},
	{token = "snap", display = "snap", description = "All chaos combined (Admin+)", params = {}, category = "Fun"},
	{token = "virus", display = "virus [player/all]", description = "Fake Trojan virus effect", params = {
		{name = "Player", placeholder = "all"},
	}, category = "Fun"},

	-- Server
	{token = "shutdown", display = "shutdown <reason>", description = "Shutdown server", params = {
		{name = "Reason", placeholder = "Reason", trailing = true},
	}, category = "Server"},
	{token = "lobbyannouncement", display = "lobbyannouncement <text>", description = "Lobby announcement", params = {
		{name = "Text", placeholder = "Announcement text", trailing = true},
	}, category = "Server"},
	{token = "globalannouncement", display = "globalannouncement <text>", description = "Global announcement", params = {
		{name = "Text", placeholder = "Announcement text", trailing = true},
	}, category = "Server"},
	{token = "lobby", display = "lobby <text>", description = "Lobby announcement (alias)", params = {
		{name = "Text", placeholder = "Announcement text", trailing = true},
	}, category = "Server"},
	{token = "global", display = "global <text>", description = "Global announcement (alias)", params = {
		{name = "Text", placeholder = "Announcement text", trailing = true},
	}, category = "Server"},
	{token = "monitor", display = "monitor", description = "Open monitor panel", params = {}, category = "Server"},
	{token = "unbanid", display = "unbanid <userId>", description = "Unban user by ID", params = {
		{name = "UserId", placeholder = "User ID number"},
	}, category = "Server"},
}

-- Build lookup
local commandNames = {}
local commandLookup = {}
for _, def in ipairs(COMMAND_DEFINITIONS) do
	if not commandLookup[def.token] then
		commandLookup[def.token] = true
		table.insert(commandNames, def.token)
	end
end
table.sort(commandNames)

--------------------------------------------------------------------------------
-- SECTION 5: Remote Setup
--------------------------------------------------------------------------------
local remote = ReplicatedStorage:WaitForChild("AdminCommandRemote", 10)
if not remote or not remote:IsA("RemoteEvent") then
	return
end

local monitorToggleEvent = ReplicatedStorage:FindFirstChild("AdminMonitorToggle")
if not monitorToggleEvent then
	monitorToggleEvent = Instance.new("BindableEvent")
	monitorToggleEvent.Name = "AdminMonitorToggle"
	monitorToggleEvent.Parent = ReplicatedStorage
end



--------------------------------------------------------------------------------
-- SECTION 6: Utility Functions
--------------------------------------------------------------------------------
local function splitBySpace(text)
	local out = {}
	for part in string.gmatch(text, "%S+") do
		table.insert(out, part)
	end
	return out
end

local function joinFrom(parts, startIndex)
	local merged = {}
	for i = startIndex, #parts do
		table.insert(merged, parts[i])
	end
	return table.concat(merged, " ")
end

local function getCharacterRoot()
	local character = player.Character
	if not character then return nil, nil end
	return character:FindFirstChild("HumanoidRootPart"), character:FindFirstChildOfClass("Humanoid")
end

local function isToggleKey(keyCode)
	for _, candidate in ipairs(TOGGLE_KEYS) do
		if keyCode == candidate then return true end
	end
	return false
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function lerpColor(c1, c2, t)
	return Color3.new(lerp(c1.R, c2.R, t), lerp(c1.G, c2.G, t), lerp(c1.B, c2.B, t))
end

-- Smooth tween helper
local function tween(obj, props, duration, style, direction)
	duration = duration or 0.2
	style = style or Enum.EasingStyle.Quint
	direction = direction or Enum.EasingDirection.Out
	return TweenService:Create(obj, TweenInfo.new(duration, style, direction), props)
end

local function tweenPlay(obj, props, duration, style, direction)
	tween(obj, props, duration, style, direction):Play()
end

--------------------------------------------------------------------------------
-- SECTION 7: Component Factory
--------------------------------------------------------------------------------
local Components = {}

function Components.corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or SIZES.cornerMd)
	c.Parent = parent
	return c
end

function Components.stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or THEME.border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.5
	s.Parent = parent
	return s
end

function Components.padding(parent, top, bottom, left, right)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, top or SIZES.padding)
	p.PaddingBottom = UDim.new(0, bottom or SIZES.padding)
	p.PaddingLeft = UDim.new(0, left or SIZES.padding)
	p.PaddingRight = UDim.new(0, right or SIZES.padding)
	p.Parent = parent
	return p
end

function Components.listLayout(parent, padding, direction, hAlign, vAlign, sortOrder)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, padding or 6)
	l.FillDirection = direction or Enum.FillDirection.Vertical
	l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
	l.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

function Components.gradient(parent, c1, c2, rotation)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1 or THEME.surface, c2 or THEME.bg)
	g.Rotation = rotation or 180
	g.Parent = parent
	return g
end

function Components.textLabel(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = props.size or UDim2.new(1, 0, 0, 20)
	l.Position = props.position or UDim2.new(0, 0, 0, 0)
	l.FontFace = props.font or FONTS.body
	l.TextSize = props.textSize or 14
	l.TextColor3 = props.color or THEME.textPrimary
	l.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = props.yAlign or Enum.TextYAlignment.Center
	l.TextTruncate = props.truncate or Enum.TextTruncate.None
	l.Text = props.text or ""
	l.RichText = props.richText or false
	l.LayoutOrder = props.layoutOrder or 0
	if props.parent then l.Parent = props.parent end
	return l
end

function Components.frame(props)
	local f = Instance.new("Frame")
	f.Name = props.name or "Frame"
	f.Size = props.size or UDim2.new(1, 0, 0, 40)
	f.Position = props.position or UDim2.new(0, 0, 0, 0)
	f.AnchorPoint = props.anchor or Vector2.new(0, 0)
	f.BackgroundColor3 = props.bg or THEME.surface
	f.BackgroundTransparency = props.bgTransparency or 0
	f.BorderSizePixel = 0
	f.LayoutOrder = props.layoutOrder or 0
	f.Visible = props.visible ~= false
	f.ClipsDescendants = props.clip or false
	f.AutomaticSize = props.autoSize or Enum.AutomaticSize.None
	if props.parent then f.Parent = props.parent end
	return f
end

function Components.button(props)
	local b = Instance.new("TextButton")
	b.Name = props.name or "Button"
	b.Size = props.size or UDim2.new(0, 100, 0, SIZES.buttonHeight)
	b.Position = props.position or UDim2.new(0, 0, 0, 0)
	b.AnchorPoint = props.anchor or Vector2.new(0, 0)
	b.BackgroundColor3 = props.bg or THEME.accent
	b.BackgroundTransparency = props.bgTransparency or 0
	b.FontFace = props.font or FONTS.subheading
	b.TextSize = props.textSize or 13
	b.TextColor3 = props.textColor or THEME.textOnAccent
	b.Text = props.text or "Button"
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.LayoutOrder = props.layoutOrder or 0
	if props.parent then b.Parent = props.parent end

	Components.corner(b, props.corner or SIZES.cornerSm)

	-- Hover/Press animations
	local normalBg = props.bg or THEME.accent
	local hoverBg = props.hoverBg or lerpColor(normalBg, THEME.textPrimary, 0.15)
	local pressBg = props.pressBg or lerpColor(normalBg, THEME.bg, 0.2)

	b.MouseEnter:Connect(function()
		tweenPlay(b, {BackgroundColor3 = hoverBg}, 0.15)
	end)
	b.MouseLeave:Connect(function()
		tweenPlay(b, {BackgroundColor3 = normalBg}, 0.15)
	end)
	b.MouseButton1Down:Connect(function()
		tweenPlay(b, {BackgroundColor3 = pressBg, Size = UDim2.new(
			b.Size.X.Scale, b.Size.X.Offset - 2,
			b.Size.Y.Scale, b.Size.Y.Offset - 2
		)}, 0.08)
	end)
	b.MouseButton1Up:Connect(function()
		tweenPlay(b, {BackgroundColor3 = hoverBg, Size = props.size or UDim2.new(0, 100, 0, SIZES.buttonHeight)}, 0.12)
	end)

	return b
end

function Components.inputBox(props)
	local box = Instance.new("TextBox")
	box.Name = props.name or "Input"
	box.Size = props.size or UDim2.new(1, 0, 0, SIZES.inputHeight)
	box.Position = props.position or UDim2.new(0, 0, 0, 0)
	box.BackgroundColor3 = props.bg or THEME.surfaceElevated
	box.BorderSizePixel = 0
	box.ClearTextOnFocus = props.clearOnFocus or false
	box.FontFace = props.font or FONTS.body
	box.TextSize = props.textSize or 14
	box.TextColor3 = props.textColor or THEME.textPrimary
	box.PlaceholderText = props.placeholder or ""
	box.PlaceholderColor3 = props.placeholderColor or THEME.textMuted
	box.Text = props.text or ""
	box.TextXAlignment = props.xAlign or Enum.TextXAlignment.Left
	box.LayoutOrder = props.layoutOrder or 0
	if props.parent then box.Parent = props.parent end

	Components.corner(box, props.corner or SIZES.cornerSm)
	Components.padding(box, 0, 0, 10, 10)

	local stroke = Components.stroke(box, THEME.borderSubtle, 1, 0.6)

	-- Focus glow
	box.Focused:Connect(function()
		tweenPlay(stroke, {Color = THEME.accent, Transparency = 0.2}, 0.2)
	end)
	box.FocusLost:Connect(function()
		tweenPlay(stroke, {Color = THEME.borderSubtle, Transparency = 0.6}, 0.2)
	end)

	return box
end

function Components.badge(props)
	local badge = Instance.new("Frame")
	badge.Size = props.size or UDim2.new(0, 60, 0, SIZES.badgeHeight)
	badge.BackgroundColor3 = props.bg or THEME.accentDim
	badge.BackgroundTransparency = props.bgTransparency or 0.3
	badge.BorderSizePixel = 0
	if props.parent then badge.Parent = props.parent end
	Components.corner(badge, props.corner or 4)

	local text = Components.textLabel({
		text = props.text or "",
		font = FONTS.subheading,
		textSize = 10,
		color = props.textColor or THEME.accent,
		xAlign = Enum.TextXAlignment.Center,
		size = UDim2.new(1, 0, 1, 0),
		parent = badge,
	})

	return badge, text
end

function Components.scrollFrame(props)
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = props.name or "Scroll"
	scroll.Size = props.size or UDim2.new(1, 0, 1, 0)
	scroll.Position = props.position or UDim2.new(0, 0, 0, 0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = props.scrollBar or 3
	scroll.ScrollBarImageColor3 = THEME.accent
	scroll.ScrollBarImageTransparency = 0.5
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.LayoutOrder = props.layoutOrder or 0
	if props.parent then scroll.Parent = props.parent end
	return scroll
end

function Components.separator(parent, order)
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.BackgroundColor3 = THEME.border
	sep.BackgroundTransparency = 0.6
	sep.BorderSizePixel = 0
	sep.LayoutOrder = order or 0
	sep.Parent = parent
	return sep
end



--------------------------------------------------------------------------------
-- SECTION 8: Toast Notification System
--------------------------------------------------------------------------------
local toastContainer -- defined later after screenGui

local function createToast(title, message, toastType, duration)
	duration = duration or 3
	toastType = toastType or "info"

	local colors = {
		info = {bg = THEME.infoDim, border = THEME.info, icon = "i"},
		success = {bg = THEME.successDim, border = THEME.success, icon = "✓"},
		warning = {bg = THEME.warningDim, border = THEME.warning, icon = "!"},
		error = {bg = THEME.dangerDim, border = THEME.danger, icon = "✕"},
	}
	local style = colors[toastType] or colors.info

	local toast = Components.frame({
		name = "Toast",
		size = UDim2.new(1, 0, 0, 56),
		bg = style.bg,
		bgTransparency = 0.1,
		parent = toastContainer,
	})
	Components.corner(toast, SIZES.cornerSm)
	local stroke = Components.stroke(toast, style.border, 1, 0.4)

	-- Left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 3, 1, -8)
	accentBar.Position = UDim2.new(0, 4, 0, 4)
	accentBar.BackgroundColor3 = style.border
	accentBar.BorderSizePixel = 0
	accentBar.Parent = toast
	Components.corner(accentBar, 2)

	-- Icon
	Components.textLabel({
		text = style.icon,
		font = FONTS.heading,
		textSize = 16,
		color = style.border,
		size = UDim2.new(0, 24, 0, 24),
		position = UDim2.new(0, 14, 0, 8),
		xAlign = Enum.TextXAlignment.Center,
		parent = toast,
	})

	-- Title
	Components.textLabel({
		text = title or "",
		font = FONTS.subheading,
		textSize = 12,
		color = THEME.textPrimary,
		size = UDim2.new(1, -50, 0, 16),
		position = UDim2.new(0, 42, 0, 6),
		parent = toast,
	})

	-- Message
	Components.textLabel({
		text = message or "",
		font = FONTS.bodyLight,
		textSize = 11,
		color = THEME.textSecondary,
		size = UDim2.new(1, -50, 0, 16),
		position = UDim2.new(0, 42, 0, 24),
		truncate = Enum.TextTruncate.AtEnd,
		parent = toast,
	})

	-- Animate in
	toast.Position = UDim2.new(1, 20, 0, 0)
	toast.BackgroundTransparency = 1
	tweenPlay(toast, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.1}, 0.35)
	tweenPlay(stroke, {Transparency = 0.4}, 0.35)

	-- Auto dismiss
	task.delay(duration, function()
		if not toast or not toast.Parent then return end
		local dismissTween = tween(toast, {Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1}, 0.25)
		dismissTween:Play()
		dismissTween.Completed:Once(function()
			if toast and toast.Parent then toast:Destroy() end
		end)
	end)

	return toast
end

local function notify(title, text, ntype, duration)
	if toastContainer then
		createToast(title, text, ntype, duration)
	else
		pcall(function()
			StarterGui:SetCore("SendNotification", {Title = title, Text = text, Duration = duration or 2.5})
		end)
	end
end

--------------------------------------------------------------------------------
-- SECTION 9: Rank System
--------------------------------------------------------------------------------
local function applyRankPermissions(rankName)
	myRank = string.lower(tostring(rankName or "guest"))
	canOpenUI = (myRank == "helper" or myRank == "support" or myRank == "trialstaff"
		or myRank == "staff" or myRank == "seniorstaff" or myRank == "admin"
		or myRank == "owner" or myRank == "hacker")
end

local function getRankDisplayColor(rank)
	local r = string.lower(tostring(rank or "guest"))
	if r == "owner" or r == "hacker" then return THEME.danger end
	if r == "admin" or r == "seniorstaff" then return THEME.warning end
	if r == "staff" or r == "trialstaff" then return THEME.accent end
	if r == "support" or r == "helper" then return THEME.success end
	return THEME.textMuted
end

--------------------------------------------------------------------------------
-- SECTION 10: ScreenGui Setup
--------------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanelPremium"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Toast container (top-right)
toastContainer = Components.frame({
	name = "ToastContainer",
	size = UDim2.new(0, SIZES.toastWidth, 1, -20),
	position = UDim2.new(1, -(SIZES.toastWidth + 12), 0, 10),
	bg = THEME.bg,
	bgTransparency = 1,
	parent = screenGui,
})
Components.listLayout(toastContainer, 6, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)

--------------------------------------------------------------------------------
-- SECTION 11: Toggle Icon (Floating Action Button)
--------------------------------------------------------------------------------
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "AdminFAB"
toggleBtn.Size = UDim2.new(0, 42, 0, 42)
toggleBtn.Position = UDim2.new(1, -58, 0, 8)
toggleBtn.AnchorPoint = Vector2.new(1, 0)
toggleBtn.BackgroundColor3 = THEME.surfaceElevated
toggleBtn.BackgroundTransparency = 0.1
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.Visible = false
toggleBtn.Parent = screenGui
Components.corner(toggleBtn, 12)

local toggleStroke = Components.stroke(toggleBtn, THEME.accent, 1.5, 0.6)

-- Inner glow ring (animated)
local glowRing = Instance.new("Frame")
glowRing.Size = UDim2.new(1, 6, 1, 6)
glowRing.Position = UDim2.new(0.5, 0, 0.5, 0)
glowRing.AnchorPoint = Vector2.new(0.5, 0.5)
glowRing.BackgroundTransparency = 1
glowRing.Parent = toggleBtn
Components.corner(glowRing, 14)
local glowStroke = Components.stroke(glowRing, THEME.accent, 2, 0.85)

-- Icon text
local toggleLabel = Components.textLabel({
	text = "A",
	font = FONTS.heading,
	textSize = 18,
	color = THEME.accent,
	size = UDim2.new(1, 0, 1, 0),
	xAlign = Enum.TextXAlignment.Center,
	parent = toggleBtn,
})

-- Pulse animation for glow ring when panel closed
local pulseUp = true
task.spawn(function()
	while true do
		if not panelOpen and toggleBtn.Visible then
			local target = pulseUp and 0.5 or 0.85
			tweenPlay(glowStroke, {Transparency = target}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			pulseUp = not pulseUp
		end
		task.wait(1.5)
	end
end)

-- Hover
toggleBtn.MouseEnter:Connect(function()
	tweenPlay(toggleBtn, {BackgroundTransparency = 0}, 0.15)
	tweenPlay(toggleStroke, {Transparency = 0.2}, 0.15)
end)
toggleBtn.MouseLeave:Connect(function()
	if not panelOpen then
		tweenPlay(toggleBtn, {BackgroundTransparency = 0.1}, 0.15)
		tweenPlay(toggleStroke, {Transparency = 0.6}, 0.15)
	end
end)



--------------------------------------------------------------------------------
-- SECTION 12: Panel Frame (Draggable, Glass Effect)
--------------------------------------------------------------------------------
local panelFrame = Components.frame({
	name = "AdminPanel",
	size = UDim2.new(0, SIZES.panelWidth, 0, SIZES.panelHeight),
	position = UDim2.new(0.5, 0, 0.5, 0),
	anchor = Vector2.new(0.5, 0.5),
	bg = THEME.bg,
	bgTransparency = 0.02,
	clip = true,
	parent = screenGui,
})
panelFrame.Visible = false
panelFrame.Active = true
Components.corner(panelFrame, SIZES.cornerLg)

local panelStroke = Components.stroke(panelFrame, THEME.border, 1, 0.3)

-- Subtle inner gradient overlay for glass depth
local glassOverlay = Instance.new("Frame")
glassOverlay.Name = "GlassOverlay"
glassOverlay.Size = UDim2.new(1, 0, 0, 120)
glassOverlay.BackgroundColor3 = THEME.accent
glassOverlay.BackgroundTransparency = 0.96
glassOverlay.BorderSizePixel = 0
glassOverlay.Parent = panelFrame
Components.corner(glassOverlay, SIZES.cornerLg)

--------------------------------------------------------------------------------
-- SECTION 13: Header (Drag Handle, Info, Close)
--------------------------------------------------------------------------------
local header = Components.frame({
	name = "Header",
	size = UDim2.new(1, 0, 0, SIZES.headerHeight),
	bg = THEME.surface,
	bgTransparency = 0.3,
	parent = panelFrame,
})

-- Drag handle (the header is the drag zone)
header.Active = true
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		panelDragging = true
		panelDragStart = input.Position
		panelDragOffset = panelFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not panelDragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - panelDragStart
		panelFrame.Position = UDim2.new(
			panelDragOffset.X.Scale, panelDragOffset.X.Offset + delta.X,
			panelDragOffset.Y.Scale, panelDragOffset.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		panelDragging = false
	end
end)

-- Logo / Title
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 28, 0, 28)
logoFrame.Position = UDim2.new(0, 14, 0.5, -14)
logoFrame.BackgroundColor3 = THEME.accent
logoFrame.BackgroundTransparency = 0.85
logoFrame.BorderSizePixel = 0
logoFrame.Parent = header
Components.corner(logoFrame, 7)

Components.textLabel({
	text = "A",
	font = FONTS.heading,
	textSize = 15,
	color = THEME.accent,
	size = UDim2.new(1, 0, 1, 0),
	xAlign = Enum.TextXAlignment.Center,
	parent = logoFrame,
})

Components.textLabel({
	text = "Admin Panel",
	font = FONTS.heading,
	textSize = 14,
	color = THEME.textPrimary,
	size = UDim2.new(0, 100, 1, 0),
	position = UDim2.new(0, 50, 0, 0),
	parent = header,
})

-- Rank badge in header
local rankBadgeFrame, rankBadgeText = Components.badge({
	text = string.upper(myRank),
	bg = getRankDisplayColor(myRank),
	textColor = THEME.textPrimary,
	bgTransparency = 0.7,
	size = UDim2.new(0, 62, 0, 20),
	parent = header,
})
rankBadgeFrame.Position = UDim2.new(0, 154, 0.5, -10)

-- Player count
local playerCountLabel = Components.textLabel({
	text = tostring(#Players:GetPlayers()) .. " online",
	font = FONTS.bodyLight,
	textSize = 11,
	color = THEME.textSecondary,
	size = UDim2.new(0, 70, 1, 0),
	position = UDim2.new(0, 224, 0, 0),
	parent = header,
})

-- Close button
local closeBtn = Components.button({
	name = "CloseBtn",
	size = UDim2.new(0, 30, 0, 30),
	position = UDim2.new(1, -40, 0.5, -15),
	bg = THEME.surfaceElevated,
	hoverBg = THEME.danger,
	textColor = THEME.textSecondary,
	text = "×",
	textSize = 20,
	font = FONTS.body,
	corner = 8,
	parent = header,
})

-- Minimize button
local minBtn = Components.button({
	name = "MinBtn",
	size = UDim2.new(0, 30, 0, 30),
	position = UDim2.new(1, -76, 0.5, -15),
	bg = THEME.surfaceElevated,
	hoverBg = THEME.surfaceActive,
	textColor = THEME.textSecondary,
	text = "—",
	textSize = 14,
	font = FONTS.body,
	corner = 8,
	parent = header,
})

--------------------------------------------------------------------------------
-- SECTION 14: Sidebar Navigation
--------------------------------------------------------------------------------
local sidebar = Components.frame({
	name = "Sidebar",
	size = UDim2.new(0, SIZES.sidebarWidth, 1, -SIZES.headerHeight),
	position = UDim2.new(0, 0, 0, SIZES.headerHeight),
	bg = THEME.surface,
	bgTransparency = 0.5,
	parent = panelFrame,
})

local TAB_INFO = {
	{name = "Dashboard", icon = "◆"},
	{name = "Commands", icon = "▶"},
	{name = "Players", icon = "●"},
	{name = "Settings", icon = "⚙"},
	{name = "Logs", icon = "≡"},
}

local tabButtons = {}
local tabFrames = {}

local sidebarLayout = Components.listLayout(sidebar, 2, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Center)
sidebarLayout.Padding = UDim.new(0, 2)

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 8)
sidebarPad.Parent = sidebar

-- Active indicator (sliding bar on left)
local sidebarIndicator = Instance.new("Frame")
sidebarIndicator.Name = "ActiveIndicator"
sidebarIndicator.Size = UDim2.new(0, 3, 0, 28)
sidebarIndicator.Position = UDim2.new(0, 0, 0, 10)
sidebarIndicator.BackgroundColor3 = THEME.accent
sidebarIndicator.BorderSizePixel = 0
sidebarIndicator.ZIndex = 5
sidebarIndicator.Parent = sidebar
Components.corner(sidebarIndicator, 2)
table.insert(accentElements, {obj = sidebarIndicator, prop = "BackgroundColor3"})

for i, info in ipairs(TAB_INFO) do
	local btn = Instance.new("TextButton")
	btn.Name = info.name .. "NavBtn"
	btn.Size = UDim2.new(0, 44, 0, 44)
	btn.BackgroundColor3 = (info.name == activeTab) and THEME.surfaceElevated or THEME.surface
	btn.BackgroundTransparency = (info.name == activeTab) and 0.3 or 1
	btn.Text = info.icon
	btn.FontFace = FONTS.body
	btn.TextSize = 18
	btn.TextColor3 = (info.name == activeTab) and THEME.accent or THEME.textMuted
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.LayoutOrder = i
	btn.Parent = sidebar
	Components.corner(btn, SIZES.cornerSm)

	-- Tooltip on hover (using a simple TextLabel)
	local tooltip = Instance.new("TextLabel")
	tooltip.Size = UDim2.new(0, 0, 0, 24)
	tooltip.AutomaticSize = Enum.AutomaticSize.X
	tooltip.Position = UDim2.new(1, 8, 0.5, -12)
	tooltip.BackgroundColor3 = THEME.surfaceElevated
	tooltip.BackgroundTransparency = 0.05
	tooltip.FontFace = FONTS.body
	tooltip.TextSize = 11
	tooltip.TextColor3 = THEME.textPrimary
	tooltip.Text = "  " .. info.name .. "  "
	tooltip.Visible = false
	tooltip.ZIndex = 20
	tooltip.Parent = btn
	Components.corner(tooltip, 4)

	btn.MouseEnter:Connect(function()
		tooltip.Visible = true
		if info.name ~= activeTab then
			tweenPlay(btn, {BackgroundTransparency = 0.4, TextColor3 = THEME.textSecondary}, 0.12)
		end
	end)
	btn.MouseLeave:Connect(function()
		tooltip.Visible = false
		if info.name ~= activeTab then
			tweenPlay(btn, {BackgroundTransparency = 1, TextColor3 = THEME.textMuted}, 0.12)
		end
	end)

	tabButtons[info.name] = btn
end

--------------------------------------------------------------------------------
-- SECTION 15: Tab Content Area
--------------------------------------------------------------------------------
local contentArea = Components.frame({
	name = "ContentArea",
	size = UDim2.new(1, -SIZES.sidebarWidth, 1, -SIZES.headerHeight),
	position = UDim2.new(0, SIZES.sidebarWidth, 0, SIZES.headerHeight),
	bg = THEME.bg,
	bgTransparency = 1,
	clip = true,
	parent = panelFrame,
})

for _, info in ipairs(TAB_INFO) do
	local frame = Components.frame({
		name = info.name .. "Content",
		size = UDim2.new(1, 0, 1, 0),
		bg = THEME.bg,
		bgTransparency = 1,
		parent = contentArea,
	})
	frame.Visible = (info.name == activeTab)
	tabFrames[info.name] = frame
end

--------------------------------------------------------------------------------
-- SECTION 16: Tab Switching (Smooth Slide)
--------------------------------------------------------------------------------
local function getTabIndex(name)
	for i, info in ipairs(TAB_INFO) do
		if info.name == name then return i end
	end
	return 1
end

local function switchTab(tabName)
	if tabName == activeTab then return end

	local oldIndex = getTabIndex(activeTab)
	local newIndex = getTabIndex(tabName)
	local direction = (newIndex > oldIndex) and 1 or -1

	-- Deactivate old tab button
	local oldBtn = tabButtons[activeTab]
	if oldBtn then
		tweenPlay(oldBtn, {BackgroundTransparency = 1, TextColor3 = THEME.textMuted}, 0.2)
	end

	-- Slide old content out
	local oldFrame = tabFrames[activeTab]
	if oldFrame then
		tweenPlay(oldFrame, {Position = UDim2.new(-direction * 0.1, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.2, function()
			if oldFrame then oldFrame.Visible = false; oldFrame.Position = UDim2.new(0, 0, 0, 0) end
		end)
	end

	activeTab = tabName

	-- Activate new tab button
	local newBtn = tabButtons[activeTab]
	if newBtn then
		tweenPlay(newBtn, {BackgroundTransparency = 0.3, TextColor3 = THEME.accent}, 0.2)
	end

	-- Move sidebar indicator
	local btnPos = newBtn and newBtn.AbsolutePosition or Vector2.new(0, 0)
	local sidePos = sidebar.AbsolutePosition
	local relY = btnPos.Y - sidePos.Y + 8
	tweenPlay(sidebarIndicator, {Position = UDim2.new(0, 0, 0, relY)}, 0.3, Enum.EasingStyle.Quint)

	-- Slide new content in
	local newFrame = tabFrames[activeTab]
	if newFrame then
		newFrame.Position = UDim2.new(direction * 0.1, 0, 0, 0)
		newFrame.Visible = true
		tweenPlay(newFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quint)
	end
end

-- Connect nav buttons
for _, info in ipairs(TAB_INFO) do
	tabButtons[info.name].MouseButton1Click:Connect(function()
		switchTab(info.name)
	end)
end



--------------------------------------------------------------------------------
-- SECTION 17: Panel Open/Close/Toggle
--------------------------------------------------------------------------------
local function openPanel()
	if panelOpen then return end
	panelOpen = true
	panelFrame.Visible = true
	panelFrame.Size = UDim2.new(0, SIZES.panelWidth * 0.92, 0, SIZES.panelHeight * 0.92)
	panelFrame.BackgroundTransparency = 0.5

	tweenPlay(panelFrame, {
		Size = UDim2.new(0, SIZES.panelWidth, 0, SIZES.panelHeight),
		BackgroundTransparency = 0.02,
	}, 0.35, Enum.EasingStyle.Quint)
	tweenPlay(panelStroke, {Transparency = 0.3}, 0.35)

	-- FAB state
	tweenPlay(toggleBtn, {BackgroundColor3 = THEME.accent, BackgroundTransparency = 0}, 0.2)
	tweenPlay(toggleLabel, {TextColor3 = THEME.textOnAccent}, 0.2)
	tweenPlay(toggleStroke, {Transparency = 0}, 0.2)
end

local function closePanel()
	if not panelOpen then return end
	panelOpen = false

	local closeTween = tween(panelFrame, {
		Size = UDim2.new(0, SIZES.panelWidth * 0.95, 0, SIZES.panelHeight * 0.95),
		BackgroundTransparency = 0.8,
	}, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	closeTween:Play()
	closeTween.Completed:Once(function()
		panelFrame.Visible = false
		panelFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	end)

	-- FAB state
	tweenPlay(toggleBtn, {BackgroundColor3 = THEME.surfaceElevated, BackgroundTransparency = 0.1}, 0.2)
	tweenPlay(toggleLabel, {TextColor3 = THEME.accent}, 0.2)
	tweenPlay(toggleStroke, {Transparency = 0.6}, 0.2)
end

local function togglePanel()
	if panelOpen then closePanel() else openPanel() end
end

toggleBtn.MouseButton1Click:Connect(togglePanel)
closeBtn.MouseButton1Click:Connect(closePanel)
minBtn.MouseButton1Click:Connect(closePanel)

--------------------------------------------------------------------------------
-- SECTION 18: Command Modal (Backdrop + Scale-in)
--------------------------------------------------------------------------------
local modalBackdrop = Instance.new("TextButton")
modalBackdrop.Name = "ModalBackdrop"
modalBackdrop.Size = UDim2.new(1, 0, 1, 0)
modalBackdrop.BackgroundColor3 = THEME.shadow
modalBackdrop.BackgroundTransparency = 1
modalBackdrop.Text = ""
modalBackdrop.AutoButtonColor = false
modalBackdrop.Visible = false
modalBackdrop.ZIndex = 50
modalBackdrop.Parent = screenGui

local commandModal = Components.frame({
	name = "CommandModal",
	size = UDim2.new(0, 380, 0, 0),
	position = UDim2.new(0.5, 0, 0.5, 0),
	anchor = Vector2.new(0.5, 0.5),
	bg = THEME.bgGlass,
	autoSize = Enum.AutomaticSize.Y,
	parent = screenGui,
})
commandModal.Visible = false
commandModal.Active = true
commandModal.ZIndex = 55
Components.corner(commandModal, SIZES.cornerLg)
Components.stroke(commandModal, THEME.border, 1, 0.3)

local modalPad = Components.padding(commandModal, 18, 18, 18, 18)
local modalLayout = Components.listLayout(commandModal, 12)

local modalTitle = Components.textLabel({
	text = "",
	font = FONTS.heading,
	textSize = 15,
	color = THEME.textPrimary,
	size = UDim2.new(1, 0, 0, 22),
	parent = commandModal,
})
modalTitle.LayoutOrder = 1

local modalDescription = Components.textLabel({
	text = "",
	font = FONTS.bodyLight,
	textSize = 12,
	color = THEME.textSecondary,
	size = UDim2.new(1, 0, 0, 16),
	parent = commandModal,
})
modalDescription.LayoutOrder = 2

local modalFields = Components.frame({
	name = "Fields",
	size = UDim2.new(1, 0, 0, 0),
	bg = THEME.bg,
	bgTransparency = 1,
	autoSize = Enum.AutomaticSize.Y,
	parent = commandModal,
})
modalFields.LayoutOrder = 3
Components.listLayout(modalFields, 10)

local modalButtonRow = Components.frame({
	name = "ButtonRow",
	size = UDim2.new(1, 0, 0, 36),
	bg = THEME.bg,
	bgTransparency = 1,
	parent = commandModal,
})
modalButtonRow.LayoutOrder = 4

local modalCancelBtn = Components.button({
	name = "CancelBtn",
	size = UDim2.new(0, 90, 0, 32),
	position = UDim2.new(1, -200, 0, 2),
	bg = THEME.surfaceElevated,
	hoverBg = THEME.surfaceActive,
	textColor = THEME.textSecondary,
	text = "Cancel",
	textSize = 12,
	corner = 7,
	parent = modalButtonRow,
})

local modalExecBtn = Components.button({
	name = "ExecuteBtn",
	size = UDim2.new(0, 100, 0, 32),
	position = UDim2.new(1, -100, 0, 2),
	bg = THEME.accent,
	textColor = THEME.textOnAccent,
	text = "Execute",
	textSize = 12,
	font = FONTS.subheading,
	corner = 7,
	parent = modalButtonRow,
})
table.insert(accentElements, {obj = modalExecBtn, prop = "BackgroundColor3"})

local currentModalCommand = nil
local modalInputFields = {}

local function closeCommandModal()
	currentModalCommand = nil
	modalInputFields = {}

	tweenPlay(modalBackdrop, {BackgroundTransparency = 1}, 0.2)
	tweenPlay(commandModal, {BackgroundTransparency = 0.8}, 0.15)
	task.delay(0.2, function()
		modalBackdrop.Visible = false
		commandModal.Visible = false
		commandModal.BackgroundTransparency = 0
		for _, child in ipairs(modalFields:GetChildren()) do
			if child.Name == "FieldRow" then child:Destroy() end
		end
	end)
end

local function buildCommandTextFromModal()
	local pieces = {}
	for _, inputBox in ipairs(modalInputFields) do
		local value = tostring(inputBox.Text or "")
		if value == "" then value = tostring(inputBox.PlaceholderText or "") end
		if value ~= "" then table.insert(pieces, value) end
	end
	local text = currentModalCommand.token
	if #pieces > 0 then text = text .. " " .. table.concat(pieces, " ") end
	return text
end

local function openCommandModal(def, prefillPlayer)
	currentModalCommand = def
	modalTitle.Text = def.display
	modalDescription.Text = def.description or ""

	for _, child in ipairs(modalFields:GetChildren()) do
		if child.Name == "FieldRow" then child:Destroy() end
	end
	modalInputFields = {}

	for idx, param in ipairs(def.params) do
		local row = Components.frame({
			name = "FieldRow",
			size = UDim2.new(1, 0, 0, 54),
			bg = THEME.bg,
			bgTransparency = 1,
			layoutOrder = idx,
			parent = modalFields,
		})

		Components.textLabel({
			text = param.name,
			font = FONTS.body,
			textSize = 11,
			color = THEME.textMuted,
			size = UDim2.new(1, 0, 0, 14),
			parent = row,
		})

		local input = Components.inputBox({
			name = "Input_" .. param.name,
			size = UDim2.new(1, 0, 0, 32),
			position = UDim2.new(0, 0, 0, 18),
			placeholder = param.placeholder or param.name,
			parent = row,
		})

		if prefillPlayer and idx == 1 and string.lower(param.name) == "player" then
			input.Text = prefillPlayer
		end

		table.insert(modalInputFields, input)
	end

	-- Show with animation
	modalBackdrop.Visible = true
	modalBackdrop.BackgroundTransparency = 1
	commandModal.Visible = true
	commandModal.Size = UDim2.new(0, 360, 0, 0)
	tweenPlay(modalBackdrop, {BackgroundTransparency = 0.5}, 0.25)
	tweenPlay(commandModal, {Size = UDim2.new(0, 380, 0, 0)}, 0.25, Enum.EasingStyle.Back)
end

modalBackdrop.MouseButton1Click:Connect(closeCommandModal)
modalCancelBtn.MouseButton1Click:Connect(closeCommandModal)
modalExecBtn.MouseButton1Click:Connect(function()
	if not currentModalCommand then return end
	local commandText = buildCommandTextFromModal()
	closeCommandModal()
	task.defer(function() runCommand(commandText) end)
end)



--------------------------------------------------------------------------------
-- SECTION 19: Logs System
--------------------------------------------------------------------------------
local logsScrollFrame -- forward declaration

local function addLogEntry(text, success)
	table.insert(commandLogs, 1, {
		timestamp = os.date("%H:%M:%S"),
		text = text,
		success = success ~= false,
	})
	if #commandLogs > MAX_LOGS then
		table.remove(commandLogs, #commandLogs)
	end
	-- Refresh logs UI
	if logsScrollFrame then
		for _, child in ipairs(logsScrollFrame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "UIListLayout" then child:Destroy() end
		end
		for idx, entry in ipairs(commandLogs) do
			local row = Components.frame({
				name = "Log_" .. idx,
				size = UDim2.new(1, 0, 0, 32),
				bg = THEME.surface,
				bgTransparency = 0.7,
				layoutOrder = idx,
				parent = logsScrollFrame,
			})
			Components.corner(row, SIZES.cornerXs)

			-- Status dot
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 6, 0, 6)
			dot.Position = UDim2.new(0, 8, 0.5, -3)
			dot.BackgroundColor3 = entry.success and THEME.success or THEME.danger
			dot.BorderSizePixel = 0
			dot.Parent = row
			Components.corner(dot, 3)

			-- Time
			Components.textLabel({
				text = entry.timestamp,
				font = FONTS.mono,
				textSize = 10,
				color = THEME.textMuted,
				size = UDim2.new(0, 55, 1, 0),
				position = UDim2.new(0, 20, 0, 0),
				parent = row,
			})

			-- Command text
			Components.textLabel({
				text = entry.text,
				font = FONTS.body,
				textSize = 12,
				color = THEME.textSecondary,
				size = UDim2.new(1, -90, 1, 0),
				position = UDim2.new(0, 78, 0, 0),
				truncate = Enum.TextTruncate.AtEnd,
				parent = row,
			})
		end
	end
end

--------------------------------------------------------------------------------
-- SECTION 20: Dashboard Tab
--------------------------------------------------------------------------------
local dashContent = tabFrames["Dashboard"]
Components.padding(dashContent, SIZES.padding, SIZES.padding, SIZES.padding, SIZES.padding)
local dashLayout = Components.listLayout(dashContent, 12)

-- Welcome section
local welcomeCard = Components.frame({
	name = "WelcomeCard",
	size = UDim2.new(1, 0, 0, 70),
	bg = THEME.surface,
	bgTransparency = 0.3,
	layoutOrder = 1,
	parent = dashContent,
})
Components.corner(welcomeCard, SIZES.cornerMd)
Components.stroke(welcomeCard, THEME.borderSubtle, 1, 0.7)

Components.textLabel({
	text = "Welcome back,",
	font = FONTS.bodyLight,
	textSize = 12,
	color = THEME.textSecondary,
	size = UDim2.new(1, -20, 0, 16),
	position = UDim2.new(0, 14, 0, 12),
	parent = welcomeCard,
})

local welcomeName = Components.textLabel({
	text = player.DisplayName,
	font = FONTS.heading,
	textSize = 18,
	color = THEME.textPrimary,
	size = UDim2.new(1, -20, 0, 24),
	position = UDim2.new(0, 14, 0, 30),
	parent = welcomeCard,
})

local dashRankBadge, dashRankText = Components.badge({
	text = string.upper(myRank),
	bg = getRankDisplayColor(myRank),
	textColor = THEME.textPrimary,
	bgTransparency = 0.6,
	size = UDim2.new(0, 70, 0, 20),
	parent = welcomeCard,
})
dashRankBadge.Position = UDim2.new(0, 14, 0, 56)
dashRankBadge.Visible = false -- Will show when rank loads
dashRankBadge.Position = UDim2.new(1, -84, 0, 14)

-- Stats row
local statsRow = Components.frame({
	name = "StatsRow",
	size = UDim2.new(1, 0, 0, 64),
	bg = THEME.bg,
	bgTransparency = 1,
	layoutOrder = 2,
	parent = dashContent,
})

local function createStatCard(props)
	local card = Components.frame({
		name = "Stat_" .. props.label,
		size = UDim2.new(0, props.width or 120, 0, 58),
		position = props.position,
		bg = THEME.surface,
		bgTransparency = 0.4,
		parent = statsRow,
	})
	Components.corner(card, SIZES.cornerSm)
	Components.stroke(card, THEME.borderSubtle, 1, 0.7)

	Components.textLabel({
		text = props.value,
		font = FONTS.heading,
		textSize = 20,
		color = props.color or THEME.accent,
		size = UDim2.new(1, -12, 0, 24),
		position = UDim2.new(0, 10, 0, 8),
		parent = card,
	})
	local valLabel = card:FindFirstChildWhichIsA("TextLabel")

	Components.textLabel({
		text = props.label,
		font = FONTS.bodyLight,
		textSize = 10,
		color = THEME.textMuted,
		size = UDim2.new(1, -12, 0, 14),
		position = UDim2.new(0, 10, 0, 34),
		parent = card,
	})

	return card, valLabel
end

local statOnline, statOnlineVal = createStatCard({
	label = "ONLINE",
	value = tostring(#Players:GetPlayers()),
	color = THEME.success,
	position = UDim2.new(0, 0, 0, 0),
	width = 130,
})

local statCommands, statCommandsVal = createStatCard({
	label = "COMMANDS RUN",
	value = "0",
	color = THEME.accent,
	position = UDim2.new(0, 138, 0, 0),
	width = 130,
})

local statRank, statRankVal = createStatCard({
	label = "YOUR RANK",
	value = string.upper(myRank),
	color = getRankDisplayColor(myRank),
	position = UDim2.new(0, 276, 0, 0),
	width = 130,
})

-- Quick actions
Components.textLabel({
	text = "Quick Actions",
	font = FONTS.subheading,
	textSize = 12,
	color = THEME.textSecondary,
	size = UDim2.new(1, 0, 0, 18),
	layoutOrder = 3,
	parent = dashContent,
})

local quickActionsRow = Components.frame({
	name = "QuickActions",
	size = UDim2.new(1, 0, 0, 38),
	bg = THEME.bg,
	bgTransparency = 1,
	layoutOrder = 4,
	parent = dashContent,
})
local qaLayout = Components.listLayout(quickActionsRow, 8, Enum.FillDirection.Horizontal)

local quickActions = {
	{text = "Fly", cmd = "fly", color = THEME.catMovement},
	{text = "Noclip", cmd = "noclip", color = THEME.catMovement},
	{text = "Freeze All", cmd = "freezeall", color = THEME.catModeration},
	{text = "Unfreeze All", cmd = "unfreezeall", color = THEME.catModeration},
}

for i, qa in ipairs(quickActions) do
	local btn = Components.button({
		name = "QA_" .. qa.text,
		size = UDim2.new(0, 95, 0, 32),
		bg = qa.color,
		textColor = THEME.textOnAccent,
		text = qa.text,
		textSize = 11,
		corner = 6,
		layoutOrder = i,
		parent = quickActionsRow,
	})
	btn.BackgroundTransparency = 0.2
	btn.MouseButton1Click:Connect(function()
		task.defer(function() runCommand(qa.cmd) end)
	end)
end

-- Recent commands section
Components.textLabel({
	text = "Recent Commands",
	font = FONTS.subheading,
	textSize = 12,
	color = THEME.textSecondary,
	size = UDim2.new(1, 0, 0, 18),
	layoutOrder = 5,
	parent = dashContent,
})

local recentFrame = Components.frame({
	name = "RecentCmds",
	size = UDim2.new(1, 0, 0, 100),
	bg = THEME.surface,
	bgTransparency = 0.5,
	layoutOrder = 6,
	parent = dashContent,
})
Components.corner(recentFrame, SIZES.cornerSm)
Components.padding(recentFrame, 8, 8, 8, 8)
local recentLayout = Components.listLayout(recentFrame, 4)

local recentEmptyLabel = Components.textLabel({
	text = "No commands executed yet",
	font = FONTS.bodyLight,
	textSize = 11,
	color = THEME.textMuted,
	size = UDim2.new(1, 0, 0, 80),
	xAlign = Enum.TextXAlignment.Center,
	yAlign = Enum.TextYAlignment.Center,
	parent = recentFrame,
})

-- Update player count dynamically
Players.PlayerAdded:Connect(function()
	playerCountLabel.Text = tostring(#Players:GetPlayers()) .. " online"
	if statOnlineVal then
		for _, c in ipairs(statOnline:GetChildren()) do
			if c:IsA("TextLabel") and c.TextSize == 20 then c.Text = tostring(#Players:GetPlayers()) break end
		end
	end
end)
Players.PlayerRemoving:Connect(function()
	task.defer(function()
		playerCountLabel.Text = tostring(#Players:GetPlayers()) .. " online"
		for _, c in ipairs(statOnline:GetChildren()) do
			if c:IsA("TextLabel") and c.TextSize == 20 then c.Text = tostring(#Players:GetPlayers()) break end
		end
	end)
end)



--------------------------------------------------------------------------------
-- SECTION 21: Commands Tab
--------------------------------------------------------------------------------
local commandsContent = tabFrames["Commands"]
Components.padding(commandsContent, SIZES.paddingSm, SIZES.paddingSm, SIZES.padding, SIZES.padding)
local cmdTabLayout = Components.listLayout(commandsContent, 8)

-- Search bar
local searchRow = Components.frame({
	name = "SearchRow",
	size = UDim2.new(1, 0, 0, SIZES.inputHeight),
	bg = THEME.bg,
	bgTransparency = 1,
	layoutOrder = 1,
	parent = commandsContent,
})

local searchBox = Components.inputBox({
	name = "SearchBox",
	size = UDim2.new(1, 0, 0, SIZES.inputHeight),
	placeholder = "Search commands...",
	parent = searchRow,
})

-- Commands scroll
local commandsScroll = Components.scrollFrame({
	name = "CommandsScroll",
	size = UDim2.new(1, 0, 1, -(SIZES.inputHeight + 16)),
	position = UDim2.new(0, 0, 0, 0),
	layoutOrder = 2,
	parent = commandsContent,
})
local commandsScrollLayout = Components.listLayout(commandsScroll, 4)

-- Build commands by category
local categoryOrder = {"Moderation", "Player", "Movement", "Fun", "Server"}
local commandsByCategory = {}
for _, cat in ipairs(categoryOrder) do commandsByCategory[cat] = {} end
for _, def in ipairs(COMMAND_DEFINITIONS) do
	local cat = def.category or "Server"
	if commandsByCategory[cat] then table.insert(commandsByCategory[cat], def) end
end

local categoryHeaders = {}
local commandRowElements = {}

local function buildCommandsUI()
	for _, child in ipairs(commandsScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	categoryHeaders = {}
	commandRowElements = {}

	local layoutOrder = 0
	for _, catName in ipairs(categoryOrder) do
		local cmds = commandsByCategory[catName]
		local catColor = CATEGORY_COLORS[catName] or THEME.accent
		local isCollapsed = collapsedCategories[catName] or false

		-- Category header
		local headerFrame = Components.frame({
			name = "Header_" .. catName,
			size = UDim2.new(1, 0, 0, 32),
			bg = THEME.bg,
			bgTransparency = 1,
			layoutOrder = layoutOrder,
			parent = commandsScroll,
		})
		layoutOrder = layoutOrder + 1

		local headerBtn = Instance.new("TextButton")
		headerBtn.Size = UDim2.new(1, 0, 1, 0)
		headerBtn.BackgroundTransparency = 1
		headerBtn.Text = ""
		headerBtn.AutoButtonColor = false
		headerBtn.Parent = headerFrame

		-- Color bar
		local catBar = Instance.new("Frame")
		catBar.Size = UDim2.new(0, 3, 0, 18)
		catBar.Position = UDim2.new(0, 0, 0.5, -9)
		catBar.BackgroundColor3 = catColor
		catBar.BorderSizePixel = 0
		catBar.Parent = headerFrame
		Components.corner(catBar, 2)

		-- Arrow
		local arrow = Components.textLabel({
			text = isCollapsed and "+" or "−",
			font = FONTS.body,
			textSize = 14,
			color = THEME.textMuted,
			size = UDim2.new(0, 16, 1, 0),
			position = UDim2.new(0, 10, 0, 0),
			xAlign = Enum.TextXAlignment.Center,
			parent = headerFrame,
		})

		-- Category name
		Components.textLabel({
			text = catName,
			font = FONTS.subheading,
			textSize = 12,
			color = catColor,
			size = UDim2.new(0, 100, 1, 0),
			position = UDim2.new(0, 28, 0, 0),
			parent = headerFrame,
		})

		-- Count
		Components.textLabel({
			text = tostring(#cmds),
			font = FONTS.bodyLight,
			textSize = 10,
			color = THEME.textMuted,
			size = UDim2.new(0, 24, 1, 0),
			position = UDim2.new(1, -28, 0, 0),
			xAlign = Enum.TextXAlignment.Right,
			parent = headerFrame,
		})

		categoryHeaders[catName] = {frame = headerFrame, arrow = arrow, rows = {}}

		-- Command rows
		for _, def in ipairs(cmds) do
			local row = Components.frame({
				name = "Cmd_" .. def.token,
				size = UDim2.new(1, 0, 0, 38),
				bg = THEME.surface,
				bgTransparency = 0.7,
				layoutOrder = layoutOrder,
				parent = commandsScroll,
			})
			row.Visible = not isCollapsed
			Components.corner(row, SIZES.cornerSm)
			layoutOrder = layoutOrder + 1

			-- Hover effect
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					tweenPlay(row, {BackgroundTransparency = 0.3}, 0.1)
				end
			end)
			row.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					tweenPlay(row, {BackgroundTransparency = 0.7}, 0.1)
				end
			end)

			-- Dot
			local dot = Instance.new("Frame")
			dot.Size = UDim2.new(0, 5, 0, 5)
			dot.Position = UDim2.new(0, 8, 0.5, -2)
			dot.BackgroundColor3 = catColor
			dot.BorderSizePixel = 0
			dot.Parent = row
			Components.corner(dot, 3)

			-- Token name
			Components.textLabel({
				text = def.token,
				font = FONTS.subheading,
				textSize = 12,
				color = THEME.textPrimary,
				size = UDim2.new(0, 100, 1, 0),
				position = UDim2.new(0, 20, 0, 0),
				parent = row,
			})

			-- Description
			Components.textLabel({
				text = def.description,
				font = FONTS.bodyLight,
				textSize = 11,
				color = THEME.textMuted,
				size = UDim2.new(1, -200, 1, 0),
				position = UDim2.new(0, 122, 0, 0),
				truncate = Enum.TextTruncate.AtEnd,
				parent = row,
			})

			-- Run button
			local runBtn = Components.button({
				name = "RunBtn",
				size = UDim2.new(0, 52, 0, 24),
				position = UDim2.new(1, -60, 0.5, -12),
				bg = THEME.surfaceElevated,
				hoverBg = THEME.accent,
				textColor = THEME.textSecondary,
				text = "Run",
				textSize = 11,
				corner = 5,
				parent = row,
			})
			Components.stroke(runBtn, THEME.borderSubtle, 1, 0.7)

			runBtn.MouseButton1Click:Connect(function()
				if #def.params == 0 then
					task.defer(function() runCommand(def.token) end)
				else
					openCommandModal(def)
				end
			end)

			table.insert(categoryHeaders[catName].rows, row)
			table.insert(commandRowElements, {frame = row, def = def})
		end

		-- Collapse toggle
		headerBtn.MouseButton1Click:Connect(function()
			collapsedCategories[catName] = not collapsedCategories[catName]
			local collapsed = collapsedCategories[catName]
			arrow.Text = collapsed and "+" or "−"
			for _, r in ipairs(categoryHeaders[catName].rows) do
				r.Visible = not collapsed
			end
		end)
	end
end

buildCommandsUI()

-- Search filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(searchBox.Text or "")
	if query == "" then
		for catName, data in pairs(categoryHeaders) do
			data.frame.Visible = true
			local collapsed = collapsedCategories[catName] or false
			for _, r in ipairs(data.rows) do r.Visible = not collapsed end
		end
		return
	end
	for catName, data in pairs(categoryHeaders) do
		local anyVisible = false
		for _, r in ipairs(data.rows) do
			local def = nil
			for _, elem in ipairs(commandRowElements) do
				if elem.frame == r then def = elem.def break end
			end
			if def then
				local matches = string.find(string.lower(def.token), query, 1, true)
					or string.find(string.lower(def.description), query, 1, true)
				r.Visible = matches ~= nil
				if matches then anyVisible = true end
			end
		end
		data.frame.Visible = anyVisible
	end
end)



--------------------------------------------------------------------------------
-- SECTION 22: Players Tab
--------------------------------------------------------------------------------
local playersContent = tabFrames["Players"]
Components.padding(playersContent, SIZES.paddingSm, SIZES.paddingSm, SIZES.padding, SIZES.padding)

local playersScroll = Components.scrollFrame({
	name = "PlayersScroll",
	size = UDim2.new(1, 0, 1, 0),
	parent = playersContent,
})
local playersLayout = Components.listLayout(playersScroll, 6)

local function addPlayerRow(targetPlayer)
	if playerRows[targetPlayer.UserId] then return end

	local row = Components.frame({
		name = "Player_" .. targetPlayer.UserId,
		size = UDim2.new(1, 0, 0, 56),
		bg = THEME.surface,
		bgTransparency = 0.5,
		parent = playersScroll,
	})
	Components.corner(row, SIZES.cornerMd)

	-- Hover
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tweenPlay(row, {BackgroundTransparency = 0.2}, 0.12)
		end
	end)
	row.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			tweenPlay(row, {BackgroundTransparency = 0.5}, 0.12)
		end
	end)

	-- Avatar thumbnail
	local avatarFrame = Instance.new("ImageLabel")
	avatarFrame.Name = "Avatar"
	avatarFrame.Size = UDim2.new(0, 38, 0, 38)
	avatarFrame.Position = UDim2.new(0, 10, 0.5, -19)
	avatarFrame.BackgroundColor3 = THEME.surfaceElevated
	avatarFrame.BorderSizePixel = 0
	avatarFrame.Image = ""
	avatarFrame.Parent = row
	Components.corner(avatarFrame, 19)

	-- Load avatar async
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(
				targetPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size48x48
			)
		end)
		if ok and url and avatarFrame.Parent then
			avatarFrame.Image = url
		end
	end)

	-- Name
	Components.textLabel({
		text = targetPlayer.DisplayName,
		font = FONTS.subheading,
		textSize = 13,
		color = THEME.textPrimary,
		size = UDim2.new(0, 120, 0, 18),
		position = UDim2.new(0, 56, 0, 10),
		truncate = Enum.TextTruncate.AtEnd,
		parent = row,
	})

	-- Username (smaller)
	Components.textLabel({
		text = "@" .. targetPlayer.Name,
		font = FONTS.bodyLight,
		textSize = 10,
		color = THEME.textMuted,
		size = UDim2.new(0, 120, 0, 14),
		position = UDim2.new(0, 56, 0, 30),
		truncate = Enum.TextTruncate.AtEnd,
		parent = row,
	})

	-- Rank badge
	local pRank = targetPlayer:GetAttribute("AdminRank") or "guest"
	local rankColor = getRankDisplayColor(pRank)
	local badge, badgeText = Components.badge({
		text = string.upper(tostring(pRank)),
		bg = rankColor,
		textColor = THEME.textPrimary,
		bgTransparency = 0.7,
		size = UDim2.new(0, 58, 0, 16),
		parent = row,
	})
	badge.Position = UDim2.new(0, 56, 0, 46)
	badge.Visible = (pRank ~= "guest")

	-- Quick action buttons
	local actions = {
		{text = "K", color = THEME.danger, cmd = "kick", tip = "Kick"},
		{text = "B", color = THEME.danger, cmd = "ban", tip = "Ban"},
		{text = "→", color = THEME.accent, cmd = "to", tip = "Teleport"},
		{text = "←", color = THEME.accent, cmd = "bring", tip = "Bring"},
		{text = "❄", color = THEME.info, cmd = "freeze", tip = "Freeze"},
	}

	for i, action in ipairs(actions) do
		local btn = Components.button({
			name = "Act_" .. action.cmd,
			size = UDim2.new(0, 28, 0, 28),
			position = UDim2.new(1, -36 * (6 - i), 0.5, -14),
			bg = action.color,
			textColor = THEME.textOnAccent,
			text = action.text,
			textSize = 12,
			corner = 7,
			parent = row,
		})
		btn.BackgroundTransparency = 0.7

		-- Override hover to reduce transparency
		btn.MouseEnter:Connect(function()
			tweenPlay(btn, {BackgroundTransparency = 0.15}, 0.12)
		end)
		btn.MouseLeave:Connect(function()
			tweenPlay(btn, {BackgroundTransparency = 0.7}, 0.12)
		end)

		btn.MouseButton1Click:Connect(function()
			local cmdDef = nil
			for _, def in ipairs(COMMAND_DEFINITIONS) do
				if def.token == action.cmd then cmdDef = def break end
			end
			if cmdDef then
				if #cmdDef.params <= 1 then
					task.defer(function() runCommand(action.cmd .. " " .. targetPlayer.Name) end)
				else
					openCommandModal(cmdDef, targetPlayer.Name)
				end
			end
		end)
	end

	playerRows[targetPlayer.UserId] = row
end

local function removePlayerRow(targetPlayer)
	local row = playerRows[targetPlayer.UserId]
	if row then row:Destroy() end
	playerRows[targetPlayer.UserId] = nil
end

-- Initialize
for _, p in ipairs(Players:GetPlayers()) do addPlayerRow(p) end
Players.PlayerAdded:Connect(addPlayerRow)
Players.PlayerRemoving:Connect(removePlayerRow)

--------------------------------------------------------------------------------
-- SECTION 23: Settings Tab
--------------------------------------------------------------------------------
local settingsContent = tabFrames["Settings"]
Components.padding(settingsContent, SIZES.padding, SIZES.padding, SIZES.padding, SIZES.padding)

local settingsScroll = Components.scrollFrame({
	name = "SettingsScroll",
	size = UDim2.new(1, 0, 1, 0),
	parent = settingsContent,
})
local settingsLayout = Components.listLayout(settingsScroll, 10)

local function createSettingsSection(text, order)
	local label = Components.textLabel({
		text = text,
		font = FONTS.subheading,
		textSize = 12,
		color = THEME.textSecondary,
		size = UDim2.new(1, 0, 0, 22),
		layoutOrder = order,
		parent = settingsScroll,
	})
	return label
end

local function createSettingsSlider(label, min, max, default, order, onChange)
	local container = Components.frame({
		name = "Slider_" .. label,
		size = UDim2.new(1, 0, 0, 42),
		bg = THEME.bg,
		bgTransparency = 1,
		layoutOrder = order,
		parent = settingsScroll,
	})

	Components.textLabel({
		text = label,
		font = FONTS.body,
		textSize = 12,
		color = THEME.textSecondary,
		size = UDim2.new(0, 140, 0, 18),
		parent = container,
	})

	local valueLabel = Components.textLabel({
		text = tostring(default),
		font = FONTS.subheading,
		textSize = 12,
		color = THEME.textPrimary,
		size = UDim2.new(0, 40, 0, 18),
		position = UDim2.new(1, -40, 0, 0),
		xAlign = Enum.TextXAlignment.Right,
		parent = container,
	})

	-- Track
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -10, 0, 4)
	track.Position = UDim2.new(0, 5, 0, 30)
	track.BackgroundColor3 = THEME.surfaceElevated
	track.BorderSizePixel = 0
	track.Parent = container
	Components.corner(track, 2)

	-- Fill
	local pct = (default - min) / (max - min)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(pct, 0, 1, 0)
	fill.BackgroundColor3 = THEME.accent
	fill.BorderSizePixel = 0
	fill.Parent = track
	Components.corner(fill, 2)
	table.insert(accentElements, {obj = fill, prop = "BackgroundColor3"})

	-- Knob
	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(pct, 0, 0.5, 0)
	knob.BackgroundColor3 = THEME.accent
	knob.BorderSizePixel = 0
	knob.Parent = track
	Components.corner(knob, 7)
	table.insert(accentElements, {obj = knob, prop = "BackgroundColor3"})

	-- Drag logic
	local dragging = false
	local knobBtn = Instance.new("TextButton")
	knobBtn.Size = UDim2.new(0, 24, 0, 24)
	knobBtn.Position = UDim2.new(0.5, -12, 0.5, -12)
	knobBtn.AnchorPoint = Vector2.new(0, 0)
	knobBtn.BackgroundTransparency = 1
	knobBtn.Text = ""
	knobBtn.Parent = knob

	knobBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local trackAbsPos = track.AbsolutePosition.X
			local trackAbsSize = track.AbsoluteSize.X
			local mouseX = input.Position.X
			local relX = math.clamp((mouseX - trackAbsPos) / trackAbsSize, 0, 1)
			knob.Position = UDim2.new(relX, 0, 0.5, 0)
			fill.Size = UDim2.new(relX, 0, 1, 0)
			local value = math.floor(min + relX * (max - min) + 0.5)
			valueLabel.Text = tostring(value)
			if onChange then onChange(value) end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return container
end

local function createSettingsToggle(label, default, order, onChange)
	local container = Components.frame({
		name = "Toggle_" .. label,
		size = UDim2.new(1, 0, 0, 32),
		bg = THEME.bg,
		bgTransparency = 1,
		layoutOrder = order,
		parent = settingsScroll,
	})

	Components.textLabel({
		text = label,
		font = FONTS.body,
		textSize = 12,
		color = THEME.textSecondary,
		size = UDim2.new(1, -60, 1, 0),
		parent = container,
	})

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 38, 0, 20)
	toggleBg.Position = UDim2.new(1, -42, 0.5, -10)
	toggleBg.BackgroundColor3 = default and THEME.accent or THEME.surfaceElevated
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = container
	Components.corner(toggleBg, 10)
	if default then table.insert(accentElements, {obj = toggleBg, prop = "BackgroundColor3"}) end

	local toggleKnob = Instance.new("Frame")
	toggleKnob.Size = UDim2.new(0, 16, 0, 16)
	toggleKnob.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
	toggleKnob.BackgroundColor3 = THEME.textPrimary
	toggleKnob.BorderSizePixel = 0
	toggleKnob.Parent = toggleBg
	Components.corner(toggleKnob, 8)

	local state = default
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(1, 0, 1, 0)
	toggleBtn.BackgroundTransparency = 1
	toggleBtn.Text = ""
	toggleBtn.Parent = toggleBg

	toggleBtn.MouseButton1Click:Connect(function()
		state = not state
		tweenPlay(toggleKnob, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.2)
		tweenPlay(toggleBg, {BackgroundColor3 = state and THEME.accent or THEME.surfaceElevated}, 0.2)
		if onChange then onChange(state) end
	end)

	return container
end

-- Build settings
createSettingsSection("Fly Settings", 1)
createSettingsSlider("Fly Speed", 10, 200, FLY_SPEED, 2, function(v) FLY_SPEED = v end)
createSettingsSlider("Fly Boost", 50, 400, FLY_BOOST_SPEED, 3, function(v) FLY_BOOST_SPEED = v end)

createSettingsSection("Movement", 4)
createSettingsToggle("Noclip", noclip, 5, function(state)
	noclip = state
	notify("Movement", state and "Noclip enabled" or "Noclip disabled", state and "success" or "info")
end)

createSettingsSection("Appearance", 6)

-- Accent color picker
local colorRow = Components.frame({
	name = "AccentPicker",
	size = UDim2.new(1, 0, 0, 36),
	bg = THEME.bg,
	bgTransparency = 1,
	layoutOrder = 7,
	parent = settingsScroll,
})

Components.textLabel({
	text = "Accent Color",
	font = FONTS.body,
	textSize = 12,
	color = THEME.textSecondary,
	size = UDim2.new(0, 90, 1, 0),
	parent = colorRow,
})

local colorCircleData = {}
for i, opt in ipairs(ACCENT_OPTIONS) do
	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 22, 0, 22)
	circle.Position = UDim2.new(0, 90 + (i - 1) * 30, 0.5, -11)
	circle.BackgroundColor3 = opt.color
	circle.BorderSizePixel = 0
	circle.Parent = colorRow
	Components.corner(circle, 11)

	local ring = Components.stroke(circle, THEME.textPrimary, (i == 1) and 2 or 0, 0)

	local circleBtn = Instance.new("TextButton")
	circleBtn.Size = UDim2.new(1, 0, 1, 0)
	circleBtn.BackgroundTransparency = 1
	circleBtn.Text = ""
	circleBtn.Parent = circle

	circleBtn.MouseButton1Click:Connect(function()
		for _, d in ipairs(colorCircleData) do d.ring.Thickness = 0 end
		ring.Thickness = 2
		THEME.accent = opt.color
		THEME.accentSoft = opt.color
		THEME.accentGlow = lerpColor(opt.color, THEME.textPrimary, 0.3)
		THEME.accentDim = lerpColor(opt.color, THEME.bg, 0.6)
		-- Update all registered accent elements
		for _, elem in ipairs(accentElements) do
			if elem.obj and elem.obj.Parent then
				pcall(function() elem.obj[elem.prop] = opt.color end)
			end
		end
		-- Update specific elements
		toggleLabel.TextColor3 = opt.color
		if not panelOpen then toggleStroke.Color = opt.color end
		glowStroke.Color = opt.color
		sidebarIndicator.BackgroundColor3 = opt.color
		-- Update active tab button color
		if tabButtons[activeTab] then
			tabButtons[activeTab].TextColor3 = opt.color
		end
	end)

	table.insert(colorCircleData, {frame = circle, ring = ring})
end



--------------------------------------------------------------------------------
-- SECTION 24: Logs Tab
--------------------------------------------------------------------------------
local logsContent = tabFrames["Logs"]
Components.padding(logsContent, SIZES.paddingSm, SIZES.paddingSm, SIZES.padding, SIZES.padding)
local logsTabLayout = Components.listLayout(logsContent, 8)

-- Logs header with clear button
local logsHeader = Components.frame({
	name = "LogsHeader",
	size = UDim2.new(1, 0, 0, 28),
	bg = THEME.bg,
	bgTransparency = 1,
	layoutOrder = 1,
	parent = logsContent,
})

Components.textLabel({
	text = "Command History",
	font = FONTS.subheading,
	textSize = 12,
	color = THEME.textSecondary,
	size = UDim2.new(0, 140, 1, 0),
	parent = logsHeader,
})

local clearLogsBtn = Components.button({
	name = "ClearLogs",
	size = UDim2.new(0, 60, 0, 24),
	position = UDim2.new(1, -60, 0.5, -12),
	bg = THEME.surfaceElevated,
	hoverBg = THEME.danger,
	textColor = THEME.textMuted,
	text = "Clear",
	textSize = 10,
	corner = 5,
	parent = logsHeader,
})

clearLogsBtn.MouseButton1Click:Connect(function()
	commandLogs = {}
	if logsScrollFrame then
		for _, child in ipairs(logsScrollFrame:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end
	end
	notify("Logs", "Command history cleared", "info")
end)

-- Logs scroll
logsScrollFrame = Components.scrollFrame({
	name = "LogsScroll",
	size = UDim2.new(1, 0, 1, -36),
	layoutOrder = 2,
	parent = logsContent,
})
local logsScrollLayout = Components.listLayout(logsScrollFrame, 3)

--------------------------------------------------------------------------------
-- SECTION 25: Quick Command Bar (Premium)
--------------------------------------------------------------------------------
local quickBar = Components.frame({
	name = "QuickCommandBar",
	size = UDim2.new(0, 460, 0, 52),
	position = UDim2.new(0.5, 0, 0, -64),
	anchor = Vector2.new(0.5, 0),
	bg = THEME.bgGlass,
	bgTransparency = 0.05,
	clip = true,
	parent = screenGui,
})
Components.corner(quickBar, SIZES.cornerMd)
local quickBarStroke = Components.stroke(quickBar, THEME.borderSubtle, 1, 0.4)

-- Glow border when focused
local quickBarGlow = Components.stroke(quickBar, THEME.accent, 1.5, 1)

local cmdInput = Components.inputBox({
	name = "CmdInput",
	size = UDim2.new(1, -20, 0, 30),
	position = UDim2.new(0, 10, 0, 5),
	placeholder = "Type a command... (TAB to autocomplete)",
	bg = THEME.surface,
	parent = quickBar,
})

local cmdHintLabel = Components.textLabel({
	text = "",
	font = FONTS.bodyLight,
	textSize = 10,
	color = THEME.textMuted,
	size = UDim2.new(1, -24, 0, 14),
	position = UDim2.new(0, 12, 0, 37),
	parent = quickBar,
})

-- Suggestion dropdown (shown below quick bar)
local suggestionFrame = Components.frame({
	name = "Suggestions",
	size = UDim2.new(0, 460, 0, 0),
	position = UDim2.new(0.5, 0, 0, 60),
	anchor = Vector2.new(0.5, 0),
	bg = THEME.bgGlass,
	bgTransparency = 0.05,
	autoSize = Enum.AutomaticSize.Y,
	clip = true,
	parent = screenGui,
})
suggestionFrame.Visible = false
Components.corner(suggestionFrame, SIZES.cornerSm)
Components.stroke(suggestionFrame, THEME.borderSubtle, 1, 0.5)
Components.padding(suggestionFrame, 4, 4, 4, 4)
local suggestionLayout = Components.listLayout(suggestionFrame, 2)

--------------------------------------------------------------------------------
-- SECTION 26: Command Autocomplete & Suggestions
--------------------------------------------------------------------------------
local function getCommandSuggestion(text)
	local raw = tostring(text or "")
	local first = raw:match("^%s*(%S+)")
	if not first then return nil end
	local partial = string.lower(first)
	if partial == "" then return nil end
	if commandLookup[partial] then return partial end
	for _, cmdName in ipairs(commandNames) do
		if cmdName:sub(1, #partial) == partial then return cmdName end
	end
	return nil
end

local function getMatchingCommands(text, maxResults)
	maxResults = maxResults or 5
	local results = {}
	local partial = string.lower(tostring(text or ""))
	if partial == "" then return results end
	for _, def in ipairs(COMMAND_DEFINITIONS) do
		if #results >= maxResults then break end
		if string.find(def.token, partial, 1, true) or string.find(string.lower(def.description), partial, 1, true) then
			table.insert(results, def)
		end
	end
	return results
end

local function updateSuggestions()
	-- Clear existing
	for _, child in ipairs(suggestionFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	if not quickBarOpen then
		suggestionFrame.Visible = false
		return
	end

	local current = cmdInput.Text or ""
	if current:find("%s") or current == "" then
		suggestionFrame.Visible = false
		return
	end

	local matches = getMatchingCommands(current, 5)
	if #matches == 0 then
		suggestionFrame.Visible = false
		return
	end

	suggestionFrame.Visible = true
	for i, def in ipairs(matches) do
		local row = Components.frame({
			name = "Sug_" .. def.token,
			size = UDim2.new(1, 0, 0, 30),
			bg = THEME.surface,
			bgTransparency = 0.6,
			layoutOrder = i,
			parent = suggestionFrame,
		})
		Components.corner(row, 4)

		-- Hover
		local rowBtn = Instance.new("TextButton")
		rowBtn.Size = UDim2.new(1, 0, 1, 0)
		rowBtn.BackgroundTransparency = 1
		rowBtn.Text = ""
		rowBtn.AutoButtonColor = false
		rowBtn.Parent = row

		rowBtn.MouseEnter:Connect(function()
			tweenPlay(row, {BackgroundTransparency = 0.2}, 0.08)
		end)
		rowBtn.MouseLeave:Connect(function()
			tweenPlay(row, {BackgroundTransparency = 0.6}, 0.08)
		end)

		-- Category dot
		local catColor = CATEGORY_COLORS[def.category] or THEME.accent
		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 4, 0, 4)
		dot.Position = UDim2.new(0, 8, 0.5, -2)
		dot.BackgroundColor3 = catColor
		dot.BorderSizePixel = 0
		dot.Parent = row
		Components.corner(dot, 2)

		Components.textLabel({
			text = def.token,
			font = FONTS.subheading,
			textSize = 12,
			color = THEME.textPrimary,
			size = UDim2.new(0, 100, 1, 0),
			position = UDim2.new(0, 18, 0, 0),
			parent = row,
		})

		Components.textLabel({
			text = def.description,
			font = FONTS.bodyLight,
			textSize = 10,
			color = THEME.textMuted,
			size = UDim2.new(1, -130, 1, 0),
			position = UDim2.new(0, 120, 0, 0),
			truncate = Enum.TextTruncate.AtEnd,
			parent = row,
		})

		rowBtn.MouseButton1Click:Connect(function()
			cmdInput.Text = def.token .. " "
			cmdInput.CursorPosition = #cmdInput.Text + 1
			cmdInput:CaptureFocus()
			updateSuggestions()
		end)
	end
end

local function updateCmdHint()
	if not quickBarOpen then cmdHintLabel.Text = "" return end
	local current = cmdInput.Text or ""
	local firstToken = current:match("^%s*(%S+)")
	if not firstToken or firstToken == "" then
		cmdHintLabel.Text = "TAB: Autocomplete  |  ↑↓: History  |  Chat: ! or ;"
		return
	end
	if current:find("%s") then cmdHintLabel.Text = "" return end
	local suggestion = getCommandSuggestion(firstToken)
	if suggestion and suggestion ~= string.lower(firstToken) then
		cmdHintLabel.Text = "→ " .. suggestion .. "  (TAB)"
	else
		cmdHintLabel.Text = ""
	end
end

cmdInput:GetPropertyChangedSignal("Text"):Connect(function()
	updateCmdHint()
	updateSuggestions()
end)
cmdInput.Focused:Connect(function()
	updateCmdHint()
	tweenPlay(quickBarGlow, {Transparency = 0.3}, 0.2)
end)
cmdInput.FocusLost:Connect(function()
	tweenPlay(quickBarGlow, {Transparency = 1}, 0.2)
end)

local function openQuickBar()
	if quickBarOpen then return end
	quickBarOpen = true
	tweenPlay(quickBar, {Position = UDim2.new(0.5, 0, 0, 10)}, 0.3, Enum.EasingStyle.Quint)
	tweenPlay(quickBarStroke, {Transparency = 0.2}, 0.2)
	cmdInput:CaptureFocus()
	updateCmdHint()
end

local function closeQuickBar()
	if not quickBarOpen then return end
	quickBarOpen = false
	tweenPlay(quickBar, {Position = UDim2.new(0.5, 0, 0, -64)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenPlay(quickBarStroke, {Transparency = 0.4}, 0.2)
	cmdInput:ReleaseFocus()
	cmdHintLabel.Text = ""
	suggestionFrame.Visible = false
end



--------------------------------------------------------------------------------
-- SECTION 27: Fly / Noclip System
--------------------------------------------------------------------------------
local function setNoclip(enabled)
	noclip = enabled
	notify("Movement", enabled and "Noclip enabled" or "Noclip disabled", enabled and "success" or "info")
end

RunService.Stepped:Connect(function()
	if not noclip then return end
	local character = player.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then part.CanCollide = false end
	end
end)

local function destroyFlyBodies()
	local function safeDestroy(inst)
		if typeof(inst) ~= "Instance" then return end
		if inst.Parent ~= nil then inst:Destroy() end
	end
	safeDestroy(flyLinearVelocity); flyLinearVelocity = nil
	safeDestroy(flyAlignOrientation); flyAlignOrientation = nil
	safeDestroy(flyAttachment); flyAttachment = nil
end

player.CharacterAdded:Connect(function()
	if not flying then return end
	flying = false
	flyVelocitySmooth = Vector3.zero
	destroyFlyBodies()
end)

local function setFly(enabled)
	flying = enabled
	local root, humanoid = getCharacterRoot()
	if not root or not humanoid then return end

	if enabled then
		destroyFlyBodies()
		flySavedAutoRotate = humanoid.AutoRotate
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true

		flyAttachment = Instance.new("Attachment")
		flyAttachment.Name = "AdminFlyAttachment"
		flyAttachment.Parent = root

		flyLinearVelocity = Instance.new("LinearVelocity")
		flyLinearVelocity.Name = "AdminFlyLinearVelocity"
		flyLinearVelocity.Attachment0 = flyAttachment
		flyLinearVelocity.MaxForce = 1e6
		flyLinearVelocity.VectorVelocity = Vector3.zero
		flyLinearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
		flyLinearVelocity.Parent = root

		flyAlignOrientation = Instance.new("AlignOrientation")
		flyAlignOrientation.Name = "AdminFlyAlignOrientation"
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
		humanoid.PlatformStand = false
		humanoid.AutoRotate = flySavedAutoRotate
		destroyFlyBodies()
		flyVelocitySmooth = Vector3.zero
		notify("Movement", "Fly disabled", "info")
	end
end

RunService.RenderStepped:Connect(function(dt)
	dt = math.clamp(dt, 1 / 240, 1 / 24)
	if not flying or not flyLinearVelocity or not flyAlignOrientation then return end

	local root = flyAttachment and flyAttachment.Parent
	if not root then return end

	local cam = workspace.CurrentCamera
	local blockFlyInput = cmdInput:IsFocused()

	local moveDirection = Vector3.zero
	if not blockFlyInput then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
			moveDirection -= Vector3.yAxis
		end
	end

	local boosted = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	local cruise = boosted and FLY_BOOST_SPEED or FLY_SPEED

	if moveDirection.Magnitude > 1e-4 then
		moveDirection = moveDirection.Unit
		local targetVel = moveDirection * cruise
		local accel = 1 - math.exp(-dt / math.max(FLY_RESPONSE, 1e-4))
		flyVelocitySmooth = flyVelocitySmooth:Lerp(targetVel, math.clamp(accel, 0, 1))
	else
		local drag = math.exp(-FLY_DRAG * dt)
		flyVelocitySmooth *= drag
	end

	flyLinearVelocity.VectorVelocity = flyVelocitySmooth

	local camCF = cam.CFrame
	local rotTau = 0.09
	local rotBlend = 1 - math.exp(-dt / math.max(rotTau, 1e-4))
	flyLastCamCFrame = flyLastCamCFrame:Lerp(camCF, math.clamp(rotBlend, 0, 1))
	flyAlignOrientation.CFrame = flyLastCamCFrame
end)

--------------------------------------------------------------------------------
-- SECTION 28: Command Execution
--------------------------------------------------------------------------------
local totalCommandsRun = 0

local function runServerCommand(commandName, args)
	if not remote then
		notify("Error", "AdminCommandRemote not found", "error")
		return
	end
	remote:FireServer({command = commandName, args = args})
end

function runCommand(rawText)
	local text = rawText:gsub("^%s+", ""):gsub("%s+$", "")
	if text == "" then return end

	local parts = splitBySpace(text)
	local base = string.lower(parts[1] or "")

	-- Log & stats
	addLogEntry(text, true)
	totalCommandsRun = totalCommandsRun + 1
	for _, c in ipairs(statCommands:GetChildren()) do
		if c:IsA("TextLabel") and c.TextSize == 20 then c.Text = tostring(totalCommandsRun) break end
	end

	-- Command history
	table.insert(commandHistory, 1, text)
	if #commandHistory > MAX_HISTORY then table.remove(commandHistory) end
	historyIndex = 0

	-- Update recent on dashboard
	if recentFrame then
		recentEmptyLabel.Visible = false
		-- Keep only last 3
		local children = {}
		for _, c in ipairs(recentFrame:GetChildren()) do
			if c:IsA("Frame") then table.insert(children, c) end
		end
		if #children >= 3 then children[#children]:Destroy() end

		local recentRow = Components.frame({
			name = "Recent",
			size = UDim2.new(1, 0, 0, 24),
			bg = THEME.surfaceElevated,
			bgTransparency = 0.5,
			layoutOrder = -totalCommandsRun,
			parent = recentFrame,
		})
		Components.corner(recentRow, 4)
		Components.textLabel({
			text = "  " .. text,
			font = FONTS.mono,
			textSize = 11,
			color = THEME.textSecondary,
			size = UDim2.new(1, 0, 1, 0),
			truncate = Enum.TextTruncate.AtEnd,
			parent = recentRow,
		})
	end

	-- Local commands
	if base == "fly" then setFly(true) return true end
	if base == "unfly" then setFly(false) return true end
	if base == "noclip" then setNoclip(true) return true end
	if base == "clip" then setNoclip(false) return true end
	if base == "monitor" then
		if monitorToggleEvent then monitorToggleEvent:Fire() end
		notify("System", "Monitor panel requested", "info")
		return true
	end

	-- Server commands
	if base == "rank" then runServerCommand("rank", {parts[2], parts[3]})
	elseif base == "money" then runServerCommand("money", {parts[2], tonumber(parts[3]) or 0})
	elseif base == "kick" then runServerCommand("kick", {parts[2], joinFrom(parts, 3)})
	elseif base == "ban" then runServerCommand("ban", {parts[2], tonumber(parts[3]) or 60, joinFrom(parts, 4)})
	elseif base == "jail" then runServerCommand("jail", {parts[2], tonumber(parts[3]) or 30})
	elseif base == "unjail" then runServerCommand("unjail", {parts[2]})
	elseif base == "namechanger" then runServerCommand("namechanger", {parts[2], joinFrom(parts, 3)})
	elseif base == "resetname" then runServerCommand("resetname", {parts[2]})
	elseif base == "bring" then runServerCommand("bring", {parts[2]})
	elseif base == "to" then runServerCommand("to", {parts[2]})
	elseif base == "kill" then runServerCommand("kill", {parts[2]})
	elseif base == "heal" then runServerCommand("heal", {parts[2]})
	elseif base == "speed" then runServerCommand("speed", {parts[2], tonumber(parts[3]) or 16})
	elseif base == "jump" then runServerCommand("jump", {parts[2], tonumber(parts[3]) or 50})
	elseif base == "freeze" then runServerCommand("freeze", {parts[2]})
	elseif base == "unfreeze" then runServerCommand("unfreeze", {parts[2]})
	elseif base == "freezeall" then runServerCommand("freezeall", {})
	elseif base == "unfreezeall" then runServerCommand("unfreezeall", {})
	elseif base == "sit" then runServerCommand("sit", {parts[2]})
	elseif base == "unsit" then runServerCommand("unsit", {parts[2]})
	elseif base == "shutdown" then runServerCommand("shutdown", {joinFrom(parts, 2)})
	elseif base == "lobbyannouncement" then runServerCommand("lobbyannouncement", {joinFrom(parts, 2)})
	elseif base == "globalannouncement" then runServerCommand("globalannouncement", {joinFrom(parts, 2)})
	elseif base == "lobby" then runServerCommand("lobby", {joinFrom(parts, 2)})
	elseif base == "global" then runServerCommand("global", {joinFrom(parts, 2)})
	elseif base == "hack" then runServerCommand("hack", {})
	elseif base == "event" then runServerCommand("event", {parts[2], parts[3]})
	elseif base == "laser" then runServerCommand("laser", {})
	elseif base == "smite" then runServerCommand("smite", {parts[2]})
	elseif base == "nuke" then runServerCommand("nuke", {})
	elseif base == "meteor" then runServerCommand("meteor", {})
	elseif base == "snap" then runServerCommand("snap", {})
	elseif base == "virus" then runServerCommand("virus", {parts[2]})
	elseif base == "unbanid" then runServerCommand("unbanid", {parts[2]})
	else
		notify("Error", "Unknown command: " .. base, "error")
	end

	return true
end

--------------------------------------------------------------------------------
-- SECTION 29: Quick Bar Input Handling
--------------------------------------------------------------------------------
cmdInput.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	local text = cmdInput.Text
	cmdInput.Text = ""
	updateCmdHint()
	suggestionFrame.Visible = false
	runCommand(text)
	closeQuickBar()
end)



--------------------------------------------------------------------------------
-- SECTION 30: Announcement System
--------------------------------------------------------------------------------
local announcementFrame = Components.frame({
	name = "AnnouncementFrame",
	size = UDim2.new(0, 480, 0, 0),
	position = UDim2.new(0.5, 0, 0, -120),
	anchor = Vector2.new(0.5, 0),
	bg = THEME.bgGlass,
	bgTransparency = 0.1,
	autoSize = Enum.AutomaticSize.Y,
	parent = screenGui,
})
announcementFrame.Visible = false
Components.corner(announcementFrame, SIZES.cornerMd)
Components.stroke(announcementFrame, THEME.accent, 1, 0.5)
Components.padding(announcementFrame, 14, 14, 20, 20)

local announcementText = Components.textLabel({
	text = "",
	font = FONTS.heading,
	textSize = 20,
	color = THEME.textPrimary,
	size = UDim2.new(1, 0, 0, 0),
	xAlign = Enum.TextXAlignment.Center,
	parent = announcementFrame,
})
announcementText.TextWrapped = true
announcementText.AutomaticSize = Enum.AutomaticSize.Y

local function playAnnouncement(scopeName, text)
	announcementText.Text = string.upper(tostring(text or ""))
	announcementTweenToken += 1
	local token = announcementTweenToken

	announcementFrame.Visible = true
	announcementFrame.Position = UDim2.new(0.5, 0, 0, -40)
	tweenPlay(announcementFrame, {Position = UDim2.new(0.5, 0, 0, 16)}, 0.4, Enum.EasingStyle.Quint)

	task.delay(5, function()
		if token ~= announcementTweenToken then return end
		local hideTween = tween(announcementFrame, {Position = UDim2.new(0.5, 0, 0, -170)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		hideTween:Play()
		hideTween.Completed:Once(function()
			if token ~= announcementTweenToken then return end
			announcementFrame.Visible = false
		end)
	end)
end

--------------------------------------------------------------------------------
-- SECTION 31: Server Communication
--------------------------------------------------------------------------------
remote.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	if payload.type == "admin_init" then
		applyRankPermissions(payload.rank or "guest")
		toggleBtn.Visible = canOpenUI
		-- Update rank displays
		rankBadgeText.Text = string.upper(myRank)
		rankBadgeFrame.BackgroundColor3 = getRankDisplayColor(myRank)
		dashRankText.Text = string.upper(myRank)
		dashRankBadge.BackgroundColor3 = getRankDisplayColor(myRank)
		dashRankBadge.Visible = true
		for _, c in ipairs(statRank:GetChildren()) do
			if c:IsA("TextLabel") and c.TextSize == 20 then
				c.Text = string.upper(myRank)
				c.TextColor3 = getRankDisplayColor(myRank)
				break
			end
		end
		if canOpenUI then
			notify("System", "Admin UI loaded. Rank: " .. (payload.rank or "guest"), "success", 4)
		end
		return
	end
	if payload.type == "announcement" then
		playAnnouncement(payload.scope, payload.text)
	end
end)

-- Request init
remote:FireServer({type = "request_init"})

-- Apply rank from attribute
applyRankPermissions(player:GetAttribute("AdminRank"))
toggleBtn.Visible = canOpenUI

player:GetAttributeChangedSignal("AdminRank"):Connect(function()
	applyRankPermissions(player:GetAttribute("AdminRank"))
	toggleBtn.Visible = canOpenUI
end)

--------------------------------------------------------------------------------
-- SECTION 32: Input Bindings
--------------------------------------------------------------------------------
local function toggleQuickBar()
	if not canOpenUI then
		notify("Admin", "No permission. Rank: " .. myRank, "error")
		return
	end
	if quickBarOpen then closeQuickBar() else openQuickBar() end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isToggleKey(input.KeyCode) then
		toggleQuickBar()
	end
	-- Escape
	if input.KeyCode == Enum.KeyCode.Escape then
		if commandModal.Visible then closeCommandModal()
		elseif panelOpen then closePanel()
		elseif quickBarOpen then closeQuickBar() end
	end
	-- History navigation in quick bar
	if quickBarOpen and cmdInput:IsFocused() then
		if input.KeyCode == Enum.KeyCode.Up then
			historyIndex = math.min(historyIndex + 1, #commandHistory)
			if commandHistory[historyIndex] then
				cmdInput.Text = commandHistory[historyIndex]
				cmdInput.CursorPosition = #cmdInput.Text + 1
			end
		elseif input.KeyCode == Enum.KeyCode.Down then
			historyIndex = math.max(historyIndex - 1, 0)
			if historyIndex == 0 then
				cmdInput.Text = ""
			elseif commandHistory[historyIndex] then
				cmdInput.Text = commandHistory[historyIndex]
				cmdInput.CursorPosition = #cmdInput.Text + 1
			end
		end
	end
end)

-- Tab autocomplete
ContextActionService:BindActionAtPriority(
	"AdminPanel_TabApply",
	function(_, state, input)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if input.KeyCode ~= Enum.KeyCode.Tab or not cmdInput:IsFocused() then return Enum.ContextActionResult.Pass end

		local current = cmdInput.Text or ""
		if current:find("%s") then return Enum.ContextActionResult.Sink end

		local suggestion = getCommandSuggestion(current)
		if suggestion and suggestion ~= string.lower(current) then
			cmdInput.Text = suggestion .. " "
			cmdInput.CursorPosition = #cmdInput.Text + 1
			updateCmdHint()
			updateSuggestions()
		end
		return Enum.ContextActionResult.Sink
	end,
	false, 100002, Enum.KeyCode.Tab
)

--------------------------------------------------------------------------------
-- SECTION 33: Chat Prefix Recognition
--------------------------------------------------------------------------------
player.Chatted:Connect(function(message)
	local text = tostring(message or "")
	local prefix = text:sub(1, 1)
	if not CHAT_PREFIXES[prefix] then return end
	if not canOpenUI then
		notify("Admin", "No permission for chat commands", "error")
		return
	end

	local rawCommand = text:sub(2):gsub("^%s+", "")
	if rawCommand == "" then return end

	local cmdLower = string.lower(rawCommand)
	if cmdLower == "ui" or cmdLower == "cmd" or cmdLower == "cmdbox" then
		toggleQuickBar()
		return
	end

	runCommand(rawCommand)
end)

--------------------------------------------------------------------------------
-- SECTION 34: Final Initialization
--------------------------------------------------------------------------------
-- Position sidebar indicator to correct initial tab
task.defer(function()
	task.wait(0.1) -- Wait for layout to settle
	local btn = tabButtons[activeTab]
	if btn then
		local btnPos = btn.AbsolutePosition
		local sidePos = sidebar.AbsolutePosition
		local relY = btnPos.Y - sidePos.Y + 8
		sidebarIndicator.Position = UDim2.new(0, 0, 0, relY)
	end
end)

-- End of AdminClient Premium
