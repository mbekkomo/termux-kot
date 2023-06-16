local slash_tools = require("discordia-slash").util.tools()

return {
    internal = true,
    owner_only = true,
    name = "eval",
    description = "Evaluate a Lua expression.",
    options = {
        slash_tools.string("exp", "A Lua expression.")
            :setRequired(true),
        slash_tools.boolean("return_exp", "Whether to return a value from Lua expression or not.")
            :setRequired(false)
    },
    ---@diagnostic disable-next-line:unused-local
    cb = function(ia, args, config)
        local ok, exp, err = pcall(function()
            return load((args.return_exp and "return " or "")..args.exp)
        end)
        ia:reply({
            content = exp and ok and not err and exp() or err,
            code = "plain"
        })
    end
}
