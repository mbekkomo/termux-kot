local child_procc = require("childprocess")
local exec = child_procc.exec

return {
	internal = true,
	name = "exec",
	description = "Execute a shell command (Owner only)",
	cb = function(msg, args, config)
		if not msg.author.id == tostring(config.ownerid) then
			return
		end

		exec(table.concat(args, " "), function(err, stdout, stderr)
			coroutine.wrap(msg.reply)(msg, {
				content = ([[
**STDOUT**
```
%s
```
**STDERR**
```
%s
```]]):format(stdout, stderr),
				reference = {
					message = msg,
					mention = false,
				},
			})
		end)
	end,
}
