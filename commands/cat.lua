local cohttp = require("coro-http")
local json = require("json")

return {
	name = "cat",
	description = "Get random cat image.",
	options = {},
	cb = function(ia)
		local res, body = cohttp.request("GET", "https://api.thecatapi.com/v1/images/search")

		if res.code ~= 200 then
			ia:reply(("Failed to GET: %d %s"):format(res.code, res.reason), true)
			return
		end

		local cat_obj = assert(json.decode(body))
		res, body = cohttp.request("GET", cat_obj[1].url)

		if res.code ~= 200 then
			ia:reply(("Failed to GET: %d %s"):format(res.code, res.reason), true)
		end

		local tmp_jpg = os.tmpname() .. ".jpg"

		local f = assert(io.open(tmp_jpg, "w+b"))
		f:write(body)
		f:close()

		local a_maxwell = ia.guild.emojis:find(function(e)
			return e.name == "Maxwell"
		end)
		ia:reply({
			content = ("Here's your cat image <a:Maxwell:%s>"):format(tostring(a_maxwell.id)),
			file = tmp_jpg,
		})
	end,
}
