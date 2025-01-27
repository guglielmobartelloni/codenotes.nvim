local M = {}

-- Default configuration
M.config = {
	notes_dir = vim.fn.expand("~/.local/share/nvim/"),
	use_floating_window = false,
}

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

function M.open_split_window(file_path)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		if name == file_path then
			vim.api.nvim_set_current_win(win)
			return buf
		end
	end

	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.cmd("edit " .. vim.fn.fnameescape(file_path))
	return vim.api.nvim_win_get_buf(win)
end

function M.open_file_in_floating_window(file_path)
	-- Check if the file is already open in a window
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		if name == file_path then
			-- File is already open in this window; focus on it
			vim.api.nvim_set_current_win(win)
			return buf
		end
	end

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
	local win = vim.api.nvim_open_win(buf, true, {
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
			vim.cmd("silent edit " .. vim.fn.fnameescape(file_path))
		end)
	end

	return buf
end

local function get_project_root()
	local cwd = vim.fn.getcwd()
	local util = vim.loop

	local function find_root(dir, marker)
		if util.fs_stat(dir .. "/" .. marker) then
			return dir
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			return nil -- Reached filesystem root
		end
		return find_root(parent, marker)
	end

	-- Look for common project markers
	return find_root(cwd, ".git") or cwd
end

function M.append_to_markdown(lines, file_path, start_line, end_line)
	-- Determine the project root
	local project_root = get_project_root()
	-- Compute the relative path from the project root
	local relative_file_path = vim.fn.fnamemodify(file_path, ":.")

	-- Ensure the path is relative to the project root
	relative_file_path = relative_file_path:gsub("^" .. vim.fn.escape(project_root, "/"), "")

	local current_file = M.get_project_name()

	-- Open or create the notes markdown file
	local markdown_path = M.config.notes_dir .. "" .. current_file .. "_notes.md"
	local current_buf_lang = vim.bo.filetype

	local note_buf = M.config.use_floating_window and M.open_file_in_floating_window(markdown_path)
		or M.open_split_window(markdown_path)

	-- Append the note
	local ref = string.format("- [%s:%d-%d]\n" .. "     ", relative_file_path, start_line, end_line)
	local ref_lines = vim.split(ref, "\n")

	-- Add the reference lines
	vim.api.nvim_buf_set_lines(note_buf, -1, -1, false, ref_lines)

	-- Move the cursor to the end of the `- [%s:%d-%d]` line
	vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(note_buf), #ref_lines[#ref_lines] + 4 })

	-- Add the code block with spaces indentation
	vim.api.nvim_buf_set_lines(note_buf, -1, -1, false, { "    " .. "```" .. current_buf_lang })
	for _, line in ipairs(lines) do
		vim.api.nvim_buf_set_lines(note_buf, -1, -1, false, { "    " .. "    " .. line })
	end
	vim.api.nvim_buf_set_lines(note_buf, -1, -1, false, { "    " .. "```" })
end

-- Main function to handle the workflow
function M.take_note()
	local selection = M.get_selected_lines()
	M.append_to_markdown(selection.lines, selection.file_path, selection.start_line, selection.end_line)
end

-- Setup function to map keys
function M.setup(opts)
	M.config = vim.tbl_extend("force", M.config, opts or {})

	vim.api.nvim_set_keymap(
		"v",
		"<leader>tn",
		[[:lua require('codenotes.core').take_note()<CR>]],
		{ noremap = true, silent = true }
	)
	vim.api.nvim_create_user_command("TakeNote", function()
		require("codenotes.core").take_note()
	end, {
		desc = "Take note of selected text",
		range = true,
	})
end

function M.get_project_root()
	local util = vim.loop
	local cwd = vim.fn.getcwd()

	-- Helper to find a directory with a specific marker
	local function find_root(dir, marker)
		if util.fs_stat(dir .. "/" .. marker) then
			return dir
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			return nil -- Reached filesystem root
		end
		return find_root(parent, marker)
	end

	-- Try to find `.git` or other project markers
	local root = find_root(cwd, ".git")
	if not root then
		-- Fallback to cwd if no marker is found
		root = cwd
	end

	return root
end

-- Get project name from the root directory
function M.get_project_name()
	local project_root = M.get_project_root()
	return vim.fn.fnamemodify(project_root, ":t")
end

return M
