function show_word()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()

	local start_col = col
	local end_col = col

	while start_col > 0 and line:sub(start_col, start_col):match("%w") do
		start_col = start_col - 1
	end

	while end_col <= #line and line:sub(end_col + 1, end_col + 1):match("%w") do
		end_col = end_col + 1
	end

	local word = line:sub(start_col + 1, end_col)

	local handle = io.popen("espeak-ng  --ipa " .. word)
	local ipa = handle:read("*a")
	handle:close()

	ipa = ipa:gsub("^%s+", ""):gsub("%s+$", "")

	vim.cmd.echo(string.format("'%s: %s'", word, ipa))
end

vim.api.nvim_create_user_command("ShowWord", show_word, {})
