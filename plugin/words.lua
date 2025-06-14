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
	bubble_width = 40,
}

local ns_id = vim.api.nvim_create_namespace("WordIPA")

---Make first letter uppercase.
---@param word string
---@return string
local function capitalise(word)
	return (word:gsub("^%l", string.upper))
end

---Wrap text to a specific width.
---Don't break words.
---@param text string
---@return string[]
local function wrap(text)
	local lines = {}
	local line = ""

	for word in text:gmatch("%S+") do
		if #line + #word + 1 <= M.opts.bubble_width then
			if line == "" then
				line = word
			else
				line = line .. " " .. word
			end
		else
			table.insert(lines, line)
			line = word
		end
	end

	if line ~= "" then
		table.insert(lines, line)
	end

	return lines
end

---Get the IPA symbols for the word.
---@param word string
---@return string
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

---Get the definition of a word.
---@param word string
---@return string
local function get_definition(word)
	local handle = io.popen("wn " .. word .. " -over")
	if handle == nil then
		return "(error getting definition)"
	end
	local definition = handle:read("*a")
	handle:close()
	return definition
end

---Get the short (first) definition of a word.
---@param definition string
---@return string
local function short_definition(definition)
	for line in definition:gmatch("[^\r\n]+") do
		local short_def = line:match("^%s*%d+.%s*%(?%d*%)?%s*.*%s*%-%-%s*%((.-)%)")
		if short_def ~= nil then
			return short_def
		end
	end
	return "(not found)"
end


-- TODO: Get selection, senteces, paragraphs, etc.

---Get the word under the cursor.
---Also return the offset from the cursor position to where the word starts.
---@return string word, number offset
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

---Display the word and it's pronunciation (IPA).
---@param word string
---@param offset number
---@param text string
local function display_IPA(word, offset, text)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

	local keyword_hl = vim.api.nvim_get_hl(0, { name = "Function" })
	vim.api.nvim_set_hl(0, "WordIPAItalic", { fg = keyword_hl.fg, italic = true })
	vim.api.nvim_buf_set_extmark(buf, ns_id, 0, 0, {
		end_col = #word + 2,
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

---Display a word, its pronunciation and its meaning.
---@param word string
---@param offset number
---@param lines string[]
local function display_full(word, offset, lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	local keyword_hl = vim.api.nvim_get_hl(0, { name = "Function" })
	vim.api.nvim_set_hl(0, "WordIPAItalic", { fg = keyword_hl.fg, italic = true })
	vim.api.nvim_buf_set_extmark(buf, ns_id, 0, 0, {
		end_col = #word,
		hl_group = "WordIPAItalic"
	})

	-- Sometimes the output can be shorter.
	local width = 0
	for _, line in ipairs(lines) do
		local w = vim.fn.strdisplaywidth(line)
		if w > width then
			width = w
		end
	end

	local height = #lines

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

---Show the sounds (IPA) of the word under the cursor.
function M.show_sounds()
	-- Get the word and the offset (the cursor may be in any part of the word).
	local word, offset = get_word()

	-- Get the IPA representation of the sounds.
	local ipa = get_IPA(word)

	-- Format the output.
	word = capitalise(word)

	local text = " " .. word .. ": 󰕾  " .. ipa .. " "

	-- Display the content in a floating window.
	display_IPA(word, offset, text)
end

---Show the sounds (IPA) and the definition of the word under the cursor.
function M.show_definition()
	local word, offset = get_word()

	local def = get_definition(word)
	def = short_definition(def)

	local ipa = get_IPA(word)

	word = capitalise(word)
	def = capitalise(def)

	def = word .. "  󰕾  (" .. ipa .. "): " .. def
	local lines = wrap(def)

	display_full(word, offset, lines)
end

---Setup this plugin options, if desired.
---Otherwise, default options will be used.
---@param opts table
function M.setup(opts)
	opts = opts or {}
	if opts.border ~= nil then
		M.opts.border = opts.border
	end
end

return M
