local Object = require("core").Object

---@param tbl table
---@return table
local function table_copy(tbl)
    local buff = {}
    for k, v in pairs(tbl) do
        buff[k] = v
    end
    return buff
end

---@class Embed : luvit.core.Object
---@operator call(): Embed
local Embed = Object:extend()

---@return Embed
function Embed:initialize()
    self.embed = {}
    return self
end

---@param t string
---@return Embed
function Embed:setType(t)
    self.embed.type = t
    return self
end

---@param title string
---@return Embed
function Embed:setTitle(title)
    self.embed.title = title
    return self
end

---@param desc string
---@return Embed
function Embed:setDescription(desc)
    self.embed.description = desc
    return self
end

---@param url string
---@return Embed
function Embed:setUrl(url)
    self.embed.url = url
    return self
end

---@param iso string
---@return Embed
function Embed:setTimestamp(iso)
    self.embed.timestamp = iso
    return self
end

---@param color integer
---@return Embed
function Embed:setColor(color)
    self.embed.color = color
    return self
end

---@class Embed.Footer
---@field text string
---@field icon_url string
---@field proxy_url string

---@param footer Embed.Footer
---@return Embed
function Embed:setFooter(footer)
    self.embed.footer = table_copy(footer)
    return self
end

---@class Embed.Image
---@field url string
---@field proxy_url string
---@field height integer
---@field weight integer

---@param image Embed.Image
---@return Embed
function Embed:setImage(image)
    self.embed.image = table_copy(image)
    return self
end

---@class Embed.Thumbnail : Embed.Image

---@param thumbnail Embed.Thumbnail
---@return Embed
function Embed:setThumbnail(thumbnail)
    self.embed.thumbnail = table_copy(thumbnail)
    return self
end

---@class Embed.Video : Embed.Image

---@param video Embed.Video
---@return Embed
function Embed:setVideo(video)
    self.embed.video = table_copy(video)
    return self
end

---@class Embed.Provider
---@field name string
---@field url string

---@param provider Embed.Provider
---@return Embed
function Embed:setProvider(provider)
    self.embed.provider = table_copy(provider)
    return self
end

---@class Embed.Author : Embed.Footer
---@field text nil
---@field name string

---@param author Embed.Author
---@return Embed
function Embed:setAuthor(author)
    self.embed.author = author
    return self
end

---@class Embed.Field
---@field name string
---@field value string
---@field inline boolean

---@param field Embed.Field
---@return Embed
function Embed:addField(field)
    self.embed.fields = self.embed.fields or {}
    self.embed.fields[#self.embed.fields+1] = table_copy(field)
    return self
end

---@return table
function Embed:returnEmbed()
    return self.embed
end

return Embed
