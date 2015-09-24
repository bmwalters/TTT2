GM.Name = "TTT2"
GM.Author = "Zerf & Bad King"

local function inc(f)
	local realm = string.sub(f, 1, 2)
	if realm == "sh" then
		if SERVER then AddCSLuaFile(f) end
		include(f)
	elseif realm == "sv" then
		if SERVER then include(f) end
	elseif realm == "cl" then
		if SERVER then AddCSLuaFile(f) end
		if CLIENT then include(f) end
	end
end

inc("sh_enums.lua")
inc("sh_message.lua")
inc("cl_hud.lua")

team.SetUp(TEAM_TTT2, "TTT2 Player", color_white)

GM.RoundStateProgression = {
	[ROUND_PREP] = ROUND_ACTIVE,
	[ROUND_ACTIVE] = ROUND_POST,
	[ROUND_POST] = ROUND_PREP,
}

function GM:GetGameDescription()
	return self.Name
end

function GM:Think()
	if self.NextRoundState and self.NextRoundState <= CurTime() then
		if SERVER then
			local newstate = self.RoundStateProgression[self.RoundState]
			self:SetRoundState(newstate)
		end
		self.NextRoundState = nil
	end
end

function GM:Initialize()
	-- Force friendly fire to be enabled.
	RunConsoleCommand("mp_friendlyfire", "1")

	self.RoundState = ROUND_WAIT

	if SERVER then
		self:SetRoundState(ROUND_WAIT)
	end

	-- Check if CS:S is mounted, print warning if it isn't
	if #(file.Find("*", "cstrike")) == 0 then
		print("TTT2 WARNING: CS:S does not appear to be mounted by GMod. This may result in broken models and other problems.")
	end
end

function GM:GetRoundState()
	return self.RoundState
end

function GM:RoundPrep()
	if SERVER then
		-- self:CleanUpMap()
	end

	for k, v in pairs(player.GetAll()) do
		if SERVER then v:StripWeapons() end

		if v:Team() == TEAM_TTT2 and not v:Alive() then
			v:Spawn()
		end

		if SERVER then self:PlayerSpawn(v) end
	end

	self.NextRoundState = CurTime() + 30
	self:ChatMessage(nil, "Round preparing.")
end

function GM:RoundStart()
	if SERVER then
		self:SelectRoles()
		self:SendRoles()
	end

	for k, v in pairs(player.GetAll()) do
		if v:Team() == TEAM_TTT2 and not v:Alive() then
			v:Spawn()
		end

		if SERVER then self:PlayerSpawn(v) end
	end

	self.NextRoundState = CurTime() + (5 * 60)
	self:ChatMessage(nil, "Round active.")
end

function GM:RoundEnd()
	for k, v in pairs(player.GetAll()) do
		v.Role = nil

		if SERVER then
			if v.TTT2_WaitingToPlay == true then
				v:SetTeam(TEAM_TTT2)
			end
		end
	end

	self.NextRoundState = CurTime() + 20
	self:ChatMessage(nil, "Round ended.")
end

local function IsBitSet(bitflag, field)
	return bit.band(bitflag, field) == field
end
local function IsBitUnset(bitflag, field)
	return bit.band(bitflag, field) ~= field
end

function GM:GetAlivePlayers()
	local players = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
			players[#players + 1] = ply
		end
	end
	return players
end

function GM:PlayerTick(ply, mov)
	-- Handle keys/binds
	local keys = mov:GetButtons()
	local keys_last = mov:GetOldButtons()

	ply.IsTeamTalking = IsBitSet(keys, IN_SPEED)

	if SERVER and ply:Team() == TEAM_SPECTATOR then
		local direction
		if IsBitSet(keys, IN_ATTACK) and IsBitUnset(keys_last, IN_ATTACK) then
			direction = 1 -- next target
		elseif IsBitSet(keys, IN_ATTACK2) and IsBitUnset(keys_last, IN_ATTACK2) then
			direction = -1 -- prev target
		end

		-- change observer target to next
		if direction then
			local players = self:GetAlivePlayers()

			local curtarget = ply:GetObserverTarget()
			if not curtarget:IsPlayer() then curtarget = players[math.random(1, #players)] end

			for i, ply in ipairs(players) do
				if ply == curtarget then
					local newi = i + direction
					if newi < 1 then newi = #players end
					if newi > #players then newi = 0 end

					ply:SpectateEntity(players[newi])

					break
				end
			end
		end
	end
end
