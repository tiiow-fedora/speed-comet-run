--!strict
-- Small UI construction helpers + palette.

local Theme = {}

Theme.Bg = Color3.fromRGB(18, 20, 42)
Theme.Panel = Color3.fromRGB(28, 31, 64)
Theme.PanelLight = Color3.fromRGB(42, 46, 92)
Theme.Accent = Color3.fromRGB(80, 220, 255)
Theme.Gold = Color3.fromRGB(255, 214, 70)
Theme.Green = Color3.fromRGB(90, 230, 120)
Theme.Red = Color3.fromRGB(255, 85, 100)
Theme.Pink = Color3.fromRGB(255, 90, 220)
Theme.Text = Color3.fromRGB(245, 246, 255)
Theme.Muted = Color3.fromRGB(170, 175, 210)
Theme.Font = Enum.Font.FredokaOne
Theme.BodyFont = Enum.Font.GothamBold

function Theme.new(className: string, props: { [string]: any }, children: { Instance }?): any
	local inst = Instance.new(className)
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = inst
	end
	if props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function Theme.corner(radius: number?): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	return c
end

function Theme.stroke(color: Color3?, thickness: number?, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.new(0, 0, 0)
	s.Thickness = thickness or 2
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

function Theme.textStroke(): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = Color3.new(0, 0, 0)
	s.Thickness = 2
	s.Transparency = 0.3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	return s
end

function Theme.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextColor3 = Theme.Text,
		TextScaled = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	local l = Theme.new("TextLabel", defaults)
	Theme.textStroke().Parent = l
	return l
end

function Theme.button(props: { [string]: any }): TextButton
	local defaults = {
		BackgroundColor3 = Theme.Accent,
		Font = Theme.Font,
		TextColor3 = Theme.Text,
		TextScaled = true,
		AutoButtonColor = true,
	}
	for k, v in props do
		defaults[k] = v
	end
	local b = Theme.new("TextButton", defaults)
	Theme.corner(10).Parent = b
	Theme.stroke(Color3.new(0, 0, 0), 2, 0.4).Parent = b
	Theme.textStroke().Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = b
	return b
end

return Theme
