local M = {}

M.opts = {
	border = "single",
	-- TODO: implement the following options.
	padding = {
		top = 1,
		right = 2,
		bottom = 1,
		left = 2,
	},
	position = "below", -- or "above"
	play_sound = false,
	language = "EN_UK",
	show_IPA = true,
	show_definitions = true,
	offline = true,
}

local ns_id = vim.api.nvim_create_namespace("WordIPA")

local function capitalise(word)
	return (word:gsub("^%l", string.upper))
end

local function get_IPA(word)
	-- Get the pronunciation using `espeak`.
	local handle = io.popen("espeak-ng -q --ipa " .. word)
	if handle == nil then
		return "(error getting IPA)"
	end
	local ipa = handle:read("*a")
	handle:close()

	return ipa:gsub("^%s+", ""):gsub("%s+$", "")
end

local function get_definition(word)
	local handle = io.popen("wn " .. word .. " -over")
	if handle == nil then
		return "(error getting definition)"
	end
	local definition = handle:read("*a")
	handle:close()
	return definition
end

---@param definition string
local function short_definition(definition)
	for line in definition:gmatch("[^\r\n]+") do
		local short_def = line:match("^%s*%d+.%s*%(?%d*%)?%s*(.*)%s*%-%-")
		if short_def ~= nil then
			return short_def
		end
	end
	return "(not found)"
end


-- TODO: Get selection, senteces, paragraphs, etc.
local function get_word()
	local _, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()

	-- Find the boundaries of the word.
	-- TODO: I think there's some other way built in vim itself...
	local start_col = col
	local end_col = col

	while start_col > 0 and line:sub(start_col, start_col):match("%w") do
		start_col = start_col - 1
	end

	while end_col <= #line and line:sub(end_col + 1, end_col + 1):match("%w") do
		end_col = end_col + 1
	end

	-- Get the word.
	local word = line:sub(start_col + 1, end_col)

	local offset = (col - start_col + 1) * -1
	return word, offset
end

local ns_id = vim.api.nvim_create_namespace("WordIPA")

local function display(word, offset, text)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

	local keyword_hl = vim.api.nvim_get_hl(0, { name = "Function" })
	vim.api.nvim_set_hl(0, "WordIPAItalic", { fg = keyword_hl.fg, italic = true })
	vim.api.nvim_buf_set_extmark(buf, ns_id, 0, 0, {
		end_col = #word + 2, -- Include space and ":".
		hl_group = "WordIPAItalic"
	})

	local width = vim.fn.strdisplaywidth(text)

	-- TODO: We'll have more lines when we include the definition.
	local height = 1

	local opts = {
		style = "minimal",
		relative = "cursor",
		anchor = "NW",
		width = width,
		height = height,
		row = 1,
		col = offset,
		border = M.opts.border,
	}

	local win = vim.api.nvim_open_win(buf, false, opts)

	-- Close the win if we move the cursor.
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertEnter" }, {
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end,
		once = true,
	})
end

function M.show_sounds()
	-- Get the word and the offset (the cursor may be in any part of the word).
	local word, offset = get_word()

	-- Get the IPA representation of the sounds.
	local ipa = get_IPA(word)

	-- Format the output.
	word = capitalise(word)

	local text = " " .. word .. ": 󰕾  " .. ipa .. " "

	-- Display the content in a floating window.
	display(word, offset, text)
end

function M.show_definition()
	local word, offset = get_word()

	local def = get_definition(word)
	def = short_definition(def)

	vim.cmd.echo(string.format("'%s'", def))
end

function M.setup(opts)
	opts = opts or {}
	if opts.border ~= nil then
		M.opts.border = opts.border
	end
end

return M
