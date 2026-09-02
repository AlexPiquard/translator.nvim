local ui = require("translator.ui")
local helpers = require("spec_helpers")

describe("translator.ui", function()
    before_each(function()
        ui.clear_selection()
    end)

    after_each(function()
        helpers.revert_stubs()
    end)

    describe("output replacement", function()
        local function replace_translated(translated, selection)
            helpers.stash_stub(vim, "schedule", function(fn)
                fn()
            end)
            ui.selection = selection
            ui.output(translated, false, true, false, nil)
            return vim.api.nvim_buf_get_lines(selection.buf, 0, -1, false)
        end

        it("replaces a characterwise visual selection", function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello world" })

            local lines = replace_translated("HELLO", {
                start_pos = { 0, 1, 1, 0 },
                end_pos = { 0, 1, 5, 0 },
                buf = buf,
                mode = "v",
            })

            assert.are.same({ "HELLO world" }, lines)
        end)

        it("replaces a linewise visual selection", function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line one", "line two", "line three" })

            local lines = replace_translated("replaced", {
                start_pos = { 0, 2, 1, 0 },
                end_pos = { 0, 2, 1, 0 },
                buf = buf,
                mode = "V",
            })

            assert.are.same({ "line one", "replaced", "line three" }, lines)
        end)

        it("replaces a multi-line characterwise selection not at line borders", function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello cruel world", "goodbye sweet moon" })

            local lines = replace_translated("RUTHLESS\nCRUEL", {
                start_pos = { 0, 1, 7, 0 },
                end_pos = { 0, 2, 13, 0 },
                buf = buf,
                mode = "v",
            })

            assert.are.same({ "hello RUTHLESS", "CRUEL moon" }, lines)
        end)

        it("replaces a multi-line characterwise selection spanning whole lines", function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "hello cruel world", "goodbye sweet moon" })

            local lines = replace_translated("TRANSLATED ONE\nTRANSLATED TWO", {
                start_pos = { 0, 1, 1, 0 },
                end_pos = { 0, 2, 18, 0 },
                buf = buf,
                mode = "v",
            })

            assert.are.same({ "TRANSLATED ONE", "TRANSLATED TWO" }, lines)
        end)

        it("replaces a multi-line linewise selection with multi-line translated text", function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "line one", "line two", "line three", "line four" })

            local lines = replace_translated("alpha\nbeta", {
                start_pos = { 0, 2, 1, 0 },
                end_pos = { 0, 3, 1, 0 },
                buf = buf,
                mode = "V",
            })

            assert.are.same({ "line one", "alpha", "beta", "line four" }, lines)
        end)
    end)
end)
