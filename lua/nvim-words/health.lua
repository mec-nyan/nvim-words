local heath = vim.health or require("vim.health")

local M = {}

function M.check()
	heath.start("Nvim Words")

	if vim.fn.executable("espeak") == 1 then
		heath.ok("Found 'eSpeak'")
	else
		heath.error("'eSpeak' not found")
	end

	if vim.fn.executable("wn") == 1 then
		heath.ok("Found 'wn' (WordNet CLI)")
	else
		heath.error("'wn' (WordNet CLI) not found")
	end
end

return M
