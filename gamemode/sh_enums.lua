function enum(prefix)
	return function(tab)
		for i, v in ipairs(tab) do
			_G[prefix .. "_" .. v] = i
		end
	end
end

enum "ROUND" {
	"WAIT",
	"PREP",
	"ACTIVE",
	"POST",
}

enum "ROLE" {
	"INNOCENT",
	"TRAITOR",
	"DETECTIVE",
}

TEAM_TTT2 = 42069
