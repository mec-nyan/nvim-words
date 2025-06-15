local words = require"nvim-words"

vim.api.nvim_create_user_command("ShowWordSound", words.ShowSound, {})
vim.api.nvim_create_user_command("ShowWordDef", words.ShowDefinition, {})
