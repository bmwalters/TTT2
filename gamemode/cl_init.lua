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
