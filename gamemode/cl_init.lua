include("sh_init.lua")

net.Receive("TTT2_SetRoundState", function(len)
	local state = net.ReadUInt(3)

	hook.Run("TTT2_RoundStateChanged", GAMEMODE.RoundState, state)

	GAMEMODE.RoundState = state

	if state == ROUND_PREP then
		GAMEMODE:RoundPrep()
	elseif state == ROUND_ACTIVE then
		GAMEMODE:RoundStart()
	elseif state == ROUND_POST then
		GAMEMODE:RoundEnd()
	end
end)

net.Receive("TTT2_Roles", function(len)
	local cnt = net.ReadUInt(6)

	for i = 1, cnt do
		local ply = net.ReadEntity()
		ply.Role = net.ReadUInt(3)
	end
end)

concommand.Remove("undo")
concommand.Remove("gmod_undo")
concommand.Add("undo", print) -- drop ammo
concommand.Add("gmod_undo", print) -- drop ammo

-- This weapon switching stuff is handled in sh_init.lua
local hud_fastswitch = GetConVar("hud_fastswitch")

function GM:Think()
	local client = LocalPlayer()
	if client._WeaponMightSwitchTime and client._WeaponMightSwitchTime + 2 <= CurTime() then
		client._WeaponMightSwitchTime = nil
		client._WeaponMightSwitch = nil
	end
end

function GM:PlayerBindPress(ply, bind, pressed)
	if ply ~= LocalPlayer() then return end -- according to wiki this shouldn't happen anyway
	if not (bind == "invprev" or bind == "invnext" or string.match(bind, "^slot(%d+)$") or ply._WeaponMightSwitch) then return end

	local oldslot = ply._WeaponMightSwitch or ply:GetActiveWeapon():GetSlot()
	local newslot = oldslot

	local slottowep = {}

	local highestslot = oldslot
	for _, wep in pairs(ply:GetWeapons()) do
		slottowep[wep:GetSlot()] = wep
		if wep:GetSlot() > highestslot then
			highestslot = wep:GetSlot()
		end
	end

	if ply._WeaponMightSwitch and bind == "+attack" and pressed then
		ply._WeaponBeforeSwitch = ply:GetActiveWeapon()
		ply._WeaponToSwitch = slottowep[ply._WeaponMightSwitch]
		ply._WeaponMightSwitch = nil
		ply._WeaponMightSwitchTime = nil
		return
	end

	if bind == "invprev" then
		newslot = oldslot - 1
		if newslot < 0 then
			newslot = highestslot
		end
		while not slottowep[newslot] do
			newslot = newslot - 1
			if newslot < 0 then return end
		end
	elseif bind == "invnext" then
		newslot = oldslot + 1
		if newslot > highestslot then
			newslot = 0
		end
		while not slottowep[newslot] do
			newslot = newslot + 1
			if newslot > highestslot then return end
		end
	else
		local slot = string.match(bind, "^slot(%d+)$")
		if not slot then return end
		newslot = slot - 1
		if not slottowep[newslot] then return end
	end

	if newslot == oldslot then return end

	if hud_fastswitch:GetBool() then
		ply._WeaponBeforeSwitch = ply:GetActiveWeapon()
		ply._WeaponToSwitch = slottowep[newslot]
	else
		ply._WeaponMightSwitchTime = CurTime()
		ply._WeaponMightSwitch = newslot
	end
end
