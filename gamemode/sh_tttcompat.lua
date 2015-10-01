local enabled = false -- disable by default

if not enabled then return end

hook.Add("TTT2_RoundStateChanged", "TTT_Compat", function(old, new)
	if new == ROUND_PREP then
		hook.Run("TTTPrepareRound")
	elseif new == ROUND_ACTIVE then
		hook.Run("TTTBeginRound")
	elseif new == ROUND_POST then
		hook.Run("TTTEndRound", SERVER and winner or nil) -- todo: winner
	end
end)
