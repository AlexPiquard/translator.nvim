---@class Ui
local M = {}

---@type {start_pos: [integer, integer, integer, integer], end_pos: [integer, integer, integer, integer], buf: integer, mode: string, indent: string}|nil
M.selection = nil

M.select_visual_text = function()
    local mode = vim.fn.visualmode()
    if mode == "" or mode == "\22" then
        return
    end
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local buf = vim.api.nvim_get_current_buf()
    local line_idx = end_pos[2] - 1
    local lines = vim.api.nvim_buf_get_lines(buf, line_idx, line_idx + 1, false)

    if #lines > 0 then
        local current_line = lines[1]
        local max_col = vim.fn.strchars(current_line)

        if mode == "v" and end_pos[3] > max_col then
            end_pos[3] = math.max(1, max_col)
        end
    end

    local ok, selected = pcall(function()
        return table.concat(vim.fn.getregion(start_pos, end_pos, { type = mode }), "\n")
    end)
    if not ok or not selected or #selected < 3 then
        return
    end
    M.selection = {
        start_pos = start_pos,
        end_pos = end_pos,
        buf = buf,
        mode = mode,
        indent = selected:match("^%s*"),
    }
    return selected
end

M.clear_selection = function()
    M.selection = nil
end

---@param callback fun(input: string) Callback function with the input
M.ask_text = function(callback)
    vim.ui.input({ prompt = "Text to translate: " }, function(input)
        if input and input ~= "" then
            callback(input)
        end
    end)
end

---@param translated string The translated text to show
---@param yank boolean Whether to yank the result into the registers
---@param replace boolean Whether to replace the selected input text with the translation
---@param notify boolean Whether to print the translated text as a notification
---@param callback fun()? Callback function
M.output = function(translated, yank, replace, notify, callback)
    vim.schedule(function()
        if yank then
            vim.fn.setreg('"', translated)
            vim.fn.setreg("+", translated)
            vim.fn.setreg("*", translated)
        end

        local s = M.selection
        if replace and s then
            local lines = vim.split(s.indent .. translated, "\n", { plain = true })
            local err
            if s.mode == "V" then
                _, err = pcall(vim.api.nvim_buf_set_lines, s.buf, s.start_pos[2] - 1, s.end_pos[2], false, lines)
            elseif s.mode == "v" then
                _, err = pcall(
                    vim.api.nvim_buf_set_text,
                    s.buf,
                    s.start_pos[2] - 1,
                    s.start_pos[3] - 1,
                    s.end_pos[2] - 1,
                    s.end_pos[3],
                    lines
                )
            end
            if err and type(err) == "string" then
                vim.notify("Translator: Failed to paste translated text in selection: " .. err, vim.log.levels.ERROR)
            end
        end

        if notify then
            vim.notify(translated, vim.log.levels.INFO)
        end

        if callback then
            callback()
        end
    end)
end

return M
