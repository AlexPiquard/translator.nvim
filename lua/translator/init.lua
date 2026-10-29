local Api = require("translator.api")
local Ui = require("translator.ui")

---@class Translator.Config
---@field yank_output? boolean Whether to yank the result into the registers
---@field replace_selection? boolean Whether to replace the selected input text with the translation
---@field visual_input? boolean Whether to use the visual selection as the input text
---@field notify_output? boolean Whether to print the translated text as a notification
local config = {
    yank_output = true,
    replace_selection = false,
    visual_input = true,
    notify_output = true,
}

---@class Translator
---@field private config Translator.Config
local M = {
    config = config,
}

---@param args Translator.Config?
M.setup = function(args)
    local new_config = vim.tbl_deep_extend("force", M.config, args or {})
    if not M.validate_config(new_config) then
        error("translator: invalid config", 0)
    end
    M.config = new_config
end

---@param cfg Translator.Config
---@return boolean
M.validate_config = function(cfg)
    return pcall(vim.validate, {
        yank_output = { cfg.yank_output, "boolean" },
        replace_selection = { cfg.replace_selection, "boolean" },
        visual_input = { cfg.visual_input, "boolean" },
        notify_output = { cfg.notify_output, "boolean" },
    })
end

---@param ... Translator.Config|nil
---@return Translator.Config
function M.get_config(...)
    local ret = vim.tbl_deep_extend("force", {}, M.config, ... or {})
    ---@cast ret Translator.Config

    return ret
end

---@param target_lang string Language to translate into
---@param input? string The optional input text to translate
---@param cfg Translator.Config? The config overriding the default one for this call
function M.translate(target_lang, input, cfg)
    cfg = M.get_config(cfg)

    Ui.clear_selection()
    if input == nil and cfg.visual_input then
        input = Ui.select_visual_text()
    end

    local function finish(text)
        Api.translate(target_lang, text, function(translated)
            Ui.output(translated, cfg.yank_output, cfg.replace_selection, cfg.notify_output, function()
                Ui.clear_selection()
            end)
        end)
    end

    if input ~= nil then
        finish(input)
    else
        Ui.clear_selection()
        Ui.ask_text(finish)
    end
end

return M
