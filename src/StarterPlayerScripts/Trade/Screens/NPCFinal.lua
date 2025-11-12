-- Ruta: src/StarterPlayerScripts/Trade/Screens/NPCFinal.lua
local Components = require(script.Parent.Parent.Components)
local Final = {}
Final.__index = Final

function Final.new(parent)
	local self = setmetatable({}, Final)
	local modal = Components.MakeModal(parent, "NPCFinal", 0.5, 0.3)
	modal.Visible = false

	local lbl = Components.MakeLabel(
		"¡Oferta enviada!\nSi nos interesa alguno of tus brainrots uno de nosotros te contactará para proponerte algo justo. Si haces trade, debes hacerlo por este sistema"
	)
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.Parent = modal

	local okBtn = Components.MakeButton("Aceptar"); okBtn.Parent = modal

	self.modal = modal
	self.okBtn = okBtn
	return self
end
function Final:Open() self.modal.Visible = true end
function Final:Close() self.modal.Visible = false end
return Final