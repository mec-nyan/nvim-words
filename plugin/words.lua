function show_word()
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
	local text = { " " .. word .. ": " .. ipa }

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, text)

	local width = #text[1]
	local height = #text

	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)


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

vim.api.nvim_create_user_command("ShowWord", show_word, {})
