---@class Api
local M = {}

---@param target_lang string Language to translate into
---@param text string Input text to translate
---@param success_callback? fun(translated: string) Callback function with the output
M.translate = function(target_lang, text, success_callback)
    local url = string.format(
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=%s&dt=t&q=%s",
        target_lang,
        vim.uri_encode(text)
    )

    vim.fn.jobstart({ "curl", "-s", "--connect-timeout", "5", "--max-time", "10", url }, {
        stdout_buffered = true,
        on_exit = function(_, code)
            if code ~= 0 then
                vim.notify("translator: failed to curl api (code " .. code .. ")", vim.log.levels.ERROR)
            end
        end,
        on_stdout = function(_, data)
            if not data or data[1] == "" and #data == 1 then
                return
            end
            local ok, decoded = pcall(vim.json.decode, table.concat(data, "\n"))
            if not ok then
                vim.notify("translator: invalid api response", vim.log.levels.ERROR)
                return
            end
            local translated = ""
            for _, sentence in ipairs(decoded[1]) do
                translated = translated .. sentence[1]
            end
            if success_callback then
                success_callback(translated)
            end
        end,
    })
end

return M
