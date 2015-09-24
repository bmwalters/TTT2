AddCSLuaFile("sh_init.lua")
include("sh_init.lua")

util.AddNetworkString("TTT2_SetRoundState")
util.AddNetworkString("TTT2_Roles")

function GM:PlayerInitialSpawn(ply)
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

--[[
function GM:CleanUpMap()
	local et = ents.TTT
	-- if we are going to import entities, it's no use replacing HL2DM ones as
	-- soon as they spawn, because they'll be removed anyway
	et.SetReplaceChecking(not et.CanImportEntities(game.GetMap()))

	et.FixParentedPreCleanup()

	game.CleanUpMap()

	et.FixParentedPostCleanup()

	-- Strip players now, so that their weapons are not seen by ReplaceEntities
	for k, v in pairs(player.GetAll()) do
		if IsValid(v) then
			v:StripWeapons()
		end
	end

	-- a different kind of cleanup
	util.SafeRemoveHook("PlayerSay", "ULXMeCheck")
end
--]]
