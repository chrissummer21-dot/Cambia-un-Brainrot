local camera = workspace.CurrentCamera

local Responsive = {}

function Responsive.Clamp(n, a, b)
	return math.max(a, math.min(b, n))
end

function Responsive.AddStroke(inst, thickness, color, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = color or Color3.fromRGB(0,0,0)
	s.Transparency = transparency or 0.25
	s.Parent = inst
	return s
end

function Responsive.MaxText(inst, max)
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = max or 28
	c.Parent = inst
	return c
end

function Responsive.SizeFromViewport(frame, wScale, hScale, wMin, wMax, hMin, hMax)
	local vp = camera.ViewportSize
	local w = Responsive.Clamp(vp.X * (wScale or 0.42), wMin or 320, wMax or 560)
	local h = Responsive.Clamp(vp.Y * (hScale or 0.42), hMin or 240, hMax or 520)
	frame.Size = UDim2.fromOffset(w, h)
end

function Responsive.OnViewportResize(cb)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(cb)
end

return Responsive
