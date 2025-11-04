local Players = game:GetService("Players")
local Responsive = require(script.Responsive)

local Components = {}

function Components.MakeScreenGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "TradeUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

function Components.MakeModal(parent, name, wScale, hScale)
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(18,18,18)
	f.BackgroundTransparency = 0.05
	f.BorderSizePixel = 0
	f.Visible = false
	Responsive.SizeFromViewport(f, wScale, hScale)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)

	local pad = Instance.new("UIPadding", f)
	pad.PaddingTop = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 14)
	pad.PaddingLeft = UDim.new(0, 16)
	pad.PaddingRight = UDim.new(0, 16)

	local list = Instance.new("UIListLayout", f)
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Top
	list.Padding = UDim.new(0, 10)

	f.Parent = parent
	Responsive.OnViewportResize(function()
		Responsive.SizeFromViewport(f, wScale, hScale)
	end)
	return f
end

function Components.MakeLabel(text, maxSize)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 0)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.TextColor3 = Color3.fromRGB(255,255,255)
	l.Font = Enum.Font.Gotham
	l.TextWrapped = true
	l.RichText = true
	l.TextScaled = true
	l.Text = text or ""
	Responsive.MaxText(l, maxSize or 28)
	return l
end

function Components.MakeButton(text, maxSize)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.Size = UDim2.fromScale(1, 0)
	b.BackgroundColor3 = Color3.fromRGB(35,35,35)
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Font = Enum.Font.GothamMedium
	b.Text = text or "Botón"
	b.TextScaled = true
	b.TextWrapped = true
	Responsive.MaxText(b, maxSize or 26)
	Responsive.AddStroke(b, 1)
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local h = Instance.new("UISizeConstraint", b)
	h.MinSize = Vector2.new(0, 40)
	h.MaxSize = Vector2.new(1e4, 56)
	return b
end

function Components.MakeInput(placeholder, maxSize)
	local tb = Instance.new("TextBox")
	tb.Size = UDim2.fromScale(1, 0)
	tb.AutomaticSize = Enum.AutomaticSize.Y
	tb.BackgroundColor3 = Color3.fromRGB(28,28,28)
	tb.PlaceholderText = placeholder or ""
	tb.ClearTextOnFocus = false
	tb.TextColor3 = Color3.fromRGB(255,255,255)
	tb.Font = Enum.Font.Gotham
	tb.TextWrapped = true
	tb.TextScaled = true
	Responsive.MaxText(tb, maxSize or 26)
	Responsive.AddStroke(tb, 1)
	Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 10)
	local h = Instance.new("UISizeConstraint", tb)
	h.MinSize = Vector2.new(0, 40)
	h.MaxSize = Vector2.new(1e4, 70)
	return tb
end

return Components
