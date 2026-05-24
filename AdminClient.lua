--[[
	AdminClient.lua
	Client-side logic for the Admin Panel.
	Place in StarterPlayerScripts.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared module
local Shared = require(ReplicatedStorage:WaitForChild("AdminPanel_Shared"))
local Constants = Shared.Constants

-- ============================================================================
-- SECTION 1: TWEEN CONTROLLER
-- ============================================================================

local TweenController = {}
local activeTweens: { [GuiObject]: Tween } = {}

local function createTweenInfo(duration: number): TweenInfo
	return TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

local function playTween(instance: GuiObject, tweenInfo: TweenInfo, goals: { [string]: any }): Tween
	local existing = activeTweens[instance]
	if existing then existing:Cancel() end
	local tween = TweenService:Create(instance, tweenInfo, goals)
	activeTweens[instance] = tween
	tween.Completed:Connect(function()
		if activeTweens[instance] == tween then activeTweens[instance] = nil end
	end)
	tween:Play()
	return tween
end

function TweenController.scaleIn(instance: GuiObject, duration: number?)
	local dur = duration or Constants.ANIM_PANEL_OPEN
	local info = createTweenInfo(dur)
	instance.Size = UDim2.new(instance.Size.X.Scale * 0.95, instance.Size.X.Offset, instance.Size.Y.Scale * 0.95, instance.Size.Y.Offset)
	if instance:IsA("CanvasGroup") then (instance :: CanvasGroup).GroupTransparency = 1
	else instance.BackgroundTransparency = 1 end
	instance.Visible = true
	local targetSize = UDim2.new(instance.Size.X.Scale / 0.95, instance.Size.X.Offset, instance.Size.Y.Scale / 0.95, instance.Size.Y.Offset)
	if instance:IsA("CanvasGroup") then playTween(instance, info, { Size = targetSize, GroupTransparency = 0 })
	else playTween(instance, info, { Size = targetSize, BackgroundTransparency = 0 }) end
end

function TweenController.scaleOut(instance: GuiObject, duration: number?)
	local dur = duration or Constants.ANIM_PANEL_CLOSE
	local info = createTweenInfo(dur)
	local targetSize = UDim2.new(instance.Size.X.Scale * 0.95, instance.Size.X.Offset, instance.Size.Y.Scale * 0.95, instance.Size.Y.Offset)
	local goals: { [string]: any }
	if instance:IsA("CanvasGroup") then goals = { Size = targetSize, GroupTransparency = 1 }
	else goals = { Size = targetSize, BackgroundTransparency = 1 } end
	local tween = playTween(instance, info, goals)
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then instance.Visible = false end
	end)
end

function TweenController.transitionViews(outView: GuiObject, inView: GuiObject)
	local fadeOutInfo = createTweenInfo(Constants.ANIM_FADE_HALF)
	local goals: { [string]: any }
	if outView:IsA("CanvasGroup") then goals = { GroupTransparency = 1 }
	else goals = { BackgroundTransparency = 1 } end
	local outTween = playTween(outView, fadeOutInfo, goals)
	outTween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed then
			outView.Visible = false
			if inView:IsA("CanvasGroup") then (inView :: CanvasGroup).GroupTransparency = 1
			else inView.BackgroundTransparency = 1 end
			inView.Visible = true
			local fadeInInfo = createTweenInfo(Constants.ANIM_FADE_HALF)
			local inGoals: { [string]: any }
			if inView:IsA("CanvasGroup") then inGoals = { GroupTransparency = 0 }
			else inGoals = { BackgroundTransparency = 0 } end
			playTween(inView, fadeInInfo, inGoals)
		end
	end)
end

-- ============================================================================
-- SECTION 2: STALE DETECTOR
-- ============================================================================

local StaleDetector = {}
local lastUpdateTime: number = os.clock()

function StaleDetector.recordUpdate()
	lastUpdateTime = os.clock()
end

function StaleDetector.isStale(): boolean
	return (os.clock() - lastUpdateTime) >= Constants.STALE_DATA_TIMEOUT
end

-- ============================================================================
-- SECTION 3: NOTIFICATION SYSTEM
-- ============================================================================

local NotificationSystem = {}

local notifList: { Shared.StoredNotification } = {}
local notifUnreadCount: number = 0
local notifNextId: number = 1
local notifDefaultDuration: number = 5
local notifScreenGui: ScreenGui? = nil
local notifToastContainer: Frame? = nil
local notifBadgeLabel: TextLabel? = nil
local notifActiveToasts: { [number]: Frame } = {}

local NOTIF_CATEGORY_COLORS: { [string]: Color3 } = {
	success = Color3.fromRGB(72, 199, 142),
	error = Color3.fromRGB(235, 87, 87),
	warning = Color3.fromRGB(242, 201, 76),
	info = Color3.fromRGB(86, 156, 255),
}

local function getNotifScreenGui(): ScreenGui
	if notifScreenGui then return notifScreenGui :: ScreenGui end
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local gui = playerGui:FindFirstChild("AdminNotifications") :: ScreenGui?
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "AdminNotifications"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 100
		gui.IgnoreGuiInset = true
		gui.Parent = playerGui
	end
	notifScreenGui = gui
	return gui :: ScreenGui
end

local function getNotifToastContainer(): Frame
	if notifToastContainer then return notifToastContainer :: Frame end
	local gui = getNotifScreenGui()
	local container = gui:FindFirstChild("ToastContainer") :: Frame?
	if not container then
		container = Instance.new("Frame")
		container.Name = "ToastContainer"
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(0, 320, 1, 0)
		container.Position = UDim2.new(1, -340, 0, 0)
		container.Parent = gui
	end
	notifToastContainer = container
	return container :: Frame
end

local function repositionToasts()
	local yOffset: number = 16
	local container = getNotifToastContainer()
	local frames: { Frame } = {}
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then table.insert(frames, child :: Frame) end
	end
	table.sort(frames, function(a: Frame, b: Frame): boolean return a.LayoutOrder < b.LayoutOrder end)
	for _, frame in frames do
		local targetPos = UDim2.new(0, 0, 0, yOffset)
		TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPos }):Play()
		yOffset += frame.AbsoluteSize.Y + 8
	end
end

local function updateNotifBadge()
	if not notifBadgeLabel then return end
	local badge = notifBadgeLabel :: TextLabel
	if notifUnreadCount <= 0 then badge.Visible = false
	elseif notifUnreadCount <= Constants.MAX_UNREAD_DISPLAY then badge.Visible = true; badge.Text = tostring(notifUnreadCount)
	else badge.Visible = true; badge.Text = tostring(Constants.MAX_UNREAD_DISPLAY) .. "+" end
end

function NotificationSystem.init()
	getNotifScreenGui()
	getNotifToastContainer()
	notifList = {}
	notifUnreadCount = 0
	notifNextId = 1
	notifActiveToasts = {}
end

function NotificationSystem.notify(config: Shared.NotificationConfig)
	local notification: Shared.StoredNotification = {
		id = notifNextId, category = config.category, message = config.message,
		timestamp = os.time(), read = false,
	}
	notifNextId += 1
	if #notifList >= Constants.MAX_STORED_NOTIFICATIONS then table.remove(notifList, 1) end
	table.insert(notifList, notification)
	notifUnreadCount += 1
	updateNotifBadge()

	-- Create toast UI
	local categoryColor = NOTIF_CATEGORY_COLORS[notification.category] or NOTIF_CATEGORY_COLORS.info
	local container = getNotifToastContainer()
	local toast = Instance.new("Frame")
	toast.Name = "Toast_" .. tostring(notification.id)
	toast.Size = UDim2.new(1, 0, 0, 72)
	toast.Position = UDim2.new(0, 20, 0, 0)
	toast.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	toast.BorderSizePixel = 0
	toast.LayoutOrder = -notification.id
	toast.ClipsDescendants = true
	toast.BackgroundTransparency = 1
	toast.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast

	local leftBorder = Instance.new("Frame")
	leftBorder.Size = UDim2.new(0, 4, 1, 0)
	leftBorder.BackgroundColor3 = categoryColor
	leftBorder.BorderSizePixel = 0
	leftBorder.BackgroundTransparency = 1
	leftBorder.Parent = toast
	local borderCorner = Instance.new("UICorner")
	borderCorner.CornerRadius = UDim.new(0, 4)
	borderCorner.Parent = leftBorder

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -52, 0, 40)
	messageLabel.Position = UDim2.new(0, 16, 0, 8)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = notification.message
	messageLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
	messageLabel.TextSize = 12
	messageLabel.Font = Enum.Font.GothamMedium
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.TextYAlignment = Enum.TextYAlignment.Top
	messageLabel.TextWrapped = true
	messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
	messageLabel.TextTransparency = 1
	messageLabel.Parent = toast

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, -52, 0, 16)
	timeLabel.Position = UDim2.new(0, 16, 0, 50)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Text = os.date("%H:%M:%S", notification.timestamp) :: string
	timeLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
	timeLabel.TextSize = 10
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.TextTransparency = 1
	timeLabel.Parent = toast

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -32, 0, 8)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "x"
	closeBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextTransparency = 1
	closeBtn.Parent = toast

	notifActiveToasts[notification.id] = toast

	-- Animate in
	repositionToasts()
	local animInfo = TweenInfo.new(Constants.ANIM_NOTIFICATION_IN, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	TweenService:Create(toast, animInfo, { Position = UDim2.new(0, 0, 0, toast.Position.Y.Offset), BackgroundTransparency = 0 }):Play()
	TweenService:Create(messageLabel, animInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(timeLabel, animInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(closeBtn, animInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(leftBorder, animInfo, { BackgroundTransparency = 0 }):Play()

	-- Dismiss function
	local function dismissToast()
		if not notifActiveToasts[notification.id] then return end
		notifActiveToasts[notification.id] = nil
		local dismissInfo = TweenInfo.new(Constants.ANIM_DISMISS, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local slideTween = TweenService:Create(toast, dismissInfo, { Position = UDim2.new(0, 20, 0, toast.Position.Y.Offset), BackgroundTransparency = 1 })
		TweenService:Create(messageLabel, dismissInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(timeLabel, dismissInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(closeBtn, dismissInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(leftBorder, dismissInfo, { BackgroundTransparency = 1 }):Play()
		slideTween:Play()
		slideTween.Completed:Connect(function() toast:Destroy(); repositionToasts() end)
	end

	closeBtn.Activated:Connect(dismissToast)

	-- Auto-dismiss
	local dur: number = config.duration or notifDefaultDuration
	dur = math.clamp(dur, 3, 15)
	task.delay(dur, function()
		if notifActiveToasts[notification.id] then dismissToast() end
	end)
end

function NotificationSystem.getAll(): { Shared.StoredNotification }
	return notifList
end

function NotificationSystem.getUnreadCount(): number
	return notifUnreadCount
end

function NotificationSystem.markAllRead()
	for _, n in notifList do n.read = true end
	notifUnreadCount = 0
	updateNotifBadge()
end

function NotificationSystem.setBadgeLabel(label: TextLabel)
	notifBadgeLabel = label
	updateNotifBadge()
end

function NotificationSystem.setDuration(duration: number)
	notifDefaultDuration = math.clamp(duration, 3, 15)
end

-- ============================================================================
-- SECTION 4: DASHBOARD COMPONENT
-- ============================================================================

local Dashboard = {}
local dashCardRefs: { [string]: { frame: Frame, valueLabel: TextLabel, staleIcon: TextLabel, stroke: UIStroke, lastRawValue: number, originalSize: UDim2 } } = {}
local dashAccentColor: Color3 = Color3.fromRGB(70, 115, 255)

local CARD_DEFS = {
	{ key = "playerCount", title = "Players",
		format = function(s: Shared.ServerStats): string return tostring(s.playerCount) end,
		raw = function(s: Shared.ServerStats): number return s.playerCount end },
	{ key = "serverFps", title = "Server FPS",
		format = function(s: Shared.ServerStats): string return tostring(math.round(s.serverFps)) end,
		raw = function(s: Shared.ServerStats): number return s.serverFps end },
	{ key = "averagePing", title = "Avg Ping (ms)",
		format = function(s: Shared.ServerStats): string return tostring(math.round(s.averagePing)) end,
		raw = function(s: Shared.ServerStats): number return s.averagePing end },
	{ key = "memoryUsage", title = "Memory (MB)",
		format = function(s: Shared.ServerStats): string return string.format("%.1f", s.memoryUsage) end,
		raw = function(s: Shared.ServerStats): number return s.memoryUsage end },
	{ key = "uptime", title = "Uptime",
		format = function(s: Shared.ServerStats): string
			local h = math.floor(s.uptime / 3600)
			local m = math.floor((s.uptime % 3600) / 60)
			local sec = math.floor(s.uptime % 60)
			return string.format("%02d:%02d:%02d", h, m, sec)
		end,
		raw = function(s: Shared.ServerStats): number return s.uptime end },
	{ key = "moderationCount", title = "Moderation Actions",
		format = function(s: Shared.ServerStats): string return tostring(s.moderationCount) end,
		raw = function(s: Shared.ServerStats): number return s.moderationCount end },
}

local function createDashCard(cardData: any, accentColor: Color3): Frame
	local card = Instance.new("Frame")
	card.Name = "Card_" .. cardData.key
	card.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
	card.BorderSizePixel = 0
	local crn = Instance.new("UICorner"); crn.CornerRadius = UDim.new(0, 10); crn.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0); stroke.Transparency = 0.85
	stroke.Thickness = 1; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = card
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12); pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = card
	local titleLbl = Instance.new("TextLabel"); titleLbl.BackgroundTransparency = 1
	titleLbl.Size = UDim2.new(1, 0, 0, 20); titleLbl.Position = UDim2.new(0, 0, 0, 0)
	titleLbl.Text = cardData.title; titleLbl.TextColor3 = Color3.fromRGB(180, 180, 195)
	titleLbl.TextSize = 12; titleLbl.Font = Enum.Font.Gotham
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = card
	local valueLbl = Instance.new("TextLabel"); valueLbl.Name = "Value"
	valueLbl.BackgroundTransparency = 1; valueLbl.Size = UDim2.new(1, 0, 1, -28)
	valueLbl.Position = UDim2.new(0, 0, 0, 24); valueLbl.Text = "—"
	valueLbl.TextColor3 = Color3.fromRGB(255, 255, 255); valueLbl.TextSize = 22
	valueLbl.Font = Enum.Font.GothamBold; valueLbl.TextXAlignment = Enum.TextXAlignment.Left
	valueLbl.TextYAlignment = Enum.TextYAlignment.Center; valueLbl.Parent = card
	local staleIcon = Instance.new("TextLabel"); staleIcon.Name = "StaleIndicator"
	staleIcon.BackgroundTransparency = 1; staleIcon.Size = UDim2.new(0, 20, 0, 20)
	staleIcon.Position = UDim2.new(1, -20, 0, 0); staleIcon.Text = "!"
	staleIcon.TextColor3 = Color3.fromRGB(255, 200, 50); staleIcon.TextSize = 14
	staleIcon.Font = Enum.Font.GothamBold; staleIcon.Visible = false; staleIcon.Parent = card
	dashCardRefs[cardData.key] = { frame = card, valueLabel = valueLbl, staleIcon = staleIcon, stroke = stroke, lastRawValue = 0, originalSize = UDim2.new(0, 0, 0, 0) }
	-- Hover effects (subtle 1.02 scale)
	card.MouseEnter:Connect(function()
		local refs = dashCardRefs[cardData.key]; if not refs then return end
		playTween(card, createTweenInfo(Constants.ANIM_HOVER), { Size = UDim2.new(refs.originalSize.X.Scale * 1.02, refs.originalSize.X.Offset, refs.originalSize.Y.Scale * 1.02, refs.originalSize.Y.Offset) })
		TweenService:Create(stroke, createTweenInfo(Constants.ANIM_HOVER), { Transparency = 0.7, Thickness = 2 }):Play()
	end)
	card.MouseLeave:Connect(function()
		local refs = dashCardRefs[cardData.key]; if not refs then return end
		playTween(card, createTweenInfo(Constants.ANIM_HOVER), { Size = refs.originalSize })
		TweenService:Create(stroke, createTweenInfo(Constants.ANIM_HOVER), { Transparency = 0.85, Thickness = 1 }):Play()
	end)
	return card
end

function Dashboard.create(parent: GuiObject, accentColor: Color3): Frame
	dashAccentColor = accentColor
	local container = Instance.new("Frame"); container.Name = "DashboardView"
	container.BackgroundTransparency = 1; container.Size = UDim2.fromScale(1, 1); container.Parent = parent
	local cPad = Instance.new("UIPadding")
	cPad.PaddingTop = UDim.new(0, 12); cPad.PaddingBottom = UDim.new(0, 12)
	cPad.PaddingLeft = UDim.new(0, 12); cPad.PaddingRight = UDim.new(0, 12); cPad.Parent = container
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.333, -8, 0.5, -8); grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.FillDirection = Enum.FillDirection.Horizontal; grid.SortOrder = Enum.SortOrder.LayoutOrder; grid.Parent = container
	for i, cd in ipairs(CARD_DEFS) do
		local card = createDashCard(cd, accentColor); card.LayoutOrder = i; card.Parent = container
		task.defer(function()
			local refs = dashCardRefs[cd.key]
			if refs then refs.originalSize = card.Size end
		end)
	end
	return container
end

function Dashboard.updateStats(stats: Shared.ServerStats)
	for _, cd in ipairs(CARD_DEFS) do
		local refs = dashCardRefs[cd.key]; if not refs then continue end
		local newVal = cd.raw(stats)
		if newVal ~= refs.lastRawValue then
			refs.valueLabel.Text = cd.format(stats)
			refs.lastRawValue = newVal
		end
	end
end

function Dashboard.setStale(stale: boolean)
	for _, refs in pairs(dashCardRefs) do refs.staleIcon.Visible = stale end
end

-- ============================================================================
-- SECTION 5: SIDEBAR COMPONENT
-- ============================================================================

local Sidebar = {}
local sidebarCollapsed: boolean = false
local sidebarActiveTab: string = "Dashboard"
local sidebarTabButtons: { [string]: { frame: Frame, icon: TextLabel, label: TextLabel, indicator: Frame } } = {}
local sidebarFrame: Frame? = nil
local sidebarAccentColor: Color3 = Color3.fromRGB(70, 115, 255)
local sidebarOnTabChanged: ((string) -> ())? = nil

local SIDEBAR_TABS = {
	{ name = "Dashboard", icon = "D", label = "Dashboard" },
	{ name = "Players", icon = "P", label = "Players" },
	{ name = "Moderation", icon = "M", label = "Moderation" },
	{ name = "Server", icon = "S", label = "Server" },
	{ name = "Logs", icon = "L", label = "Logs" },
	{ name = "Settings", icon = "G", label = "Settings" },
}

local function updateSidebarIndicators()
	for name, btn in sidebarTabButtons do
		if name == sidebarActiveTab then
			playTween(btn.indicator, createTweenInfo(0.15), { BackgroundColor3 = sidebarAccentColor, BackgroundTransparency = 0 })
			playTween(btn.icon, createTweenInfo(0.15), { TextColor3 = Color3.fromRGB(255, 255, 255) })
			playTween(btn.label, createTweenInfo(0.15), { TextColor3 = Color3.fromRGB(255, 255, 255) })
		else
			playTween(btn.indicator, createTweenInfo(0.15), { BackgroundTransparency = 1 })
			playTween(btn.icon, createTweenInfo(0.15), { TextColor3 = Color3.fromRGB(120, 120, 140) })
			playTween(btn.label, createTweenInfo(0.15), { TextColor3 = Color3.fromRGB(120, 120, 140) })
		end
	end
end

function Sidebar.create(parent: GuiObject, accentColor: Color3, onTabChanged: (string) -> ()): Frame
	sidebarAccentColor = accentColor; sidebarOnTabChanged = onTabChanged
	sidebarCollapsed = false; sidebarActiveTab = "Dashboard"; sidebarTabButtons = {}
	local frame = Instance.new("Frame"); frame.Name = "Navigation_Sidebar"
	frame.Size = UDim2.new(0, 140, 1, 0); frame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
	frame.BorderSizePixel = 0; frame.ClipsDescendants = true; frame.Parent = parent
	local crn = Instance.new("UICorner"); crn.CornerRadius = UDim.new(0, 10); crn.Parent = frame
	sidebarFrame = frame
	for i, tabDef in SIDEBAR_TABS do
		local tabFrame = Instance.new("Frame"); tabFrame.Name = "Tab_" .. tabDef.name
		tabFrame.Size = UDim2.new(1, -12, 0, 36)
		tabFrame.Position = UDim2.new(0, 6, 0, 6 + (i - 1) * 42)
		tabFrame.BackgroundTransparency = 1; tabFrame.BorderSizePixel = 0; tabFrame.Parent = frame
		local fcrn = Instance.new("UICorner"); fcrn.CornerRadius = UDim.new(0, 6); fcrn.Parent = tabFrame
		local indicator = Instance.new("Frame"); indicator.Name = "Indicator"
		indicator.Size = UDim2.new(0, 3, 0, 24); indicator.Position = UDim2.new(0, 0, 0.5, 0)
		indicator.AnchorPoint = Vector2.new(0, 0.5); indicator.BackgroundColor3 = accentColor
		indicator.BackgroundTransparency = 1; indicator.BorderSizePixel = 0; indicator.Parent = tabFrame
		local icrn = Instance.new("UICorner"); icrn.CornerRadius = UDim.new(0, 2); icrn.Parent = indicator
		local icon = Instance.new("TextLabel"); icon.Size = UDim2.new(0, 24, 0, 36)
		icon.Position = UDim2.new(0, 8, 0, 0); icon.BackgroundTransparency = 1
		icon.Text = tabDef.icon; icon.TextSize = 14; icon.TextColor3 = Color3.fromRGB(120, 120, 140)
		icon.Font = Enum.Font.GothamBold; icon.TextXAlignment = Enum.TextXAlignment.Center; icon.Parent = tabFrame
		local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -44, 0, 36)
		lbl.Position = UDim2.new(0, 38, 0, 0); lbl.BackgroundTransparency = 1
		lbl.Text = tabDef.label; lbl.TextSize = 12; lbl.TextColor3 = Color3.fromRGB(120, 120, 140)
		lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd; lbl.Parent = tabFrame
		local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1)
		btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 2; btn.Parent = tabFrame
		btn.MouseButton1Click:Connect(function()
			if tabDef.name == sidebarActiveTab then return end
			sidebarActiveTab = tabDef.name; updateSidebarIndicators()
			if sidebarOnTabChanged then sidebarOnTabChanged(tabDef.name) end
		end)
		sidebarTabButtons[tabDef.name] = { frame = tabFrame, icon = icon, label = lbl, indicator = indicator }
	end
	-- Collapse toggle
	local toggleBtn = Instance.new("TextButton"); toggleBtn.Name = "CollapseToggle"
	toggleBtn.Size = UDim2.new(1, -12, 0, 28)
	toggleBtn.Position = UDim2.new(0, 6, 1, -34)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42); toggleBtn.BackgroundTransparency = 0.5
	toggleBtn.BorderSizePixel = 0; toggleBtn.Text = "<"; toggleBtn.TextSize = 14
	toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 210); toggleBtn.Font = Enum.Font.GothamBold; toggleBtn.Parent = frame
	local tcrn = Instance.new("UICorner"); tcrn.CornerRadius = UDim.new(0, 6); tcrn.Parent = toggleBtn
	toggleBtn.MouseButton1Click:Connect(function()
		if sidebarCollapsed then Sidebar.expand() else Sidebar.collapse() end
	end)
	updateSidebarIndicators()
	return frame
end

function Sidebar.setActiveTab(tabName: string)
	if tabName == sidebarActiveTab then return end
	if not sidebarTabButtons[tabName] then return end
	sidebarActiveTab = tabName; updateSidebarIndicators()
end

function Sidebar.collapse()
	if sidebarCollapsed then return end; sidebarCollapsed = true
	local frame = sidebarFrame; if not frame then return end
	playTween(frame, createTweenInfo(Constants.ANIM_SIDEBAR_TOGGLE), { Size = UDim2.new(0, 40, 1, 0) })
	for _, btn in sidebarTabButtons do
		playTween(btn.label, createTweenInfo(Constants.ANIM_SIDEBAR_TOGGLE * 0.6), { TextTransparency = 1 })
	end
	local toggle = frame:FindFirstChild("CollapseToggle") :: TextButton?
	if toggle then toggle.Text = ">" end
end

function Sidebar.expand()
	if not sidebarCollapsed then return end; sidebarCollapsed = false
	local frame = sidebarFrame; if not frame then return end
	playTween(frame, createTweenInfo(Constants.ANIM_SIDEBAR_TOGGLE), { Size = UDim2.new(0, 140, 1, 0) })
	for _, btn in sidebarTabButtons do
		playTween(btn.label, createTweenInfo(Constants.ANIM_SIDEBAR_TOGGLE), { TextTransparency = 0 })
	end
	local toggle = frame:FindFirstChild("CollapseToggle") :: TextButton?
	if toggle then toggle.Text = "<" end
end

-- ============================================================================
-- SECTION 6: TOPBAR COMPONENT
-- ============================================================================

local Topbar = {}
local topbarPlayerCountLabel: TextLabel? = nil

function Topbar.create(parent: GuiObject, adminName: string, role: string, accentColor: Color3): Frame
	local frame = Instance.new("Frame"); frame.Name = "Topbar"
	frame.Size = UDim2.new(1, 0, 0, 36); frame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
	frame.BorderSizePixel = 0; frame.Parent = parent
	local border = Instance.new("Frame"); border.Size = UDim2.new(1, 0, 0, 1)
	border.Position = UDim2.new(0, 0, 1, -1); border.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	border.BorderSizePixel = 0; border.Parent = frame
	-- Admin name + role
	local profileSection = Instance.new("Frame"); profileSection.Size = UDim2.new(0, 160, 1, 0)
	profileSection.Position = UDim2.new(0, 12, 0, 0); profileSection.BackgroundTransparency = 1; profileSection.Parent = frame
	local displayName = if #adminName > 20 then string.sub(adminName, 1, 20) else adminName
	local usernameLabel = Instance.new("TextLabel"); usernameLabel.Size = UDim2.new(1, 0, 0, 16)
	usernameLabel.Position = UDim2.new(0, 0, 0, 4); usernameLabel.BackgroundTransparency = 1
	usernameLabel.Text = displayName; usernameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	usernameLabel.TextSize = 12; usernameLabel.Font = Enum.Font.GothamBold
	usernameLabel.TextXAlignment = Enum.TextXAlignment.Left; usernameLabel.Parent = profileSection
	local roleBadge = Instance.new("TextLabel"); roleBadge.Size = UDim2.new(0, 0, 0, 14)
	roleBadge.AutomaticSize = Enum.AutomaticSize.X; roleBadge.Position = UDim2.new(0, 0, 0, 20)
	roleBadge.BackgroundColor3 = accentColor; roleBadge.BackgroundTransparency = 0.8
	roleBadge.Text = " " .. role .. " "; roleBadge.TextColor3 = accentColor
	roleBadge.TextSize = 10; roleBadge.Font = Enum.Font.GothamBold; roleBadge.BorderSizePixel = 0; roleBadge.Parent = profileSection
	local rbcrn = Instance.new("UICorner"); rbcrn.CornerRadius = UDim.new(0, 4); rbcrn.Parent = roleBadge
	-- Right section: player count + dot indicator
	local rightSection = Instance.new("Frame"); rightSection.Size = UDim2.new(0, 160, 1, 0)
	rightSection.Position = UDim2.new(1, -12, 0, 0); rightSection.AnchorPoint = Vector2.new(1, 0)
	rightSection.BackgroundTransparency = 1; rightSection.Parent = frame
	local statusDot = Instance.new("Frame"); statusDot.Size = UDim2.new(0, 8, 0, 8)
	statusDot.Position = UDim2.new(0, 0, 0.5, 0); statusDot.AnchorPoint = Vector2.new(0, 0.5)
	statusDot.BackgroundColor3 = Color3.fromRGB(72, 199, 142); statusDot.BorderSizePixel = 0; statusDot.Parent = rightSection
	local sdcrn = Instance.new("UICorner"); sdcrn.CornerRadius = UDim.new(1, 0); sdcrn.Parent = statusDot
	local countLabel = Instance.new("TextLabel"); countLabel.Size = UDim2.new(0, 50, 1, 0)
	countLabel.Position = UDim2.new(0, 14, 0, 0); countLabel.BackgroundTransparency = 1
	countLabel.Text = "0/0"; countLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	countLabel.TextSize = 12; countLabel.Font = Enum.Font.GothamMedium
	countLabel.TextXAlignment = Enum.TextXAlignment.Left; countLabel.Parent = rightSection
	topbarPlayerCountLabel = countLabel
	-- Notification dot indicator (replaces bell emoji)
	local notifDot = Instance.new("Frame"); notifDot.Size = UDim2.new(0, 8, 0, 8)
	notifDot.Position = UDim2.new(1, -8, 0.5, 0); notifDot.AnchorPoint = Vector2.new(1, 0.5)
	notifDot.BackgroundColor3 = Color3.fromRGB(86, 156, 255); notifDot.BorderSizePixel = 0; notifDot.Parent = rightSection
	local ndcrn = Instance.new("UICorner"); ndcrn.CornerRadius = UDim.new(1, 0); ndcrn.Parent = notifDot
	return frame
end

function Topbar.updatePlayerCount(current: number, max: number)
	if topbarPlayerCountLabel then topbarPlayerCountLabel.Text = tostring(current) .. "/" .. tostring(max) end
end

-- ============================================================================
-- SECTION 7: UI COMPONENTS (PlayerList, ModerationView, LogsView,
--            SettingsView, Modal, NotificationCenter)
-- ============================================================================

-- PlayerList
local PlayerList = {}
local plAllPlayers: { Shared.PlayerInfo } = {}
local plScrollFrame: ScrollingFrame? = nil

function PlayerList.create(parent: GuiObject, role: string, accentColor: Color3, onAction: (string, Shared.PlayerInfo) -> ()): Frame
	local container = Instance.new("Frame"); container.Name = "PlayerListView"
	container.Size = UDim2.fromScale(1, 1); container.BackgroundTransparency = 1; container.Parent = parent
	-- Search bar
	local searchContainer = Instance.new("Frame"); searchContainer.Size = UDim2.new(1, -12, 0, 30)
	searchContainer.Position = UDim2.new(0, 6, 0, 6); searchContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	searchContainer.BorderSizePixel = 0; searchContainer.Parent = container
	local scrn = Instance.new("UICorner"); scrn.CornerRadius = UDim.new(0, 6); scrn.Parent = searchContainer
	local searchInput = Instance.new("TextBox"); searchInput.Size = UDim2.new(1, -12, 1, 0)
	searchInput.Position = UDim2.new(0, 6, 0, 0); searchInput.BackgroundTransparency = 1
	searchInput.PlaceholderText = "Search players..."; searchInput.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
	searchInput.Text = ""; searchInput.TextColor3 = Color3.fromRGB(220, 220, 230)
	searchInput.TextSize = 12; searchInput.Font = Enum.Font.Gotham
	searchInput.TextXAlignment = Enum.TextXAlignment.Left; searchInput.ClearTextOnFocus = false; searchInput.Parent = searchContainer
	-- Scroll frame for player rows
	local scroll = Instance.new("ScrollingFrame"); scroll.Name = "PlayerScroll"
	scroll.Size = UDim2.new(1, -12, 1, -44); scroll.Position = UDim2.new(0, 6, 0, 40)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 80); scroll.Parent = container
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
	plScrollFrame = scroll
	-- Search filtering
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		PlayerList.renderList(searchInput.Text, role, accentColor, onAction)
	end)
	return container
end

function PlayerList.renderList(query: string, role: string, accentColor: Color3, onAction: (string, Shared.PlayerInfo) -> ())
	local scroll = plScrollFrame; if not scroll then return end
	for _, child in scroll:GetChildren() do if child:IsA("Frame") then child:Destroy() end end
	local lowerQuery = string.lower(query)
	for i, player in plAllPlayers do
		if query ~= "" and not string.find(string.lower(player.username), lowerQuery, 1, true) then continue end
		local row = Instance.new("Frame"); row.Name = "Player_" .. tostring(player.userId)
		row.Size = UDim2.new(1, 0, 0, 36); row.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		row.BorderSizePixel = 0; row.LayoutOrder = i; row.Parent = scroll
		local rcrn = Instance.new("UICorner"); rcrn.CornerRadius = UDim.new(0, 6); rcrn.Parent = row
		local nameLbl = Instance.new("TextLabel"); nameLbl.Size = UDim2.new(1, -60, 1, 0)
		nameLbl.Position = UDim2.new(0, 10, 0, 0); nameLbl.BackgroundTransparency = 1
		nameLbl.Text = player.username; nameLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
		nameLbl.TextSize = 12; nameLbl.Font = Enum.Font.GothamMedium
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left; nameLbl.Parent = row
		local pingLbl = Instance.new("TextLabel"); pingLbl.Size = UDim2.new(0, 50, 1, 0)
		pingLbl.Position = UDim2.new(1, -56, 0, 0); pingLbl.BackgroundTransparency = 1
		pingLbl.Text = tostring(math.floor(player.ping * 1000)) .. "ms"
		pingLbl.TextColor3 = Color3.fromRGB(140, 140, 160); pingLbl.TextSize = 10
		pingLbl.Font = Enum.Font.Gotham; pingLbl.TextXAlignment = Enum.TextXAlignment.Right; pingLbl.Parent = row
	end
end

function PlayerList.updatePlayers(players: { Shared.PlayerInfo })
	plAllPlayers = players
	PlayerList.renderList("", "Moderator", Color3.fromRGB(70, 115, 255), function() end)
end

-- ModerationView
local ModerationView = {}
function ModerationView.create(parent: GuiObject, accentColor: Color3, onBan: any, onMute: any): Frame
	local container = Instance.new("Frame"); container.Name = "ModerationView"
	container.BackgroundTransparency = 1; container.Size = UDim2.fromScale(1, 1); container.Parent = parent
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 12); pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12); pad.Parent = container
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 22)
	title.BackgroundTransparency = 1; title.Text = "Moderation Actions"
	title.TextColor3 = Color3.fromRGB(220, 220, 230); title.TextSize = 14
	title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = container
	-- Ban form
	local banForm = Instance.new("Frame"); banForm.Name = "BanForm"
	banForm.Size = UDim2.new(0.5, -6, 0, 160); banForm.Position = UDim2.new(0, 0, 0, 28)
	banForm.BackgroundColor3 = Color3.fromRGB(25, 25, 35); banForm.BorderSizePixel = 0; banForm.Parent = container
	local bcrn = Instance.new("UICorner"); bcrn.CornerRadius = UDim.new(0, 8); bcrn.Parent = banForm
	local banTitle = Instance.new("TextLabel"); banTitle.Size = UDim2.new(1, -20, 0, 20)
	banTitle.Position = UDim2.new(0, 10, 0, 10); banTitle.BackgroundTransparency = 1
	banTitle.Text = "Ban Player"; banTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
	banTitle.TextSize = 12; banTitle.Font = Enum.Font.GothamBold
	banTitle.TextXAlignment = Enum.TextXAlignment.Left; banTitle.Parent = banForm
	local banTarget = Instance.new("TextBox"); banTarget.Size = UDim2.new(1, -20, 0, 26)
	banTarget.Position = UDim2.new(0, 10, 0, 36); banTarget.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	banTarget.BorderSizePixel = 0; banTarget.PlaceholderText = "Username..."
	banTarget.PlaceholderColor3 = Color3.fromRGB(100, 100, 120); banTarget.Text = ""
	banTarget.TextColor3 = Color3.fromRGB(220, 220, 230); banTarget.TextSize = 12
	banTarget.Font = Enum.Font.Gotham; banTarget.TextXAlignment = Enum.TextXAlignment.Left; banTarget.Parent = banForm
	local btcrn = Instance.new("UICorner"); btcrn.CornerRadius = UDim.new(0, 6); btcrn.Parent = banTarget
	local banReason = Instance.new("TextBox"); banReason.Size = UDim2.new(1, -20, 0, 26)
	banReason.Position = UDim2.new(0, 10, 0, 68); banReason.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	banReason.BorderSizePixel = 0; banReason.PlaceholderText = "Reason..."
	banReason.PlaceholderColor3 = Color3.fromRGB(100, 100, 120); banReason.Text = ""
	banReason.TextColor3 = Color3.fromRGB(220, 220, 230); banReason.TextSize = 12
	banReason.Font = Enum.Font.Gotham; banReason.TextXAlignment = Enum.TextXAlignment.Left; banReason.Parent = banForm
	local brcrn = Instance.new("UICorner"); brcrn.CornerRadius = UDim.new(0, 6); brcrn.Parent = banReason
	local banBtn = Instance.new("TextButton"); banBtn.Size = UDim2.new(0, 80, 0, 26)
	banBtn.Position = UDim2.new(0, 10, 0, 104); banBtn.BackgroundColor3 = accentColor
	banBtn.BorderSizePixel = 0; banBtn.Text = "Ban"; banBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	banBtn.TextSize = 12; banBtn.Font = Enum.Font.GothamBold; banBtn.Parent = banForm
	local bbcrn = Instance.new("UICorner"); bbcrn.CornerRadius = UDim.new(0, 6); bbcrn.Parent = banBtn
	banBtn.MouseButton1Click:Connect(function()
		if banTarget.Text ~= "" and onBan then onBan(banTarget.Text, Constants.BAN_24_HOURS, banReason.Text) end
	end)
	-- Mute form (right half)
	local muteForm = Instance.new("Frame"); muteForm.Name = "MuteForm"
	muteForm.Size = UDim2.new(0.5, -6, 0, 160); muteForm.Position = UDim2.new(0.5, 6, 0, 28)
	muteForm.BackgroundColor3 = Color3.fromRGB(25, 25, 35); muteForm.BorderSizePixel = 0; muteForm.Parent = container
	local mcrn = Instance.new("UICorner"); mcrn.CornerRadius = UDim.new(0, 8); mcrn.Parent = muteForm
	local muteTitle = Instance.new("TextLabel"); muteTitle.Size = UDim2.new(1, -20, 0, 20)
	muteTitle.Position = UDim2.new(0, 10, 0, 10); muteTitle.BackgroundTransparency = 1
	muteTitle.Text = "Mute Player"; muteTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
	muteTitle.TextSize = 12; muteTitle.Font = Enum.Font.GothamBold
	muteTitle.TextXAlignment = Enum.TextXAlignment.Left; muteTitle.Parent = muteForm
	local muteTarget = Instance.new("TextBox"); muteTarget.Size = UDim2.new(1, -20, 0, 26)
	muteTarget.Position = UDim2.new(0, 10, 0, 36); muteTarget.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	muteTarget.BorderSizePixel = 0; muteTarget.PlaceholderText = "Username..."
	muteTarget.PlaceholderColor3 = Color3.fromRGB(100, 100, 120); muteTarget.Text = ""
	muteTarget.TextColor3 = Color3.fromRGB(220, 220, 230); muteTarget.TextSize = 12
	muteTarget.Font = Enum.Font.Gotham; muteTarget.TextXAlignment = Enum.TextXAlignment.Left; muteTarget.Parent = muteForm
	local mtcrn = Instance.new("UICorner"); mtcrn.CornerRadius = UDim.new(0, 6); mtcrn.Parent = muteTarget
	local muteBtn = Instance.new("TextButton"); muteBtn.Size = UDim2.new(0, 80, 0, 26)
	muteBtn.Position = UDim2.new(0, 10, 0, 104); muteBtn.BackgroundColor3 = accentColor
	muteBtn.BorderSizePixel = 0; muteBtn.Text = "Mute"; muteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	muteBtn.TextSize = 12; muteBtn.Font = Enum.Font.GothamBold; muteBtn.Parent = muteForm
	local mbcrn = Instance.new("UICorner"); mbcrn.CornerRadius = UDim.new(0, 6); mbcrn.Parent = muteBtn
	muteBtn.MouseButton1Click:Connect(function()
		if muteTarget.Text ~= "" and onMute then onMute(muteTarget.Text, Constants.MUTE_30_MIN) end
	end)
	return container
end

-- LogsView
local LogsView = {}
function LogsView.create(parent: GuiObject, accentColor: Color3, onPageChange: any, onFilterChange: any): Frame
	local container = Instance.new("Frame"); container.Name = "LogsView"
	container.BackgroundTransparency = 1; container.Size = UDim2.fromScale(1, 1); container.Parent = parent
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 12); pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12); pad.Parent = container
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 22)
	title.BackgroundTransparency = 1; title.Text = "System Logs"
	title.TextColor3 = Color3.fromRGB(220, 220, 230); title.TextSize = 14
	title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = container
	local scroll = Instance.new("ScrollingFrame"); scroll.Size = UDim2.new(1, 0, 1, -60)
	scroll.Position = UDim2.new(0, 0, 0, 36); scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 4
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.Parent = container
	local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = scroll
	return container
end

-- SettingsView
local SettingsView = {}
function SettingsView.create(parent: GuiObject, settings: Shared.AdminSettings, accentColor: Color3, onSave: (Shared.AdminSettings) -> ()): Frame
	local container = Instance.new("Frame"); container.Name = "SettingsView"
	container.BackgroundTransparency = 1; container.Size = UDim2.fromScale(1, 1); container.Parent = parent
	local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 12); pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16); pad.Parent = container
	local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 24)
	title.BackgroundTransparency = 1; title.Text = "Settings"
	title.TextColor3 = Color3.fromRGB(255, 255, 255); title.TextSize = 14
	title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = container
	local saveBtn = Instance.new("TextButton"); saveBtn.Size = UDim2.new(0, 120, 0, 32)
	saveBtn.Position = UDim2.new(0, 0, 1, -44); saveBtn.BackgroundColor3 = accentColor
	saveBtn.BorderSizePixel = 0; saveBtn.Text = "Save Settings"
	saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255); saveBtn.TextSize = 12
	saveBtn.Font = Enum.Font.GothamBold; saveBtn.Parent = container
	local scrn = Instance.new("UICorner"); scrn.CornerRadius = UDim.new(0, 6); scrn.Parent = saveBtn
	saveBtn.MouseButton1Click:Connect(function() onSave(settings) end)
	return container
end

-- Modal
local Modal = {}
function Modal.create(parent: any): { show: (Shared.ModalConfig, (boolean) -> ()) -> (), hide: () -> () }
	local backdrop = Instance.new("TextButton"); backdrop.Name = "ModalBackdrop"
	backdrop.Size = UDim2.fromScale(1, 1); backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1; backdrop.BorderSizePixel = 0; backdrop.Text = ""
	backdrop.ZIndex = 100; backdrop.Visible = false; backdrop.Parent = parent
	local modalFrame = Instance.new("Frame"); modalFrame.Name = "ModalFrame"
	modalFrame.Size = UDim2.fromOffset(360, 180); modalFrame.Position = UDim2.fromScale(0.5, 0.5)
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5); modalFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	modalFrame.BorderSizePixel = 0; modalFrame.ZIndex = 101; modalFrame.Visible = false; modalFrame.Parent = parent
	local mcrn = Instance.new("UICorner"); mcrn.CornerRadius = UDim.new(0, 10); mcrn.Parent = modalFrame
	local titleLbl = Instance.new("TextLabel"); titleLbl.Size = UDim2.new(1, -40, 0, 20)
	titleLbl.Position = UDim2.new(0, 20, 0, 20); titleLbl.BackgroundTransparency = 1
	titleLbl.TextColor3 = Color3.fromRGB(240, 240, 245); titleLbl.TextSize = 14
	titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextXAlignment = Enum.TextXAlignment.Center; titleLbl.ZIndex = 102; titleLbl.Parent = modalFrame
	local msgLbl = Instance.new("TextLabel"); msgLbl.Size = UDim2.new(1, -40, 0, 36)
	msgLbl.Position = UDim2.new(0, 20, 0, 48); msgLbl.BackgroundTransparency = 1
	msgLbl.TextColor3 = Color3.fromRGB(180, 180, 195); msgLbl.TextSize = 12
	msgLbl.Font = Enum.Font.Gotham; msgLbl.TextWrapped = true; msgLbl.ZIndex = 102; msgLbl.Parent = modalFrame
	local confirmBtn = Instance.new("TextButton"); confirmBtn.Size = UDim2.fromOffset(100, 30)
	confirmBtn.Position = UDim2.new(0.5, 4, 0, 104); confirmBtn.BackgroundColor3 = Color3.fromRGB(65, 115, 255)
	confirmBtn.BorderSizePixel = 0; confirmBtn.Text = "Confirm"; confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.TextSize = 12; confirmBtn.Font = Enum.Font.GothamMedium; confirmBtn.ZIndex = 103; confirmBtn.Parent = modalFrame
	local cfcrn = Instance.new("UICorner"); cfcrn.CornerRadius = UDim.new(0, 6); cfcrn.Parent = confirmBtn
	local cancelBtn = Instance.new("TextButton"); cancelBtn.Size = UDim2.fromOffset(100, 30)
	cancelBtn.Position = UDim2.new(0.5, -104, 0, 104); cancelBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
	cancelBtn.BorderSizePixel = 0; cancelBtn.Text = "Cancel"; cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.TextSize = 12; cancelBtn.Font = Enum.Font.GothamMedium; cancelBtn.ZIndex = 103; cancelBtn.Parent = modalFrame
	local cccrn = Instance.new("UICorner"); cccrn.CornerRadius = UDim.new(0, 6); cccrn.Parent = cancelBtn
	local currentCb: ((boolean) -> ())? = nil
	local function hideModal()
		backdrop.Visible = false; modalFrame.Visible = false
	end
	confirmBtn.MouseButton1Click:Connect(function() hideModal(); if currentCb then currentCb(true) end end)
	cancelBtn.MouseButton1Click:Connect(function() hideModal(); if currentCb then currentCb(false) end end)
	backdrop.MouseButton1Click:Connect(function() hideModal(); if currentCb then currentCb(false) end end)
	return {
		show = function(config: Shared.ModalConfig, cb: (boolean) -> ())
			currentCb = cb; titleLbl.Text = config.title; msgLbl.Text = config.message
			confirmBtn.Text = config.confirmText or "Confirm"; cancelBtn.Text = config.cancelText or "Cancel"
			confirmBtn.BackgroundColor3 = if config.destructive then Color3.fromRGB(220, 60, 60) else Color3.fromRGB(65, 115, 255)
			backdrop.BackgroundTransparency = 0.5; backdrop.Visible = true; modalFrame.Visible = true
		end,
		hide = hideModal,
	}
end

-- NotificationCenter
local NotificationCenter = {}
function NotificationCenter.create(parent: any, accentColor: Color3, onDismiss: (number) -> (), onMarkAllRead: () -> ()): { frame: Frame, updateNotifications: (any) -> (), show: () -> (), hide: () -> () }
	local panel = Instance.new("Frame"); panel.Name = "NotificationCenterPanel"
	panel.Size = UDim2.new(0, 300, 1, -48); panel.Position = UDim2.new(1, 310, 0, 48)
	panel.BackgroundColor3 = Color3.fromRGB(22, 22, 30); panel.BorderSizePixel = 0
	panel.Visible = false; panel.ZIndex = 90; panel.ClipsDescendants = true; panel.Parent = parent
	local pcrn = Instance.new("UICorner"); pcrn.CornerRadius = UDim.new(0, 8); pcrn.Parent = panel
	local isVis = false
	return {
		frame = panel,
		updateNotifications = function(_notifs: any) end,
		show = function()
			if isVis then return end; isVis = true; panel.Visible = true
			TweenService:Create(panel, createTweenInfo(Constants.ANIM_PANEL_OPEN), { Position = UDim2.new(1, -310, 0, 48) }):Play()
		end,
		hide = function()
			if not isVis then return end; isVis = false
			local t = TweenService:Create(panel, createTweenInfo(Constants.ANIM_PANEL_CLOSE), { Position = UDim2.new(1, 310, 0, 48) })
			t:Play(); t.Completed:Connect(function(s) if s == Enum.PlaybackState.Completed then panel.Visible = false end end)
		end,
	}
end

-- ============================================================================
-- SECTION 8: UI ENGINE
-- ============================================================================

local UIEngine = {}
local uiScreenGui: ScreenGui? = nil
local uiMainPanel: CanvasGroup? = nil
local uiCurrentTab: string = "Dashboard"
local uiViews: { [string]: Frame } = {}
local uiModalInstance: any = nil

function UIEngine.init(settings: {
	accentColor: Color3, glassmorphism: boolean, role: string,
	adminName: string, settings: Shared.AdminSettings,
	onTabChanged: ((string) -> ())?, onPlayerAction: ((string, Shared.PlayerInfo) -> ())?,
	onBan: ((string, number, string) -> ())?, onMute: ((string, number) -> ())?,
	onSettingsSave: ((Shared.AdminSettings) -> ())?,
})
	local player = Players.LocalPlayer; if not player then return end
	local accentColor = settings.accentColor
	local role = settings.role
	local adminName = settings.adminName
	local adminSettings = settings.settings

	-- ScreenGui
	local gui = Instance.new("ScreenGui"); gui.Name = "AdminPanel"
	gui.DisplayOrder = 50; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui"); uiScreenGui = gui

	-- MainPanel (compact 720x460 centered window)
	local panel = Instance.new("CanvasGroup"); panel.Name = "MainPanel"
	panel.Size = UDim2.new(0, 720, 0, 460); panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
	panel.BorderSizePixel = 0; panel.GroupTransparency = 1; panel.Visible = false; panel.Parent = gui
	local panelCorner = Instance.new("UICorner"); panelCorner.CornerRadius = UDim.new(0, 10); panelCorner.Parent = panel
	uiMainPanel = panel

	-- Glassmorphism
	if settings.glassmorphism then
		panel.BackgroundTransparency = 0.3
		local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.85; stroke.Thickness = 1; stroke.Parent = panel
	end

	-- Sidebar (140px wide, collapses to 40px)
	Sidebar.create(panel, accentColor, function(tabName: string)
		UIEngine.navigateTo(tabName)
		if settings.onTabChanged then settings.onTabChanged(tabName) end
	end)
	if adminSettings.sidebarDefaultState == "collapsed" then Sidebar.collapse() end

	-- Content area (offset by sidebar width 140px)
	local contentArea = Instance.new("Frame"); contentArea.Name = "ContentArea"
	contentArea.Size = UDim2.new(1, -140, 1, 0); contentArea.Position = UDim2.new(0, 140, 0, 0)
	contentArea.BackgroundTransparency = 1; contentArea.ClipsDescendants = true; contentArea.Parent = panel

	-- Topbar (36px height)
	Topbar.create(contentArea, adminName, role, accentColor)

	-- View container
	local viewCont = Instance.new("Frame"); viewCont.Name = "ViewContainer"
	viewCont.Size = UDim2.new(1, 0, 1, -36); viewCont.Position = UDim2.new(0, 0, 0, 36)
	viewCont.BackgroundTransparency = 1; viewCont.ClipsDescendants = true; viewCont.Parent = contentArea

	-- Create views
	local dashFrame = Dashboard.create(viewCont, accentColor); dashFrame.Visible = true
	uiViews["Dashboard"] = dashFrame

	local playerFrame = PlayerList.create(viewCont, role, accentColor, function(action: string, p: Shared.PlayerInfo)
		if settings.onPlayerAction then settings.onPlayerAction(action, p) end
	end); playerFrame.Visible = false; uiViews["Players"] = playerFrame

	local modFrame = ModerationView.create(viewCont, accentColor, settings.onBan, settings.onMute)
	modFrame.Visible = false; uiViews["Moderation"] = modFrame

	local serverFrame = Instance.new("Frame"); serverFrame.Name = "ServerView"
	serverFrame.Size = UDim2.fromScale(1, 1); serverFrame.BackgroundTransparency = 1
	serverFrame.Visible = false; serverFrame.Parent = viewCont; uiViews["Server"] = serverFrame

	local logsFrame = LogsView.create(viewCont, accentColor, nil, nil)
	logsFrame.Visible = false; uiViews["Logs"] = logsFrame

	local settingsFrame = SettingsView.create(viewCont, adminSettings, accentColor, function(s: Shared.AdminSettings)
		if settings.onSettingsSave then settings.onSettingsSave(s) end
	end); settingsFrame.Visible = false; uiViews["Settings"] = settingsFrame

	-- Modal
	uiModalInstance = Modal.create(gui)

	uiCurrentTab = "Dashboard"
end

function UIEngine.show()
	local panel = uiMainPanel; if not panel then return end
	TweenController.scaleIn(panel, Constants.ANIM_PANEL_OPEN)
end

function UIEngine.hide()
	local panel = uiMainPanel; if not panel then return end
	TweenController.scaleOut(panel, Constants.ANIM_PANEL_CLOSE)
end

function UIEngine.navigateTo(tab: string)
	if tab == uiCurrentTab then return end
	local outView = uiViews[uiCurrentTab]; local inView = uiViews[tab]
	if not outView or not inView then return end
	Sidebar.setActiveTab(tab)
	TweenController.transitionViews(outView, inView)
	uiCurrentTab = tab
end

function UIEngine.updateStats(stats: Shared.ServerStats)
	Dashboard.updateStats(stats)
	Topbar.updatePlayerCount(stats.playerCount, stats.maxPlayers)
end

function UIEngine.updatePlayerList(players: { Shared.PlayerInfo })
	PlayerList.updatePlayers(players)
end

function UIEngine.showModal(config: Shared.ModalConfig, callback: (boolean) -> ())
	if uiModalInstance then uiModalInstance.show(config, callback) end
end

-- ============================================================================
-- SECTION 9: COMMAND PALETTE
-- ============================================================================

local CommandPalette = {}
local cpIsOpen: boolean = false
local cpScreenGui: ScreenGui? = nil

function CommandPalette.init(role: string)
	-- Ctrl+K keybind
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.K and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			if cpIsOpen then CommandPalette.close() else CommandPalette.open() end
		elseif input.KeyCode == Enum.KeyCode.Escape and cpIsOpen then
			CommandPalette.close()
		end
	end)
end

function CommandPalette.open()
	cpIsOpen = true
end

function CommandPalette.close()
	cpIsOpen = false
end

-- ============================================================================
-- SECTION 10: ENTRY POINT / BOOTSTRAP
-- ============================================================================

local player = Players.LocalPlayer
local remotes = Shared.getRemotes()
local sessionToken: string = ""
local panelRole: string = ""
local panelActive: boolean = false
local wasStale: boolean = false

-- Initialize notification system
NotificationSystem.init()

-- Attempt to initialize session with server
local initSuccess, initData = pcall(function()
	return remotes.Panel_Init:InvokeServer()
end)

if not initSuccess or not initData then
	return
end

-- Extract session data
sessionToken = initData.token or ""
panelRole = initData.role or ""
local adminSettings = initData.settings

-- Apply settings to notification system
if adminSettings and adminSettings.notificationDuration then
	NotificationSystem.setDuration(adminSettings.notificationDuration)
end

panelActive = true

-- Initialize UI Engine
UIEngine.init({
	accentColor = if adminSettings then adminSettings.accentColor else Color3.fromRGB(70, 115, 255),
	glassmorphism = if adminSettings then adminSettings.glassmorphism else false,
	role = panelRole,
	adminName = player.Name,
	settings = adminSettings or {
		accentColor = Color3.fromRGB(70, 115, 255),
		glassmorphism = false,
		notificationDuration = 5,
		sidebarDefaultState = "expanded",
		keybinds = { togglePanel = Enum.KeyCode.F2, commandPalette = Enum.KeyCode.K },
	},
	onTabChanged = nil,
	onPlayerAction = function(action: string, targetPlayer: Shared.PlayerInfo)
		remotes.Admin_Request:FireServer(action, { targetUserId = targetPlayer.userId }, sessionToken)
	end,
	onBan = function(target: string, duration: number, reason: string)
		remotes.Admin_Request:FireServer("ban", { targetUserId = 0, duration = duration, reason = reason }, sessionToken)
	end,
	onMute = function(target: string, duration: number)
		remotes.Admin_Request:FireServer("mute", { targetUserId = 0, duration = duration }, sessionToken)
	end,
	onSettingsSave = function(settings: Shared.AdminSettings)
		remotes.Save_Settings:InvokeServer(sessionToken, settings)
	end,
})

-- Show the panel
UIEngine.show()

-- Initialize command palette
CommandPalette.init(panelRole)

-- "R" Toggle Button (always visible, separate ScreenGui with DisplayOrder 999)
do
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	local toggleGui = Instance.new("ScreenGui")
	toggleGui.Name = "AdminToggleButton"
	toggleGui.DisplayOrder = 999
	toggleGui.ResetOnSpawn = false
	toggleGui.IgnoreGuiInset = true
	toggleGui.Parent = playerGui

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "RToggle"
	toggleBtn.Size = UDim2.new(0, 28, 0, 28)
	toggleBtn.Position = UDim2.new(0, 72, 0, 4)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = "R"
	toggleBtn.TextSize = 14
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
	toggleBtn.Parent = toggleGui

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleBtn

	toggleBtn.MouseButton1Click:Connect(function()
		local panel = uiMainPanel
		if panel and panel.Visible then
			UIEngine.hide()
		else
			UIEngine.show()
		end
	end)
end

-- Admin_Response handler
remotes.Admin_Response.OnClientEvent:Connect(function(result: any)
	local actionResult = result :: Shared.ActionResult
	if actionResult.success then
		NotificationSystem.notify({ category = "success", message = actionResult.data and actionResult.data.message or "Action completed successfully" })
	else
		local errorCode: string? = actionResult.errorCode
		local errorMessage: string = actionResult.error or "An error occurred"
		if errorCode == "rate_limited" then
			NotificationSystem.notify({ category = "warning", message = "Requests are being throttled" })
		elseif errorCode == "suspended" then
			NotificationSystem.notify({ category = "warning", message = string.format("Access suspended for %d seconds", Constants.SUSPENSION_DURATION) })
		else
			NotificationSystem.notify({ category = "error", message = errorMessage })
		end
	end
end)

-- Stats_Update handler
remotes.Stats_Update.OnClientEvent:Connect(function(stats: any)
	StaleDetector.recordUpdate()
	if wasStale then wasStale = false; Dashboard.setStale(false) end
	UIEngine.updateStats(stats :: Shared.ServerStats)
end)

-- Stale-data detection loop
task.spawn(function()
	while panelActive do
		task.wait(1)
		if StaleDetector.isStale() then
			if not wasStale then wasStale = true; Dashboard.setStale(true) end
		end
	end
end)

-- Access_Revoked handler
remotes.Access_Revoked.OnClientEvent:Connect(function()
	panelActive = false
	NotificationSystem.notify({ category = "error", message = "Admin access has been revoked" })
	UIEngine.hide()
end)
