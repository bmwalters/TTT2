local PLAYER = FindMetaTable("Player")

function PLAYER:SelectWeapon(wepclass)
	local wep = ply:GetWeapons()[wepclass]
	if not wep then return end

	ply._WeaponBeforeSwitch = ply:GetActiveWeapon()
	ply._WeaponToSwitch = wep
end

PLAYER.SetActiveWeapon = PLAYER.SelectWeapon -- different behavior, sure, but this function is just better
