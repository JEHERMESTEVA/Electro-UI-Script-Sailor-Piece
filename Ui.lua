--[[
╔══════════════════════════════════════════════════════════════════════╗
║   NEXUS UI  v4.1  ·  Stable Clean Module                            ║
║   Sidebar Layout  ·  Sailor Piece Style                             ║
╚══════════════════════════════════════════════════════════════════════╝
]]

-- Services
local RS   = game:GetService("RunService")
local UIS  = game:GetService("UserInputService")
local TS   = game:GetService("TweenService")
local PL   = game:GetService("Players")
local LP   = PL.LocalPlayer
local Mouse = LP:GetMouse()

-- Spring
local Spring = {}; Spring.__index = Spring
function Spring.new(k,d)
	return setmetatable({k=k or 200,d=d or 20,p=0,v=0,t=0},Spring)
end
function Spring:step(dt)
	dt = math.min(dt, .05)
	local x, v = self.p - self.t, self.v
	local disc = self.d^2/4 - self.k
	if disc < 0 then
		local w = math.sqrt(-disc)
		local e = math.exp(-self.d*dt/2)
		self.p = self.t + e*(x*math.cos(w*dt) + (v + self.d/2*x)/w*math.sin(w*dt))
		self.v = e*((v+self.d/2*x)*math.cos(w*dt) - (x*w + (v+self.d/2*x)*self.d/(2*w))*math.sin(w*dt))
	else
		local sq = math.sqrt(math.max(disc,0))
		local r1, r2 = -self.d/2 + sq, -self.d/2 - sq
		local den = r2-r1
		if math.abs(den) < 1e-9 then den = 1e-9 end
		local c2 = (v-r1*x)/den
		local c1 = x-c2
		self.p = self.t + c1*math.exp(r1*dt) + c2*math.exp(r2*dt)
		self.v = c1*r1*math.exp(r1*dt) + c2*r2*math.exp(r2*dt)
	end
	return self.p
end
function Spring:done()
	return math.abs(self.p-self.t) < .2 and math.abs(self.v) < .2
end

-- Render loop
local FX = {}
local _fxid = 0
local function Fx(fn)
	_fxid += 1
	FX[_fxid] = fn
	return _fxid
end
local function KFx(id)
	FX[id] = nil
end
RS.RenderStepped:Connect(function(dt)
	for _,f in pairs(FX) do
		pcall(f, dt)
	end
end)

-- Palette
local C = {
	WinBg      = Color3.fromRGB(18, 18, 24),

	SideBg     = Color3.fromRGB(13, 13, 18),
	SideHov    = Color3.fromRGB(22, 22, 30),
	SideSel    = Color3.fromRGB(26, 26, 36),

	ContentBg  = Color3.fromRGB(23, 23, 31),
	SectionBg  = Color3.fromRGB(28, 28, 38),
	RowBg      = Color3.fromRGB(23, 23, 31),
	DropBg     = Color3.fromRGB(20, 20, 28),
	DropHov    = Color3.fromRGB(30, 30, 42),

	Green      = Color3.fromRGB(72, 210, 120),
	GreenDim   = Color3.fromRGB(40, 110, 65),
	Purple     = Color3.fromRGB(140, 100, 255),
	PurpleDim  = Color3.fromRGB(80, 55, 160),

	TextBright = Color3.fromRGB(230, 230, 240),
	TextMid    = Color3.fromRGB(160, 160, 178),
	TextDim    = Color3.fromRGB(100, 100, 118),

	Border     = Color3.fromRGB(38, 38, 54),
	BorderBrt  = Color3.fromRGB(55, 55, 78),
	White      = Color3.new(1,1,1),
	Black      = Color3.new(0,0,0),

	BadgeBg    = Color3.fromRGB(55, 28, 110),
	BadgeText  = Color3.fromRGB(195, 155, 255),

	Err        = Color3.fromRGB(220, 70, 70),
	Warn       = Color3.fromRGB(255, 190, 50),
}

-- Helpers
local function New(cls, props, par)
	local o = Instance.new(cls)
	for k,v in pairs(props or {}) do
		pcall(function() o[k] = v end)
	end
	if par then o.Parent = par end
	return o
end

local function Cr(p,r)
	New("UICorner",{CornerRadius=UDim.new(0,r or 6)},p)
end

local function St(p,c,t,tr)
	return New("UIStroke",{
		Color = c or C.Border,
		Thickness = t or 1,
		Transparency = tr or 0,
	},p)
end

local function Pd(p,x,y)
	New("UIPadding",{
		PaddingLeft = UDim.new(0,x or 8),
		PaddingRight = UDim.new(0,x or 8),
		PaddingTop = UDim.new(0,y or 6),
		PaddingBottom = UDim.new(0,y or 6),
	},p)
end

local function Ls(p,g,d)
	return New("UIListLayout",{
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0,g or 4),
		FillDirection = d or Enum.FillDirection.Vertical,
	},p)
end

local function Tw(o,t,pr)
	return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), pr)
end

local function Txt(p,text,size,col,font,xa,ya)
	return New("TextLabel",{
		BackgroundTransparency = 1,
		Text = text,
		Font = font or Enum.Font.Gotham,
		TextSize = size or 13,
		TextColor3 = col or C.TextBright,
		TextXAlignment = xa or Enum.TextXAlignment.Left,
		TextYAlignment = ya or Enum.TextYAlignment.Center,
		Size = UDim2.fromScale(1,1),
	},p)
end

local function SafeDisconnect(conn)
	if conn then
		pcall(function() conn:Disconnect() end)
	end
end

-- Root ScreenGui
local GUI = New("ScreenGui",{
	Name = "NexusUI_v4_1",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = false,
	DisplayOrder = 100,
}, LP:WaitForChild("PlayerGui"))

-- Ripple
local function Ripple(parent, col)
	if not parent or not parent.Parent then return end
	local ap = parent.AbsolutePosition
	local as = parent.AbsoluteSize
	local lx = Mouse.X - ap.X
	local ly = Mouse.Y - ap.Y

	local maxD = 0
	for _,c in ipairs({
		Vector2.zero,
		Vector2.new(as.X,0),
		Vector2.new(0,as.Y),
		Vector2.new(as.X,as.Y)
	}) do
		local d = (c - Vector2.new(lx,ly)).Magnitude
		if d > maxD then maxD = d end
	end

	local r = New("Frame",{
		Size = UDim2.fromOffset(0,0),
		Position = UDim2.fromOffset(lx,ly),
		AnchorPoint = Vector2.new(.5,.5),
		BackgroundColor3 = col or C.White,
		BackgroundTransparency = 0.85,
		ZIndex = parent.ZIndex + 8,
	}, parent)
	Cr(r,99)

	local tw = Tw(r,.45,{
		Size = UDim2.fromOffset(maxD*2.2,maxD*2.2),
		BackgroundTransparency = 1
	})
	tw:Play()

	task.delay(.5,function()
		if r and r.Parent then r:Destroy() end
	end)
end

-- Drag
local function Drag(frame, handle, lockFn)
	local drag = false
	local last = Vector2.zero
	local vel = Vector2.zero

	local rid = Fx(function()
		if not frame or not frame.Parent then
			KFx(rid)
			return
		end
		if drag then return end
		if vel.Magnitude < 0.3 then
			vel = Vector2.zero
			return
		end
		vel = vel * 0.82
		pcall(function()
			frame.Position = UDim2.new(
				frame.Position.X.Scale, frame.Position.X.Offset + vel.X,
				frame.Position.Y.Scale, frame.Position.Y.Offset + vel.Y
			)
		end)
	end)

	handle.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		if lockFn and lockFn() then return end
		drag = true
		last = Vector2.new(i.Position.X, i.Position.Y)
		vel = Vector2.zero
	end)

	local c1 = UIS.InputChanged:Connect(function(i)
		if not drag or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local cur = Vector2.new(i.Position.X, i.Position.Y)
		vel = cur - last
		last = cur
		pcall(function()
			frame.Position = UDim2.new(
				frame.Position.X.Scale, frame.Position.X.Offset + vel.X,
				frame.Position.Y.Scale, frame.Position.Y.Offset + vel.Y
			)
		end)
	end)

	local c2 = UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = false
		end
	end)

	frame.Destroying:Connect(function()
		SafeDisconnect(c1)
		SafeDisconnect(c2)
	end)
end

-- Notifications
local Notifs = {}
local NOTIF_H = 58
local NOTIF_G = 6

local function Notify(title, body, dur, col)
	col = col or C.Green
	dur = dur or 3.5

	local idx = #Notifs + 1
	local endY = -(NOTIF_H + NOTIF_G) * idx - 8

	local f = New("Frame",{
		Size = UDim2.fromOffset(260,NOTIF_H),
		Position = UDim2.new(0,-270,1,endY),
		BackgroundColor3 = C.SideBg,
		ZIndex = 180,
		ClipsDescendants = true,
	}, GUI)
	Cr(f,8)
	St(f,C.Border,1,0.3)

	local bar = New("Frame",{
		Size = UDim2.new(0,3,1,-12),
		Position = UDim2.fromOffset(6,6),
		BackgroundColor3 = col,
		ZIndex = 181,
	}, f)
	Cr(bar,2)

	New("Frame",{
		Size = UDim2.new(1,0,0,1),
		BackgroundColor3 = col,
		BackgroundTransparency = 0.4,
		ZIndex = 181,
	}, f)

	New("TextLabel",{
		Size = UDim2.new(1,-18,0,22),
		Position = UDim2.fromOffset(14,5),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.TextBright,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 182,
	}, f)

	New("TextLabel",{
		Size = UDim2.new(1,-18,0,18),
		Position = UDim2.fromOffset(14,26),
		BackgroundTransparency = 1,
		Text = body,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 182,
	}, f)

	table.insert(Notifs, f)

	local tin = Tw(f,.28,{Position = UDim2.new(0,8,1,endY)})
	tin:Play()

	task.delay(dur, function()
		if not f or not f.Parent then return end
		local tout = Tw(f,.22,{Position = UDim2.new(0,-270,1,endY)})
		tout:Play()
		task.delay(.25,function()
			if f and f.Parent then f:Destroy() end
			for i,v in ipairs(Notifs) do
				if v == f then
					table.remove(Notifs,i)
					break
				end
			end
		end)
	end)
end

-- Stable dropdown registry
local OpenDropdowns = {}

local function CloseAllDropdowns(except)
	for dd in pairs(OpenDropdowns) do
		if dd ~= except and dd.Close then
			dd:Close()
		end
	end
end

-- Dropdown
local function MakeDropdown(parent, cfg)
	cfg = cfg or {}
	local opts = cfg.Options or {}
	local fn = cfg.OnChange or function() end
	local cur = cfg.Default or opts[1] or "Select..."
	local open = false
	local ITEM_H = 28
	local MAX_VISIBLE = 5

	local wrap = New("Frame",{
		Size = UDim2.new(1,0,0,34),
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, parent)

	New("TextLabel",{
		Size = UDim2.new(.42,0,1,0),
		BackgroundTransparency = 1,
		Text = cfg.Label or "",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = C.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 11,
	}, wrap)

	local btn = New("TextButton",{
		Size = UDim2.new(.55,0,0,28),
		Position = UDim2.new(.45,0,.5,-14),
		BackgroundColor3 = C.DropBg,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 11,
	}, wrap)
	Cr(btn,6)
	St(btn,C.Border,1,0.3)

	local selLbl = New("TextLabel",{
		Size = UDim2.new(1,-26,1,0),
		Position = UDim2.fromOffset(8,0),
		BackgroundTransparency = 1,
		Text = cur,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.TextBright,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 12,
	}, btn)

	local chev = New("TextLabel",{
		Size = UDim2.fromOffset(20,28),
		Position = UDim2.new(1,-22,0,0),
		BackgroundTransparency = 1,
		Text = "⌄",
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C.TextDim,
		ZIndex = 12,
	}, btn)

	local list = New("Frame",{
		Size = UDim2.new(1,0,0,0),
		Position = UDim2.new(0,0,1,4),
		BackgroundColor3 = C.DropBg,
		ClipsDescendants = true,
		ZIndex = 50,
		Visible = false,
	}, btn)
	Cr(list,6)
	St(list,C.Border,1,0.2)

	local scroll = New("ScrollingFrame",{
		Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = C.Green,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 51,
	}, list)
	local ll = Ls(scroll,1)
	Pd(scroll,2,2)

	local dropdownApi = {}

	function dropdownApi:Close()
		if not open then return end
		open = false
		local tw1 = Tw(list,.15,{Size = UDim2.new(1,0,0,0)})
		local tw2 = Tw(chev,.15,{Rotation = 0})
		tw1:Play()
		tw2:Play()
		task.delay(.16,function()
			if not open and list and list.Parent then
				list.Visible = false
			end
		end)
		OpenDropdowns[dropdownApi] = nil
	end

	local function setValue(v, fire)
		cur = v
		selLbl.Text = v
		if fire ~= false then
			fn(v)
		end
	end

	for _,opt in ipairs(opts) do
		local item = New("TextButton",{
			Size = UDim2.new(1,0,0,ITEM_H),
			BackgroundColor3 = C.DropBg,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 51,
		}, scroll)
		Cr(item,4)

		New("TextLabel",{
			Size = UDim2.new(1,-12,1,0),
			Position = UDim2.fromOffset(8,0),
			BackgroundTransparency = 1,
			Text = tostring(opt),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = C.TextBright,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 52,
		}, item)

		item.MouseEnter:Connect(function()
			local tw = Tw(item,.1,{BackgroundColor3 = C.DropHov}); tw:Play()
		end)
		item.MouseLeave:Connect(function()
			local tw = Tw(item,.1,{BackgroundColor3 = C.DropBg}); tw:Play()
		end)
		item.MouseButton1Click:Connect(function()
			setValue(tostring(opt), true)
			dropdownApi:Close()
			Ripple(btn,C.Green)
		end)
	end

	btn.MouseButton1Click:Connect(function()
		if not open then
			CloseAllDropdowns(dropdownApi)
		end
		open = not open
		list.Visible = true
		local listH = math.min(#opts, MAX_VISIBLE) * ITEM_H + 4
		local tw1 = Tw(list,.18,{Size = UDim2.new(1,0,0,open and listH or 0)})
		local tw2 = Tw(chev,.18,{Rotation = open and 180 or 0})
		tw1:Play()
		tw2:Play()
		if open then
			OpenDropdowns[dropdownApi] = true
		else
			task.delay(.19,function()
				if not open and list and list.Parent then
					list.Visible = false
				end
			end)
			OpenDropdowns[dropdownApi] = nil
		end
		Ripple(btn)
	end)

	btn.MouseEnter:Connect(function()
		local tw = Tw(btn,.12,{BackgroundColor3 = C.DropHov}); tw:Play()
	end)
	btn.MouseLeave:Connect(function()
		local tw = Tw(btn,.12,{BackgroundColor3 = C.DropBg}); tw:Play()
	end)

	if cfg.Default then
		setValue(cfg.Default, false)
	end

	dropdownApi.Frame = wrap
	dropdownApi.Get = function() return cur end
	dropdownApi.Set = function(_,v) setValue(v,true) end

	wrap.Destroying:Connect(function()
		OpenDropdowns[dropdownApi] = nil
	end)

	return dropdownApi
end

-- Global click outside dropdowns
UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		CloseAllDropdowns(nil)
	end
end)

-- Toggle
local function MakeToggle(parent, cfg)
	cfg = cfg or {}
	local val = cfg.Default or false
	local fn = cfg.OnChange or function() end

	local row = New("Frame",{
		Size = UDim2.new(1,0,0,32),
		BackgroundTransparency = 1,
	}, parent)

	New("TextLabel",{
		Size = UDim2.new(1,-52,1,0),
		BackgroundTransparency = 1,
		Text = cfg.Label or "Toggle",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = C.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local track = New("TextButton",{
		Size = UDim2.fromOffset(44,24),
		Position = UDim2.new(1,-44,.5,-12),
		BackgroundColor3 = val and C.Green or C.Border,
		Text = "",
		AutoButtonColor = false,
	}, row)
	Cr(track,99)

	local knob = New("Frame",{
		Size = UDim2.fromOffset(18,18),
		Position = UDim2.fromOffset(val and 23 or 3,3),
		BackgroundColor3 = C.White,
	}, track)
	Cr(knob,99)

	New("UIGradient",{
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0,.3),
			NumberSequenceKeypoint.new(1,1),
		}),
		Rotation = 90,
	}, knob)

	local ksp = Spring.new(400,26)
	ksp.p = val and 23 or 3
	ksp.t = ksp.p

	local rid = Fx(function(dt)
		if not row or not row.Parent then
			KFx(rid)
			return
		end
		knob.Position = UDim2.fromOffset(ksp:step(dt),3)
	end)

	local busy = false
	track.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		val = not val
		ksp.t = val and 23 or 3
		local tw = Tw(track,.16,{BackgroundColor3 = val and C.Green or C.Border})
		tw:Play()
		fn(val)
		task.delay(.05,function() busy = false end)
	end)

	return {
		Frame = row,
		Get = function() return val end,
		Set = function(_,v)
			val = not not v
			ksp.t = val and 23 or 3
			local tw = Tw(track,.16,{BackgroundColor3 = val and C.Green or C.Border})
			tw:Play()
			fn(val)
		end
	}
end

-- Button
local function MakeButton(parent, cfg)
	cfg = cfg or {}
	local col = cfg.Color or C.Green
	local fn = cfg.OnClick or function() end

	local wrap = New("Frame",{
		Size = UDim2.new(1,0,0,32),
		BackgroundTransparency = 1,
	}, parent)

	if cfg.Label then
		New("TextLabel",{
			Size = UDim2.new(1,-100,1,0),
			BackgroundTransparency = 1,
			Text = cfg.Label,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = C.TextMid,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, wrap)
	end

	local bw = cfg.Label and 90 or 200
	local btn = New("TextButton",{
		Size = UDim2.fromOffset(bw,26),
		Position = cfg.Label and UDim2.new(1,-bw,.5,-13) or UDim2.new(0,0,.5,-13),
		BackgroundColor3 = C.SideBg,
		Text = "",
		AutoButtonColor = false,
		ClipsDescendants = true,
		ZIndex = 10,
	}, wrap)
	Cr(btn,6)
	St(btn,col,1,0.5)

	New("TextLabel",{
		Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1,
		Text = cfg.Text or cfg.Label or "Button",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = col,
		ZIndex = 11,
	}, btn)

	local sc = New("UIScale",{Scale = 1},btn)
	local sp = Spring.new(420,24)
	sp.t = 1

	local rid = Fx(function(dt)
		if not btn or not btn.Parent then
			KFx(rid)
			return
		end
		sc.Scale = sp:step(dt)
	end)

	btn.MouseEnter:Connect(function()
		sp.t = 1.06
		local tw = Tw(btn,.12,{BackgroundColor3 = C.SideHov}); tw:Play()
	end)
	btn.MouseLeave:Connect(function()
		sp.t = 1
		local tw = Tw(btn,.12,{BackgroundColor3 = C.SideBg}); tw:Play()
	end)
	btn.MouseButton1Down:Connect(function()
		sp.t = 0.93
		sp.v = -3
	end)
	btn.MouseButton1Up:Connect(function()
		sp.t = 1.04
		Ripple(btn,col)
		task.delay(.04, fn)
	end)

	return {Frame = wrap}
end

-- Slider
local function MakeSlider(parent, cfg)
	cfg = cfg or {}
	local mn = cfg.Min or 0
	local mx = cfg.Max or 100
	local def = cfg.Default or mn
	local fn = cfg.OnChange or function() end
	local cur = math.clamp(def, mn, mx)

	local hold = New("Frame",{
		Size = UDim2.new(1,0,0,48),
		BackgroundTransparency = 1,
	}, parent)

	local top = New("Frame",{
		Size = UDim2.new(1,0,0,18),
		BackgroundTransparency = 1,
	}, hold)

	New("TextLabel",{
		Size = UDim2.new(.75,0,1,0),
		BackgroundTransparency = 1,
		Text = cfg.Label or "Slider",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = C.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, top)

	local valL = New("TextLabel",{
		Size = UDim2.new(.25,0,1,0),
		Position = UDim2.fromScale(.75,0),
		BackgroundTransparency = 1,
		Text = tostring(cur),
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Green,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, top)

	local track = New("Frame",{
		Size = UDim2.new(1,0,0,4),
		Position = UDim2.fromOffset(0,24),
		BackgroundColor3 = C.Border,
	}, hold)
	Cr(track,99)

	local t0 = (cur-mn)/(mx-mn == 0 and 1 or (mx-mn))
	local fill = New("Frame",{
		Size = UDim2.fromScale(t0,1),
		BackgroundColor3 = C.Green,
	}, track)
	Cr(fill,99)

	local knob = New("Frame",{
		Size = UDim2.fromOffset(12,12),
		AnchorPoint = Vector2.new(.5,.5),
		Position = UDim2.new(t0,0,.5,0),
		BackgroundColor3 = C.White,
	}, track)
	Cr(knob,99)

	local fsp = Spring.new(300,20)
	fsp.p = t0
	fsp.t = t0

	local rid = Fx(function(dt)
		if not hold or not hold.Parent then
			KFx(rid)
			return
		end
		local v = fsp:step(dt)
		fill.Size = UDim2.fromScale(v,1)
		knob.Position = UDim2.new(v,0,.5,0)
	end)

	local dragging = false
	local function setFromX(x, fire)
		local t = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X,1), 0, 1)
		local value = math.round(mn + t * (mx - mn))
		cur = value
		fsp.t = t
		valL.Text = tostring(cur)
		if fire ~= false then
			fn(cur)
		end
	end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			setFromX(i.Position.X, true)
		end
	end)

	local c1 = UIS.InputChanged:Connect(function(i)
		if not dragging or i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		setFromX(i.Position.X, true)
	end)

	local c2 = UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	hold.Destroying:Connect(function()
		SafeDisconnect(c1)
		SafeDisconnect(c2)
	end)

	return {
		Frame = hold,
		Get = function() return cur end,
		Set = function(_,v)
			v = math.clamp(v, mn, mx)
			cur = v
			local t = (cur-mn)/(mx-mn == 0 and 1 or (mx-mn))
			fsp.t = t
			valL.Text = tostring(cur)
			fn(cur)
		end
	}
end

-- Input
local function MakeInput(parent, cfg)
	cfg = cfg or {}
	local row = New("Frame",{
		Size = UDim2.new(1,0,0,32),
		BackgroundTransparency = 1,
	}, parent)

	if cfg.Label then
		New("TextLabel",{
			Size = UDim2.new(.42,0,1,0),
			BackgroundTransparency = 1,
			Text = cfg.Label,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = C.TextMid,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
	end

	local hold = New("Frame",{
		Size = UDim2.new(.55,0,0,26),
		Position = UDim2.new(.45,0,.5,-13),
		BackgroundColor3 = C.DropBg,
		ClipsDescendants = true,
	}, row)
	Cr(hold,6)
	local st = St(hold,C.Border,1,0.35)

	local box = New("TextBox",{
		Size = UDim2.new(1,-10,1,0),
		Position = UDim2.fromOffset(6,0),
		BackgroundTransparency = 1,
		PlaceholderText = cfg.Placeholder or "",
		PlaceholderColor3 = C.TextDim,
		Text = cfg.Default or "",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.TextBright,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, hold)

	box.Focused:Connect(function()
		local tw = Tw(st,.12,{Color = C.Green, Transparency = 0})
		tw:Play()
	end)

	box.FocusLost:Connect(function(enter)
		local tw = Tw(st,.12,{Color = C.Border, Transparency = 0.35})
		tw:Play()
		if cfg.OnSubmit and enter then
			cfg.OnSubmit(box.Text)
		end
	end)

	return {Frame = row, Box = box}
end

-- Keybind
local function MakeKeybind(parent, cfg)
	cfg = cfg or {}
	local row = New("Frame",{
		Size = UDim2.new(1,0,0,28),
		BackgroundTransparency = 1,
	}, parent)

	New("TextLabel",{
		Size = UDim2.new(1,-50,1,0),
		BackgroundTransparency = 1,
		Text = cfg.Label or "Key",
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextColor3 = C.TextMid,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)

	local badge = New("TextButton",{
		Size = UDim2.fromOffset(44,22),
		Position = UDim2.new(1,-44,.5,-11),
		BackgroundColor3 = C.SideBg,
		Text = cfg.Key or "None",
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = C.Green,
		ZIndex = 10,
	}, row)
	Cr(badge,4)
	St(badge,C.Green,1,0.55)

	local waiting = false
	badge.MouseButton1Click:Connect(function()
		if waiting then return end
		waiting = true
		badge.Text = "..."
		badge.TextColor3 = C.TextDim

		local conn
		conn = UIS.InputBegan:Connect(function(i,gpe)
			if gpe then return end
			if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
			badge.Text = UIS:GetStringForKeyCode(i.KeyCode):upper()
			badge.TextColor3 = C.Green
			SafeDisconnect(conn)
			waiting = false
			if cfg.OnChange then
				cfg.OnChange(i.KeyCode)
			end
		end)
	end)

	return {Frame = row}
end

-- Page factory
local function NewPage(scroll)
	local api = {_scroll = scroll}

	local function SectionLabel(text)
		local f = New("Frame",{
			Size = UDim2.new(1,0,0,30),
			BackgroundTransparency = 1,
		}, scroll)

		New("TextLabel",{
			Size = UDim2.fromScale(1,1),
			BackgroundTransparency = 1,
			Text = text or "",
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			TextColor3 = C.TextBright,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, f)

		New("Frame",{
			Size = UDim2.new(1,0,0,1),
			Position = UDim2.new(0,0,1,-1),
			BackgroundColor3 = C.Border,
			BackgroundTransparency = 0.4,
		}, f)
	end

	function api:Section(text) return SectionLabel(text) end
	function api:Toggle(cfg)   return MakeToggle(scroll,cfg) end
	function api:Dropdown(cfg) return MakeDropdown(scroll,cfg) end
	function api:Button(cfg)   return MakeButton(scroll,cfg) end
	function api:Slider(cfg)   return MakeSlider(scroll,cfg) end
	function api:Input(cfg)    return MakeInput(scroll,cfg) end
	function api:Keybind(cfg)  return MakeKeybind(scroll,cfg) end

	function api:Label(text,col)
		return New("TextLabel",{
			Size = UDim2.new(1,0,0,20),
			BackgroundTransparency = 1,
			Text = text or "",
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = col or C.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, scroll)
	end

	function api:Divider()
		return New("Frame",{
			Size = UDim2.new(1,0,0,1),
			BackgroundColor3 = C.Border,
			BackgroundTransparency = 0.5,
		}, scroll)
	end

	return api
end

-- Main UI module
local UI = {}
UI.__index = UI

function UI.new(cfg)
	cfg = cfg or {}
	local title = cfg.Title or "Hub"
	local version = cfg.Version or "v0.0.1"
	local wm = cfg.Watermark or "by dev"
	local W = cfg.Width or 580
	local H = cfg.Height or 360
	local SIDEBAR_W = 130

	local root = New("CanvasGroup",{
		Name = "NexusWin",
		Size = UDim2.fromOffset(W,H),
		Position = UDim2.new(.5,-W/2,.5,-H/2),
		BackgroundColor3 = C.WinBg,
		GroupTransparency = 1,
		ZIndex = 20,
	}, GUI)
	Cr(root,10)
	St(root,C.Border,1,0.4)

	local topbar = New("Frame",{
		Size = UDim2.new(1,0,0,36),
		BackgroundColor3 = C.SideBg,
		ZIndex = 21,
	}, root)
	Cr(topbar,10)

	New("Frame",{
		Size = UDim2.new(1,0,0,10),
		Position = UDim2.new(0,0,1,-10),
		BackgroundColor3 = C.SideBg,
		ZIndex = 21,
	}, topbar)

	local avCircle = New("Frame",{
		Size = UDim2.fromOffset(22,22),
		Position = UDim2.fromOffset(10,7),
		BackgroundColor3 = C.GreenDim,
		ZIndex = 22,
	}, topbar)
	Cr(avCircle,99)

	New("Frame",{
		Size = UDim2.fromOffset(8,8),
		Position = UDim2.fromOffset(7,7),
		BackgroundColor3 = C.Green,
		ZIndex = 23,
	}, avCircle)

	New("TextLabel",{
		Size = UDim2.fromOffset(120,36),
		Position = UDim2.fromOffset(38,0),
		BackgroundTransparency = 1,
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = C.TextBright,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 22,
	}, topbar)

	local badge = New("Frame",{
		Size = UDim2.fromOffset(46,18),
		Position = UDim2.fromOffset(142,9),
		BackgroundColor3 = C.BadgeBg,
		ZIndex = 22,
	}, topbar)
	Cr(badge,99)

	New("TextLabel",{
		Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1,
		Text = version,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = C.BadgeText,
		ZIndex = 23,
	}, badge)

	New("TextLabel",{
		Size = UDim2.new(1,-210,1,0),
		Position = UDim2.fromOffset(200,0),
		BackgroundTransparency = 1,
		Text = wm,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 22,
	}, topbar)

	local ctrlColors = {C.Err, C.Warn, C.Green}
	for i,col in ipairs(ctrlColors) do
		local dot = New("TextButton",{
			Size = UDim2.fromOffset(10,10),
			Position = UDim2.new(1,-16-(2-i)*16,.5,-5),
			BackgroundColor3 = col,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 23,
		}, topbar)
		Cr(dot,99)

		if i == 1 then
			dot.MouseButton1Click:Connect(function()
				local sp = Spring.new(280,18)
				sp.p = 0
				sp.t = 1
				local eid
				eid = Fx(function(dt)
					if not root or not root.Parent then
						KFx(eid)
						return
					end
					local v = sp:step(dt)
					root.GroupTransparency = 1-v
					if sp:done() then
						KFx(eid)
						pcall(function() root:Destroy() end)
					end
				end)
				sp.t = 0
			end)
		end
	end

	New("Frame",{
		Size = UDim2.new(1,0,0,1),
		Position = UDim2.fromOffset(0,36),
		BackgroundColor3 = C.Border,
		BackgroundTransparency = 0.3,
		ZIndex = 21,
	}, root)

	local sidebar = New("Frame",{
		Size = UDim2.fromOffset(SIDEBAR_W,H-37),
		Position = UDim2.fromOffset(0,37),
		BackgroundColor3 = C.SideBg,
		ZIndex = 21,
	}, root)

	New("Frame",{
		Size = UDim2.new(0,1,1,0),
		Position = UDim2.new(1,-1,0,0),
		BackgroundColor3 = C.Border,
		BackgroundTransparency = 0.3,
		ZIndex = 22,
	}, sidebar)

	local navScroll = New("ScrollingFrame",{
		Size = UDim2.new(1,0,1,-4),
		Position = UDim2.fromOffset(0,4),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.fromScale(0,0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 22,
		BorderSizePixel = 0,
	}, sidebar)
	Pd(navScroll,6,4)
	Ls(navScroll,2)

	local contentHost = New("Frame",{
		Size = UDim2.new(1,-SIDEBAR_W,1,-37),
		Position = UDim2.fromOffset(SIDEBAR_W,37),
		BackgroundColor3 = C.ContentBg,
		ZIndex = 21,
		ClipsDescendants = true,
	}, root)

	local pages = {}
	local navBtns = {}
	local curPage = nil
	local selecting = false
	local destroyed = false

	local win = {
		_root = root,
		_pages = pages,
		_destroyed = false,
	}

	local function SelectPage(name)
		if destroyed or selecting or curPage == name or not pages[name] then return end
		selecting = true
		curPage = name
		CloseAllDropdowns(nil)

		for pname,pdata in pairs(pages) do
			pdata.scroll.Visible = (pname == name)
		end

		for pname,btn in pairs(navBtns) do
			local sel = (pname == name)
			local tw1 = Tw(btn,.14,{BackgroundColor3 = sel and C.SideSel or C.SideBg})
			tw1:Play()

			local lbl = btn:FindFirstChildOfClass("TextLabel")
			if lbl then
				local tw2 = Tw(lbl,.14,{TextColor3 = sel and C.TextBright or C.TextMid})
				tw2:Play()
			end

			local bar = btn:FindFirstChild("_selbar")
			if bar then
				local tw3 = Tw(bar,.14,{BackgroundTransparency = sel and 0 or 1})
				tw3:Play()
			end
		end

		task.delay(.05,function()
			selecting = false
		end)
	end

	function win:Page(name, icon)
		assert(not destroyed, "Window destroyed")
		assert(name, "Page name required")
		if pages[name] then
			return pages[name].api
		end

		local navBtn = New("TextButton",{
			Size = UDim2.new(1,0,0,30),
			BackgroundColor3 = C.SideBg,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 23,
		}, navScroll)
		Cr(navBtn,6)

		local selBar = New("Frame",{
			Name = "_selbar",
			Size = UDim2.new(0,3,0.6,0),
			AnchorPoint = Vector2.new(0,.5),
			Position = UDim2.new(0,0,.5,0),
			BackgroundColor3 = C.Green,
			BackgroundTransparency = 1,
			ZIndex = 24,
		}, navBtn)
		Cr(selBar,2)

		local iconOff = icon and icon ~= "" and 28 or 12
		if icon and icon ~= "" then
			New("ImageLabel",{
				Size = UDim2.fromOffset(16,16),
				Position = UDim2.fromOffset(8,7),
				BackgroundTransparency = 1,
				Image = icon,
				ImageColor3 = C.TextDim,
				ZIndex = 24,
			}, navBtn)
		else
			New("Frame",{
				Size = UDim2.fromOffset(5,5),
				Position = UDim2.fromOffset(10,12),
				BackgroundColor3 = C.TextDim,
				ZIndex = 24,
			}, navBtn)
		end

		New("TextLabel",{
			Size = UDim2.new(1,-iconOff,1,0),
			Position = UDim2.fromOffset(iconOff,0),
			BackgroundTransparency = 1,
			Text = name,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = C.TextMid,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 24,
		}, navBtn)

		navBtn.MouseEnter:Connect(function()
			if curPage ~= name then
				local tw = Tw(navBtn,.1,{BackgroundColor3 = C.SideHov}); tw:Play()
			end
		end)

		navBtn.MouseLeave:Connect(function()
			if curPage ~= name then
				local tw = Tw(navBtn,.1,{BackgroundColor3 = C.SideBg}); tw:Play()
			end
		end)

		navBtn.MouseButton1Click:Connect(function()
			Ripple(navBtn,C.Green)
			SelectPage(name)
		end)

		navBtns[name] = navBtn

		local scroll = New("ScrollingFrame",{
			Size = UDim2.fromScale(1,1),
			BackgroundTransparency = 1,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.Green,
			ScrollBarImageTransparency = 0.4,
			CanvasSize = UDim2.fromScale(0,0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 22,
			BorderSizePixel = 0,
			Visible = false,
		}, contentHost)
		Pd(scroll,14,10)
		Ls(scroll,5)

		local api = NewPage(scroll)
		pages[name] = {scroll = scroll, api = api}

		if not curPage then
			SelectPage(name)
		end

		return api
	end

	function win:SelectPage(name)
		SelectPage(name)
	end

	function win:Notify(t,b,d,c)
		Notify(t,b,d,c)
	end

	function win:Destroy()
		if destroyed then return end
		destroyed = true
		self._destroyed = true
		CloseAllDropdowns(nil)
		if root and root.Parent then
			root:Destroy()
		end
	end

	local openBtn = New("TextButton",{
		Name = "NexusOpenBtn",
		Size = UDim2.fromOffset(110,34),
		Position = UDim2.new(.5,-55,0,8),
		BackgroundColor3 = C.SideBg,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
		Visible = false,
	}, GUI)
	Cr(openBtn,99)
	St(openBtn,C.Border,1,0.3)

	New("UIGradient",{
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,C.Purple),
			ColorSequenceKeypoint.new(1,C.Green),
		}),
		Rotation = 90,
	}, openBtn)

	New("Frame",{
		Size = UDim2.fromOffset(20,20),
		Position = UDim2.fromOffset(8,7),
		BackgroundColor3 = C.GreenDim,
		ZIndex = 51,
	}, openBtn)

	New("TextLabel",{
		Size = UDim2.new(1,-34,1,0),
		Position = UDim2.fromOffset(30,0),
		BackgroundTransparency = 1,
		Text = "Open UI",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.White,
		ZIndex = 51,
	}, openBtn)

	openBtn.MouseButton1Click:Connect(function()
		if destroyed then return end
		root.Visible = true
		openBtn.Visible = false
		root.GroupTransparency = 1
		local tw = Tw(root,.22,{GroupTransparency = 0})
		tw:Play()
	end)

	local animating = true
	do
		local posSp = Spring.new(290,22); posSp.p = -60; posSp.t = 0
		local fadeSp = Spring.new(270,18); fadeSp.p = 1; fadeSp.t = 0
		root.Position = UDim2.new(.5,-W/2,.5,-H/2-60)

		local eid
		eid = Fx(function(dt)
			if destroyed or not root or not root.Parent then
				KFx(eid)
				return
			end
			local dy = posSp:step(dt)
			local tr = fadeSp:step(dt)
			root.Position = UDim2.new(.5,-W/2,.5,-H/2+dy)
			root.GroupTransparency = math.clamp(tr,0,1)
			if posSp:done() and fadeSp:done() then
				root.Position = UDim2.new(.5,-W/2,.5,-H/2)
				root.GroupTransparency = 0
				animating = false
				KFx(eid)
			end
		end)
	end

	Drag(root, topbar, function() return animating end)

	local hotkeyConn
	hotkeyConn = UIS.InputBegan:Connect(function(i)
		if destroyed then
			SafeDisconnect(hotkeyConn)
			return
		end

		if i.KeyCode == Enum.KeyCode.RightShift
			or i.KeyCode == Enum.KeyCode.Insert
			or i.KeyCode == Enum.KeyCode.RightControl then

			root.Visible = not root.Visible
			if root.Visible then
				root.GroupTransparency = 1
				local tw = Tw(root,.2,{GroupTransparency = 0})
				tw:Play()
				openBtn.Visible = false
			else
				openBtn.Visible = true
			end
		end
	end)

	root.Destroying:Connect(function()
		SafeDisconnect(hotkeyConn)
		if openBtn and openBtn.Parent then
			openBtn:Destroy()
		end
	end)

	return win
end

return UI
