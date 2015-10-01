AddCSLuaFile("sh_init.lua")
include("sh_init.lua")

util.AddNetworkString("TTT2_SetRoundState")
util.AddNetworkString("TTT2_Roles")

function GM:PlayerInitialSpawn(ply)
	ply:SetCanZoom(false)

	local players = player.GetAll()

	if self:GetRoundState() == ROUND_WAIT and #players >= 2 then
		self:SetRoundState(ROUND_PREP)
	end

	self:SendRoundState(ply)

	if self:GetRoundState() == ROUND_ACTIVE then
		self:SendRoles(ply)
		self:PlayerSpawnAsSpectator(ply)
		ply.TTT2_WaitingToPlay = true
	end
end

function GM:PlayerSetModel(ply)
	ply:SetModel("models/player/odessa.mdl")
	ply:SetColor(color_white)
end

function GM:PlayerLoadout(ply)
	ply:Give("weapon_crowbar")
	ply:Give("weapon_base_z")
end

function GM:PlayerSpawn(ply)
	hook.Run("PlayerLoadout", ply)

	hook.Run("PlayerSetModel", ply)

	if IsValid(ply) and not ply:IsBot() then
		ply:SetupHands()
	end
end

function GM:CanPlayerSuicide()
	return ply:Team() == TEAM_TTT2
end

function GM:SelectRoles()
	local players = {}
	for _, v in pairs(player.GetAll()) do
		if IsValid(v) and v:Team() ~= TEAM_SPECTATOR then
			players[#players + 1] = v
		end
	end

	local plycnt = #players
	local tcnt = math.Clamp(math.floor(plycnt * 0.25), 1, 8) -- keep between 1 and 8 traitors
	local dcnt = math.Clamp(math.floor(plycnt * 0.125), 0, 4) -- keep between 0 and 4 detectives

	for i = 1, tcnt do
		local ply = table.remove(players, math.random(1, #players))
		ply.Role = ROLE_TRAITOR
	end
	for i = 1, dcnt do
		local ply = table.remove(players, math.random(1, #players))
		ply.Role = ROLE_DETECTIVE
	end
	for k, v in pairs(players) do
		v.Role = ROLE_INNOCENT
	end
end

function GM:SendRoles(ply)
	if self:GetRoundState() ~= ROUND_ACTIVE then return end

	local players = {}
	for _, v in pairs(player.GetAll()) do
		if IsValid(v) and v:Team() ~= TEAM_SPECTATOR then
			players[#players + 1] = v
		end
	end

	net.Start("TTT2_Roles")
		net.WriteUInt(#players, 6)
		for k, ply in pairs(players) do
			net.WriteEntity(ply)
			local r = ply.Role
			net.WriteUInt((ply:Team() ~= TEAM_SPECTATOR and ply.Role ~= ROLE_TRAITOR and r == ROLE_TRAITOR) and ROLE_INNOCENT or r, 3) -- hide traitors from innocents
		end
	if ply then net.Send(ply) else net.Broadcast() end
end

function GM:SendRoundState(ply)
	net.Start("TTT2_SetRoundState")
		net.WriteUInt(self.RoundState, 3)
	if ply then net.Send(ply) else net.Broadcast() end
end

function GM:SetRoundState(state)
	local shouldblock = (hook.Run("TTT2_RoundStateChanged", self.RoundState, state) == true)

	if shouldblock then return end

	self.RoundState = state

	self:SendRoundState()

	if state == ROUND_PREP then
		self:RoundPrep()
	elseif state == ROUND_ACTIVE then
		self:RoundStart()
	elseif state == ROUND_POST then
		self:RoundEnd()
	end
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
	local lr, tr = listener.Role, talker.Role

	if talker.IsTeamTalking and tr == ROLE_TRAITOR and lr ~= ROLE_TRAITOR then
		return false
	end

	return true
end

function GM:EntityTakeDamage(ent, dmginfo)
	if not IsValid(ent) then return end
	local att = dmginfo:GetAttacker()

	local isexplosive = (ent:GetKeyValues().ExplodeDamage or 0) > 0

	if self:GetRoundState() == ROUND_PREP then
		if ent:IsPlayer() and IsValid(att) and att:IsPlayer() then
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	elseif isexplosive then
		-- When a barrel hits a player, that player damages the barrel because
		-- Source physics. This gives stupid results like a player who gets hit
		-- with a barrel being blamed for killing himself or even his attacker.
		if IsValid(att) and att:IsPlayer() and dmginfo:IsDamageType(DMG_CRUSH) and IsValid(ent:GetPhysicsAttacker()) then
			dmginfo:SetAttacker(ent:GetPhysicsAttacker())
			dmginfo:ScaleDamage(0)
			dmginfo:SetDamage(0)
		end
	end
end

function GM:IsSpawnpointSuitable(ply, spawnpoint, force)
	if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then return true end
	if not (IsValid(spawnpoint) and spawnpoint:IsInWorld()) then return false end

	local pos = spawnpoint:GetPos()

	local blocking = ents.FindInBox(pos + Vector(-16, -16, 0), pos + Vector(16, 16, 64))

	for _, ply in pairs(blocking) do
		if IsValid(ply) and ply:IsPlayer() and ply:Alive() then
			if force then
				ply:Kill()
			else
				return false
			end
		end
	end

	return true
end

local spawnpointents = {
	info_player_start = true,
	gmod_player_start = true,
	info_player_teamspawn = true,
	info_player_coop = true,

	info_player_red = true,
	info_player_blue = true,

	info_player_deathmatch = true,
	info_player_combine = true,
	info_player_rebel = true,

	info_player_zombiemaster = true,

	info_player_terrorist = true,
	info_player_counterterrorist = true,

	info_player_allies = true,
	info_player_axis = true,

	ins_spawnpoint = true,
	aoc_spawnpoint = true,
	dys_spawn_point = true,

	info_player_pirate = true,
	info_player_viking = true,
	info_player_knight = true,

	diprip_start_team_red = true,
	diprip_start_team_blue = true,

	info_player_human = true,
	info_player_zombie = true,
}

function GM:GetSpawnpointEnts()
	local spawns = {}

	for _, ent in pairs(ents.GetAll()) do
		if spawnpointents[ent:GetClass()] then
			spawns[#spawns + 1] = ent
		end
	end

	return spawns
end

function GM:PlayerSelectSpawn(ply)
	local spawnpoints = self:GetSpawnpointEnts()

	if #spawnpoints == 0 then
		error("No spawnpoint entities found!")
		return
	end

	-- try for a free spawn
	while #spawnpoints > 0 do
		local spawn = table.remove(spawnpoints, math.random(1, #spawnpoints))

		if hook.Run("IsSpawnpointSuitable", ply, spawn, false) then
			return spawn
		end
	end

	local w, h = 36, 72 -- a little larger than player hull
	spawnpoints = self:GetSpawnpointEnts()
	for _, spawn in pairs(spawnpoints) do
		-- try to create a spawn near an existing one
		local pos = spawn:GetPos()

		local poses = {
			pos + Vector( w, 0, 0),
			pos + Vector( 0, w, 0),
			pos + Vector( w, w, 0),
			pos + Vector(-w, 0, 0),
			pos + Vector( 0,-w, 0),
			pos + Vector(-w,-w, 0),
			pos + Vector(-w, w, 0),
			pos + Vector( w,-w, 0),
			-- pos + Vector( 0,  0,  h), -- just in case we're outside
		}

		for _, pos in pairs(poses) do
			local ent = ents.Create("info_player_terrorist")
			ent:SetPos(pos)
			ent:Spawn()

			if not IsValid(ent) then continue end

			if hook.Run("IsSpawnpointSuitable", ply, ent, false) then
				ErrorNoHalt("TTT2 WARNING: Map has too few spawn points, using a rigged spawn for " .. ply:GetName() .. "\n")

				return ent
			else
				ent:Remove()
			end
		end
	end

	return spawnpoints[1] -- players will get stuck; better than killing them all I guess
end

GM.DeathSounds = {
	Sound("player/death1.wav"),
	Sound("player/death2.wav"),
	Sound("player/death3.wav"),
	Sound("player/death4.wav"),
	Sound("player/death5.wav"),
	Sound("player/death6.wav"),
	Sound("vo/npc/male01/pain07.wav"),
	Sound("vo/npc/male01/pain08.wav"),
	Sound("vo/npc/male01/pain09.wav"),
	Sound("vo/npc/male01/pain04.wav"),
	Sound("vo/npc/Barney/ba_pain06.wav"),
	Sound("vo/npc/Barney/ba_pain07.wav"),
	Sound("vo/npc/Barney/ba_pain09.wav"),
	Sound("vo/npc/Barney/ba_ohshit03.wav"), --heh
	Sound("vo/npc/Barney/ba_no01.wav"),
	Sound("vo/npc/male01/no02.wav"),
	Sound("hostage/hpain/hpain1.wav"),
	Sound("hostage/hpain/hpain2.wav"),
	Sound("hostage/hpain/hpain3.wav"),
	Sound("hostage/hpain/hpain4.wav"),
	Sound("hostage/hpain/hpain5.wav"),
	Sound("hostage/hpain/hpain6.wav"),
}

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	if ply:Team() == TEAM_SPECTATOR then return end

	-- Drop all weapons
	for k, wep in pairs(ply:GetWeapons()) do
		if wep.PreDrop then
			wep:PreDrop(true)
		end
		if wep.DampenDrop then
			wep:DampenDrop()
		end
	end

	ply:StripWeapons()

	local wep = dmginfo:GetInflictor()

	-- headshots and weapons tagged as silent prevent death sound from occurring
	if not (ply:LastHitGroup() == HITGROUP_HEAD or (IsValid(killwep) and killwep.IsSilent)) then
		ply:EmitSound(self.DeathSounds[math.random(1, #self.DeathSounds)], 90, 100, 1, CHAN_VOICE)
	end
end

function GM:PlayerDeath(victim, inflictor, attacker)
	self:PlayerSilentDeath(victim)

	victim:SetTeam(TEAM_SPECTATOR)

	local players = self:GetAlivePlayers()
	if #players > 0 then victim:SpectateEntity(players[math.random(1, #players)]) end

	victim:Freeze(false)
	victim:Flashlight(false)
	victim:Extinguish()
end

-- kill hl2 beep
function GM:PlayerDeathSound() return true end

-- GetFallDamage isn't called until around 600 speed, we want to handle even less
function GM:GetFallDamage(ply, speed)
	return 0
end

GM.FallSounds = {
	Sound("player/damage1.wav"),
	Sound("player/damage2.wav"),
	Sound("player/damage3.wav"),
}

function GM:OnPlayerHitGround(ply, inwater, onfloater, speed)
	if inwater or speed < 450 or not IsValid(ply) then return end

	-- everything over a threshold hurts you, rising exponentially with speed
	local damage = math.pow(0.05 * (speed - 420), 1.75)

	if onfloater then damage = damage * 0.5 end

	-- if we fell on a dude, that hurts (him) (a.k.a. goomba stomp)
	local ground = ply:GetGroundEntity()
	if IsValid(ground) and ground:IsPlayer() then
		if math.floor(damage) > 0 then
			local att = ply

			-- if the faller was pushed, that person should get attrib
			--[[
			local push = ply.was_pushed
			if push then
				-- TODO: move push time checking stuff into fn?
				if math.max(push.t or 0, push.hurt or 0) > CurTime() - 4 then
					att = push.att
				end
			end
			--]]

			local dmg = DamageInfo()
			dmg:SetDamageType(DMG_CRUSH)
			dmg:SetAttacker(att)
			dmg:SetInflictor(att)
			dmg:SetDamageForce(Vector(0, 0, -1))
			dmg:SetDamage(damage)

			ground:TakeDamageInfo(dmg)
		end

		-- our own falling damage is cushioned
		damage = damage / 3
	end

	if math.floor(damage) > 0 then
		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_FALL)
		dmg:SetAttacker(game.GetWorld())
		dmg:SetInflictor(game.GetWorld())
		dmg:SetDamageForce(Vector(0, 0, 1))
		dmg:SetDamage(damage)

		ply:TakeDamageInfo(dmg)

		-- play CS:S fall sound if we got somewhat significant damage
		if damage > 5 then
			ply:EmitSound(self.FallSounds[math.random(1, #self.FallSounds)], 55 + math.Clamp(damage, 0, 50))
		end
	end
end