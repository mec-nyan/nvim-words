local words = require"nvim-words.words"

local M = {}

M.ShowSound = function() words.show_sounds() end

M.ShowDefinition = function() words.show_definition() end

M.setup = function (opts)
	words.setup(opts)
end


return M
