local translator = require("translator")
local ui = require("translator.ui")
local api = require("translator.api")
local helpers = require("spec_helpers")

describe("translator", function()
    before_each(function()
        translator.setup({})
        ui.clear_selection()
    end)

    after_each(function()
        helpers.revert_stubs()
    end)

    describe("setup", function()
        it("applies defaults", function()
            assert.are.same({
                yank_output = true,
                replace_selection = false,
                visual_input = true,
                notify_output = true,
            }, translator.config)
        end)

        it("overrides defaults with user config", function()
            translator.setup({ yank_output = false, notify_output = false })
            assert.is_false(translator.config.yank_output)
            assert.is_false(translator.config.notify_output)
            assert.is_true(translator.config.visual_input)
        end)

        it("raises an error on invalid config", function()
            assert.has_error(function()
                translator.setup({ yank_output = "not-a-boolean" })
            end)
        end)
    end)

    describe("validate_config", function()
        it("returns true for a valid config", function()
            assert.is_true(translator.validate_config(translator.config))
        end)

        it("returns false when a field is not a boolean", function()
            assert.is_false(translator.validate_config({ yank_output = "yes" }))
            assert.is_false(translator.validate_config({ visual_input = 1 }))
        end)
    end)

    describe("translate", function()
        it("calls api with the given input", function()
            local captured = {}
            helpers.stash_stub(ui, "ask_text")
            helpers.stash_stub(ui, "clear_selection")
            helpers.stash_stub(ui, "output")
            helpers.stash_stub(api, "translate", function(_, text, cb)
                captured[#captured + 1] = text
                cb("hello")
            end)

            translator.translate("en", "bonjour")

            assert.are.same({ "bonjour" }, captured)
            assert.spy(api.translate).called(1)
            assert.spy(ui.ask_text).called(0)
        end)

        it("passes the translated text to output", function()
            local translated_text
            helpers.stash_stub(ui, "ask_text")
            helpers.stash_stub(ui, "clear_selection")
            helpers.stash_stub(ui, "output", function(translated)
                translated_text = translated
            end)
            helpers.stash_stub(api, "translate", function(_, _, cb)
                cb("hello")
            end)

            translator.translate("en", "bonjour")

            assert.are.same("hello", translated_text)
            assert.spy(ui.output).called(1)
        end)

        it("asks for input when visual_input is disabled and no input is given", function()
            translator.setup({ visual_input = false })
            helpers.stash_stub(ui, "ask_text")
            helpers.stash_stub(ui, "clear_selection")
            helpers.stash_stub(ui, "output")
            helpers.stash_stub(api, "translate")

            translator.translate("en", nil)

            assert.spy(ui.ask_text).called(1)
            assert.spy(api.translate).called(0)
        end)
    end)
end)
