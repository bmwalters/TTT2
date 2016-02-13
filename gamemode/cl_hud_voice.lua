-- Player voice chat panel, modified from base gamemode
local PANEL = {}
local PlayerVoicePanels = setmetatable({}, {__mode = "k"})

function PANEL:Init()
	self.LabelName = vgui.Create("DLabel", self)
	self.LabelName:SetFont("GModNotify")
	self.LabelName:Dock(FILL)
	self.LabelName:DockMargin(8, 0, 0, 0)
	self.LabelName:SetTextColor(color_white)

	self.Avatar = vgui.Create("AvatarImage", self)
	self.Avatar:Dock(LEFT)
	self.Avatar:SetSize(32, 32)

	self:SetSize(250, 32 + 8)
	self:DockPadding(4, 4, 4, 4)
	self:DockMargin(2, 2, 2, 2)
	self:Dock(BOTTOM)
end

function PANEL:Setup(ply)
	self.ply = ply
	self.LabelName:SetText(ply:Nick())
	self.Avatar:SetPlayer(ply)

	self.color = GAMEMODE:GetRoleColor(ply.Role) or color_black

	self:InvalidateLayout()
end

function PANEL:Paint(w, h)
	if not IsValid(self.ply) then return end

	surface.SetDrawColor(self.color)

	surface.DrawRect(0, 0, w, h)
end

function PANEL:Think()
	if IsValid(self.ply) then
		self.LabelName:SetText(self.ply:Nick())
	end

	if self.fadeAnim then
		self.fadeAnim:Run()
	end
end

function PANEL:FadeOut(anim, delta)
	if anim.Finished then
		if IsValid(PlayerVoicePanels[self.ply]) then
			PlayerVoicePanels[self.ply]:Remove()
			PlayerVoicePanels[self.ply] = nil
			return
		end

		return
	end

	self:SetAlpha(255 - (255 * delta))
end

vgui.Register("VoiceNotify", PANEL, "DPanel")

-- Hooks
function GM:PlayerStartVoice(ply)
	if not IsValid(self.VoicePanelList) then return end

	if IsValid(PlayerVoicePanels[ply]) then
		if PlayerVoicePanels[ply].fadeAnim then
			PlayerVoicePanels[ply].fadeAnim:Stop()
			PlayerVoicePanels[ply].fadeAnim = nil
		end

		PlayerVoicePanels[ply]:SetAlpha(255)

		return
	end

	if not IsValid(ply) then return end

	local entry = vgui.Create("VoiceNotify", self.VoicePanelList)
	entry:Setup(ply)

	PlayerVoicePanels[ply] = entry
end

function GM:PlayerEndVoice(ply)
	if IsValid(PlayerVoicePanels[ply]) then
		if PlayerVoicePanels[ply].fadeAnim then return end

		PlayerVoicePanels[ply].fadeAnim = Derma_Anim("FadeOut", PlayerVoicePanels[ply], PlayerVoicePanels[ply].FadeOut)
		PlayerVoicePanels[ply].fadeAnim:Start(0.5)
	end
end

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "TTT2_PlayerStopVoice", function(data)
	local ply = player.GetByID(data.userid)
	if ply then -- might fail IsValid because they are disconnected?
		hook.Run("PlayerEndVoice", ply)
	end
end)

hook.Add("InitPostEntity", "TTT2_CreateVoiceVGUI", function()
	local list = vgui.Create("DPanel")
	list:ParentToHUD()
	list:SetPos(300, 200)
	list:SetSize(250, ScrH() - 200)
	list:SetPaintBackground(false)

	GAMEMODE.VoicePanelList = list
end)
