local api = require("translator.api")
local ui = require("translator.ui")

---@class Config
---@field yank_output boolean Whether to yank the result into the registers
---@field replace_selection boolean Whether to replace the selected input text with the translation
---@field visual_input boolean Whether to use the visual selection as the input text
---@field notify_output boolean Whether to print the translated text as a notification
local config = {
    yank_output = true,
    replace_selection = false,
    visual_input = true,
    notify_output = true,
}

---@class (partial) PartialConfig: Config

---@class Translator
local M = {}

---@type Config
M.config = config

---@param args PartialConfig?
M.setup = function(args)
    local new_config = vim.tbl_deep_extend("force", M.config, args or {})
    if not M.validate_config(new_config) then
        error("translator: invalid config", 0)
    end
    M.config = new_config
end

---@param cfg Config
---@return boolean
M.validate_config = function(cfg)
    return pcall(vim.validate, {
        yank_output = { cfg.yank_output, "boolean" },
        replace_selection = { cfg.replace_selection, "boolean" },
        visual_input = { cfg.visual_input, "boolean" },
        notify_output = { cfg.notify_output, "boolean" },
    })
end

---@param target_lang string Language to translate into
---@param input? string The optional input text to translate
---@param cfg PartialConfig ? The config overriding the default one for this call
M.translate = function(target_lang, input, cfg)
    config = vim.tbl_deep_extend("force", M.config, cfg or {})

    ui.clear_selection()
    if input == nil and config.visual_input then
        input = ui.select_visual_text()
    end

    local function finish(text)
        api.translate(target_lang, text, function(translated)
            ui.output(translated, config.yank_output, config.replace_selection, config.notify_output, function()
                ui.clear_selection()
            end)
        end)
    end

    if input ~= nil then
        finish(input)
    else
        ui.clear_selection()
        ui.ask_text(finish)
    end
end

return M
