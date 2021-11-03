local utils = require("src.libs.utils")

local savedir = "./save/setu/"
local urllist = {}
local pathlist = {}
local sendcd = {}
local sendcrit = {}

os.execute("mkdir -p "..savedir)

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
            sendcd[srcid] = os.time()
            if #pathlist > 0 then
                sendcrit[srcid] = nil
                local path = pathlist[#pathlist]
                pathlist[#pathlist] = nil
                source:sendMessage(ImageFile(path, source))
            else
                source:sendMessage("呜呜已经没有了")
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
    local cachecount = 30

    while true do
        for k, v in pairs(Bots) do
            bot = v
        end

        if delaysecs <= 0 then
            delaysecs = 12
            thread(function()
                local num = cachecount - #urllist
                num = num > 10 and 10 or num
                if num > 0 then
                    local body, _ = Http.get("https://api.lolicon.app/setu/v2?r18=0&size=regular&num="..num)
                    local datalist = Json.parseJson(tostring(body)).data
                    for _, datarec in pairs(datalist) do
                        local legal = true
                        for _, tag in pairs(datarec.tags) do
                            if tag == "R-18" then
                                legal = false
                            end
                        end
                        if legal then
                            table.insert(urllist, datarec.urls.regular)
                        end
                    end
                end
            end)
            thread(function()
                local ind = #pathlist + 1
                if ind <= cachecount and #urllist > 0 then
                    local url = urllist[#urllist]
                    urllist[#urllist] = nil
                    local body, _ = Http.get(url)
                    local fwrite = io.open(savedir..ind, "w")
                    if fwrite then
                        fwrite:write(body)
                        fwrite:close()
                        pathlist[ind] = savedir..ind
                    end
                end
            end)
        end

        delaysecs = delaysecs - 1
        sleep(1 * 1000)
    end
end)

