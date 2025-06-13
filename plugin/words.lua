local ns_id = vim.api.nvim_create_namespace("WordIPA")

local function show_sounds()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
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

	-- Get the pronunciation using `espeak`.
	local handle = io.popen("espeak-ng -q --ipa " .. word)
	local ipa = handle:read("*a")
	handle:close()

	ipa = ipa:gsub("^%s+", ""):gsub("%s+$", "")

	-- Format the output.
	local text = " " .. word .. ": 󰕾  " .. ipa

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { text })

	local keyword_hl = vim.api.nvim_get_hl(0, { name = "Function" })
	vim.api.nvim_set_hl(0, "WordIPAItalic", { fg = keyword_hl.fg, italic = true })
	vim.api.nvim_buf_set_extmark(buf, ns_id, 0, 0, {
		end_col = #word + 2, -- Include space and ":".
		hl_group = "WordIPAItalic"
	})

	-- TODO: Improve the way we calculate the width: some symbols won't return a column count.
	local width = #text
	-- TODO: We'll have more lines when we include the definition.
	local height = 1

	local opts = {
		style = "minimal",
		relative = "cursor",
		anchor = "NW",
		width = width,
		height = height,
		row = 1,
		col = (col - start_col + 1) * -1,
		border = "single",
	}

	local win = vim.api.nvim_open_win(buf, false, opts)

	-- Close the win if we move the cursor.
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end,
		once = true,
	})
end

vim.api.nvim_create_user_command("ShowSounds", show_sounds, {})
