local M = {}

-- Function to get the selected lines and buffer info
function M.get_selected_lines()
	local bufnr = vim.api.nvim_get_current_buf()
	local start_line, _ = unpack(vim.api.nvim_buf_get_mark(bufnr, "<"))
	local end_line, _ = unpack(vim.api.nvim_buf_get_mark(bufnr, ">"))
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
	local file_path = vim.api.nvim_buf_get_name(bufnr)
	return {
		lines = lines,
		file_path = file_path,
		start_line = start_line,
		end_line = end_line,
	}
end

function M.open_file_in_floating_window(file_path)
	-- Check if a buffer with this name already exists
	local existing_buf = vim.fn.bufnr(file_path)
	local buf

	if existing_buf ~= -1 then
		-- Buffer already exists; use it
		buf = existing_buf
	else
		-- Create a new buffer
		buf = vim.api.nvim_create_buf(true, false) -- 'true' makes it a listed buffer
		vim.api.nvim_buf_set_name(buf, file_path)
	end

	-- Define the dimensions of the floating window
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Open the floating window
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "single",
	})

	-- Load the file into the buffer if it's a new buffer
	if existing_buf == -1 then
		vim.api.nvim_buf_call(buf, function()
			vim.cmd("silent edit " .. file_path)
		end)
	end
	return buf
end

-- Function to append notes to a Markdown file
function M.append_to_markdown(lines, file_path, start_line, end_line)
	-- local note_buf = M.create_floating_window()

	-- Open or create the notes markdown file
	local markdown_path = vim.fn.expand("~/.local/share/nvim/notes.md")
	print(markdown_path)
	local note_buf = M.open_file_in_floating_window(markdown_path)

	-- if vim.fn.filereadable(markdown_path) == 1 then
	-- 	vim.api.nvim_buf_call(note_buf, function()
	-- 		vim.cmd("edit " .. markdown_path)
	-- 	end)
	-- else
	-- 	vim.api.nvim_buf_call(note_buf, function()
	-- 		vim.cmd("new " .. markdown_path)
	-- 	end)
	-- end

	-- -- Append the note
	local ref = string.format("- [%s:%d-%d]\n", file_path, start_line, end_line)
	print(ref)
	vim.api.nvim_buf_set_lines(note_buf, -1, -1, false, vim.split(ref, "\n"))
	for _, line in ipairs(lines) do
		vim.api.nvim_buf_set_lines(note_buf, -1, -1, false, { "    " .. line })
	end
end

-- Main function to handle the workflow
function M.take_note()
	local selection = M.get_selected_lines()
	M.append_to_markdown(selection.lines, selection.file_path, selection.start_line, selection.end_line)
end

-- Setup function to map keys
function M.setup()
	vim.api.nvim_set_keymap(
		"v",
		"<leader>tn",
		[[:lua require('note_plugin').take_note()<CR>]],
		{ noremap = true, silent = true }
	)
end

function M.print_table(tbl, indent)
	if type(tbl) ~= "table" then
		print(tostring(tbl))
		return
	end

	indent = indent or 0
	local formatting = string.rep("  ", indent)

	print(formatting .. "{")
	for key, value in pairs(tbl) do
		local display_key = tostring(key)
		if type(value) == "table" then
			print(formatting .. "  " .. display_key .. " = ")
			M.print_table(value, indent + 1)
		else
			print(formatting .. "  " .. display_key .. " = " .. tostring(value))
		end
	end
	print(formatting .. "}")
end

M.take_note()

return M
