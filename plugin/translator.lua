local translator = require("translator")

---@param opts vim.api.keyset.create_user_command.command_args
---@param config Translator.Config
local translate_command = function(opts, config)
    local args = vim.split(opts.args, "%s+", { trimempty = true })
    local target_lang = args[1]

    local text
    if #args >= 2 then
        text = table.concat(vim.list_slice(args, 2), " ")
    end

    translator.translate(target_lang, text, config)
end

vim.api.nvim_create_user_command("Translate", function(opts)
    translate_command(opts, { visual_input = opts.range == 2 })
end, { nargs = "+", range = true })

vim.api.nvim_create_user_command("TranslateReplace", function(opts)
    translate_command(opts, { visual_input = opts.range == 2, replace_selection = true })
end, { nargs = "+", range = true })
