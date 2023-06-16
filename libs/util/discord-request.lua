local Object = require("core").Object
local cohttp = require("coro-http")
local ext_table = require("discordia").extensions.table

---@class DiscordRequest : luvit.core.Object
---@operator call(): DiscordRequest
local DiscordRequest = Object:extend()

---@param token string
---@param api_v string|integer
---@return DiscordRequest
function DiscordRequest:initialize(token, api_v)
    self.token = token
    self.url = "https://discord.com/api/v"..api_v
    return self
end

---@param request_type string
---@param url_path string
---@param url_param table
---@param url_header coro-http.alias.header[]?
---@param body string?
---@return coro-http.alias.response
---@return string
function DiscordRequest:request(request_type, url_path, url_param, url_header, body)
    local headers = ext_table.copy(url_header or {})
    headers[#headers+1] = { "Authorization", "Bot "..self.token }
    p(headers)
    local params = {}
    for k, v in ipairs(url_param) do
        params[#params+1] = k.."="..v
    end

    return cohttp.request(request_type,("%s%s?%s"):format(self.url, url_path, table.concat(params, "&")), headers, body)
end

return DiscordRequest
