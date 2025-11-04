local Responsive = require(script.Responsive)

local Toast = {}
Toast.__index = Toast

function Toast.new(parent)
	local self = setmetatable({}, Toast)

	local frame = Instance.new("Frame")
	frame.Name = "Toast"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0.05)
	frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
	frame.BackgroundTransparency = 0.05
	frame.Visible = false
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local pad = Instance.new("UIPadding", frame)
	pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,8)
	pad.PaddingLeft = UDim.new(0,12); pad.PaddingRight = UDim.new(0,12)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.Font = Enum.Font.Gotham
	lbl.TextScaled = true
	lbl.TextWrapped = true
	lbl.Size = UDim2.fromScale(1,1)
	lbl.Parent = frame
	local tsize = Instance.new("UITextSizeConstraint", lbl)
	tsize.MaxTextSize = 24

	local function resize()
		local vp = workspace.CurrentCamera.ViewportSize
		local w = math.clamp(vp.X * 0.4, 220, 520)
		frame.Size = UDim2.fromOffset(w, 48)
	end
	resize()
	Responsive.OnViewportResize(resize)

	self.frame = frame
	self.lbl = lbl
	return self
end

function Toast:Show(text, duration)
	self.lbl.Text = text
	self.frame.Visible = true
	task.delay(duration or 1.4, function()
		if self.lbl.Text == text then
			self.frame.Visible = false
		end
	end)
end

return Toast
