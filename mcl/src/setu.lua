local utils = require("src.libs.utils")

local urllist = {}
local sendcd = {}
local sendcrit = {}

Event.subscribe("FriendMessageEvent", function(event)
    -- handle_message(event.friend, "f"..tostring(event.friend.id), event.message)
end)

Event.subscribe("GroupMessageEvent", function(event)
    handle_message(event.group, "g"..tostring(event.group.id), event.message)
end)

function handle_message(source, srcid, message)
    local msgtable = utils.split(tostring(message))

    if msgtable[1] == "setu" then
        if os.time() - (sendcd[srcid] or 0) > 20 then
            if #urllist then
                sendcd[srcid] = os.time()
                sendcrit[srcid] = nil
                local url = urllist[#urllist]
                urllist[#urllist] = nil
                source:sendMessage(ImageUrl(url, source))
            end
        elseif not sendcrit[srcid] then
            sendcrit[srcid] = true
            source:sendMessage("不可以频繁地涩涩哦")
        end
    end
end

thread(function()
    local bot = nil
    local delaysecs = 0

    while true do
        for k, v in pairs(Bots) do
            bot = v
        end

        if delaysecs <= 0 then
            delaysecs = 20
            thread(function()
                local num = 10 - #urllist
                if num > 0 then
                    local body, _ = Http.get("https://api.lolicon.app/setu/v2?r18=0&size=regular&num="..num)
                    local datajson = Json.parseJson(tostring(body)).data
                    for _, data in pairs(datajson) do
                        table.insert(urllist, data.urls.regular)
                    end
                end
            end)
        end

        delaysecs = delaysecs - 1
        sleep(1 * 1000)
    end
end)
