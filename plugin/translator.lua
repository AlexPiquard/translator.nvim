local translator = require("translator")

vim.api.nvim_create_user_command("Translate", function(opts)
  local args = vim.split(opts.args, "%s+", { trimempty = true })
  if #args < 1 then
    vim.notify("Usage: :Translate <target_lang> [text]", vim.log.levels.ERROR)
    return
  end
  local target_lang = args[1]

  local text
  if #args >= 2 then
    text = table.concat(vim.list_slice(args, 2), " ")
  end

  translator.translate(target_lang, text, { visual_input = opts.range == 2 })
end, { nargs = "+", range = true })
