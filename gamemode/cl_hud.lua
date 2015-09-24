local color_hudbg = Color(0, 0, 0, 200)
local color_healthbar = Color(200, 50, 50)
local color_healthbarbg = Color(100, 25, 25, 222)
local color_ammobar = Color(205, 155, 0)
local color_ammobarbg = Color(20, 20, 5, 222)

local rolecolors = {
	[ROLE_INNOCENT] = Color(25, 200, 25, 200),
	[ROLE_TRAITOR] = Color(200, 25, 25, 200),
	[ROLE_DETECTIVE] = Color(25, 25, 200, 200),

	[false] = Color(100, 100, 100, 200), -- round isn't active
}

local rolestring = {
	[ROLE_INNOCENT] = "INNOCENT",
	[ROLE_TRAITOR] = "TRAITOR",
	[ROLE_DETECTIVE] = "DETECTIVE",
}

local roundstatestring = {
	[ROUND_WAIT] = "WAITING",
	[ROUND_PREP] = "PREPARING",
	[ROUND_POST] = "ROUND OVER",
}

surface.CreateFont("TTT2_RoleBar", {
	font = "Trebuchet24",
	size = 28,
	weight = 1000,
})

surface.CreateFont("TTT2_TimeLeft", {
	font = "Trebuchet24",
	size = 24,
	weight = 800,
})

surface.CreateFont("TTT2_HealthAmmo", {
	font = "Trebuchet24",
	size = 24,
	weight = 750,
})

-- Returns player's ammo information
local function GetAmmo(ply)
	local wep = ply:GetActiveWeapon()
	if not (IsValid(wep) and ply:Alive()) then return -1 end

	local ammo_inv = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
	local ammo_clip = wep:Clip1() or 0
	local ammo_max = wep.Primary and wep.Primary.ClipSize or wep:GetMaxClip1()

	return ammo_clip, ammo_max, ammo_inv
end

function GM:HUDPaint()
	local scrw, scrh = ScrW(), ScrH()
	local client = LocalPlayer()
	local role = client.Role or false
	local roundstate = self:GetRoundState()

	local scale = scrw / 1920 -- terrible?

	local bgw, bgh = scale * 250, scale * 120
	local bgx, bgy = 20, scrh - bgh - 20

	surface.SetDrawColor(color_hudbg)
	surface.DrawRect(bgx, bgy, bgw, bgh)

	local rolebarw, rolebarh = 170, 30
	surface.SetDrawColor(rolecolors[role])
	surface.DrawRect(bgx, bgy, rolebarw, rolebarh)

	surface.SetTextColor(color_white)

	surface.SetFont("TTT2_TimeLeft")
	local timetext = string.FormattedTime(self.NextRoundState and self.NextRoundState - CurTime() or 0, "%2i:%02i") -- todo
	local timetextw, timetexth = surface.GetTextSize(timetext)
	surface.SetTextPos(bgx + rolebarw + ((bgw - rolebarw) - timetextw) / 2, bgy + (rolebarh - timetexth) / 2)
	surface.DrawText(timetext)

	surface.SetFont("TTT2_RoleBar")
	local roletext = (role and roundstate == ROUND_ACTIVE and client:Team() ~= TEAM_SPECTATOR) and rolestring[role] or roundstatestring[roundstate]
	local roletextw, roletexth = surface.GetTextSize(roletext)
	surface.SetTextPos(bgx + (rolebarw - roletextw) / 2, bgy + (rolebarh - roletexth) / 2)
	surface.DrawText(roletext)

	local habarw, habarh = bgw - 20, 25
	local habarpaddingx, habarpaddingy = (bgw - habarw) / 2, (bgh - rolebarh - (2 * habarh)) / 3
	local habarx = bgx + habarpaddingx

	surface.SetFont("TTT2_HealthAmmo")

	local health_cur, health_max = client:Health(), client:GetMaxHealth()
	local health_ratio = health_cur/health_max

	local hbary = bgy + rolebarh + habarpaddingy
	surface.SetDrawColor(color_healthbarbg)
	surface.DrawRect(habarx, hbary, habarw, habarh)
	surface.SetDrawColor(color_healthbar)
	surface.DrawRect(habarx, hbary, math.floor(habarw * health_ratio), habarh)

	local healthtextw, healthtexth = surface.GetTextSize(health_cur)
	surface.SetTextPos(bgx + bgw - habarpaddingx - 10 - healthtextw, hbary + (habarh - healthtexth) / 2)
	surface.DrawText(health_cur)

	local ammo_clip, ammo_max, ammo_inv = GetAmmo(client)
	local clip_ratio = (ammo_clip ~= -1 and client:GetActiveWeapon().Primary) and ammo_clip/ammo_max or 1

	local abary = hbary + habarh + habarpaddingy
	surface.SetDrawColor(color_ammobarbg)
	surface.DrawRect(habarx, abary, habarw, habarh)
	surface.SetDrawColor(color_ammobar)
	surface.DrawRect(habarx, abary, math.floor(habarw * clip_ratio), habarh)

	if ammo_clip ~= -1 and client:GetActiveWeapon().Primary then
		local ammotext = string.format("%i + %02i", ammo_clip, ammo_inv)
		local ammotextw, ammotexth = surface.GetTextSize(ammotext)
		surface.SetTextPos(bgx + bgw - habarpaddingx - 10 - ammotextw, hbary + habarpaddingy + habarh + (habarh - ammotexth) / 2)
		surface.DrawText(ammotext)
	end
end

local shoulddraw = {
	CHudAmmo = false,
	CHudSecondaryAmmo = false,
	CHudHealth = false,
	CHudBattery = false,
	-- CHudDamageIndicator = false,
}

function GM:HUDShouldDraw(element)
	local sd = shoulddraw[element]
	return sd == nil and true or sd
end
