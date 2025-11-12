-- Ruta: src/StarterPlayerScripts/Trade/Screens/NPCPrompt2.lua
local Components = require(script.Parent.Parent.Components)
local Prompt2 = {}
Prompt2.__index = Prompt2

function Prompt2.new(parent)
	local self = setmetatable({}, Prompt2)
	local modal = Components.MakeModal(parent, "NPCPrompt2", 0.45, 0.25)
	modal.Visible = false

	local title = Components.MakeLabel("Selecciona qué tienes para nosotros.", 26)
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = modal

	local okBtn = Components.MakeButton("OK")
	okBtn.Parent = modal

	self.modal = modal
	self.okBtn = okBtn
	return self
end
function Prompt2:Open() self.modal.Visible = true end
function Prompt2:Close() self.modal.Visible = false end
return Prompt2