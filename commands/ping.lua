return {
    name = "ping",
    description = "Ping the bot.",
    options = {},
    cb = function(ia)
        ia:reply("Pong!")
    end
}
