local color_wepbg = Color(0, 0, 0, 240)
local color_purple = Color(200, 0, 200)

function GM:HUDDrawWeaponSwitch()
	local client = LocalPlayer()
	if not client._WeaponMightSwitch then return end

	local scrw, scrh = ScrW(), ScrH()

	local weps = client:GetWeapons()
	local weps_by_slot = {}

	for _, wep in pairs(weps) do
		weps_by_slot[wep:GetSlot() + 1] = wep
	end

	local bpadding = 5
	local tpadding = 40
	local bw, bh = 240, 40
	local bx, by = scrw - 10 - bw, scrh - 10 - (bh * #weps + (#weps - 1) * bpadding)

	for slot, wep in ipairs(weps_by_slot) do
		surface.SetDrawColor(color_wepbg)
		surface.DrawRect(bx, by, bw, bh)

		surface.SetFont("TTT2_HealthAmmo")
		surface.SetTextColor(color_white)
		local text = wep.PrintName or wep:GetClass()
		local tw, th = surface.GetTextSize(text)
		local tx, ty = bx + tpadding, by + ((bh - th) / 2)
		surface.SetTextPos(tx, ty)
		surface.DrawText(text)

		if slot - 1 == client._WeaponMightSwitch then
			surface.SetDrawColor(color_purple)
			surface.DrawRect(bx + 10, by + 10, 20, 20)
		end

		by = by + bh + bpadding
	end
end
