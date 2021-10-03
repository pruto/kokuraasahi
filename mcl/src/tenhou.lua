local base64 = require("src.libs.base64")
local utils = require("src.libs.utils")

local savedir = "./save/tenhou/"
local savefile = "save.json"
local rootdata = {}
local matchtimer = 0
local matchlist = {}
local strroomlist = {
    ["97"] = "四特东",
    ["41"] = "四特南",
    ["225"] = "四凤东",
    ["169"] = "四凤南",
    ["57"] = "三特南",
    ["185"] = "三凤南",
}

os.execute("mkdir -p "..savedir)
local fread = io.open(savedir..savefile, "r")
if fread then
    rootdata = Json.parseJson(fread:read("*a"))
    fread:close()
end
rootdata.srcdata = rootdata.srcdata or {}
rootdata.notify = rootdata.notify or {}

Event.subscribe("FriendMessageEvent", function(event)
    handle_message(event.friend, "f"..tostring(event.friend.id), event.message)
end)

Event.subscribe("GroupMessageEvent", function(event)
    handle_message(event.group, "g"..tostring(event.group.id), event.message)
end)

function handle_message(source, srcid, message)
    local msgtable = utils.split(tostring(message))
    local reply = ""
    local needsave = false

    rootdata.srcdata[srcid] = rootdata.srcdata[srcid] or {}
    local srcdata = rootdata.srcdata[srcid]
    local notifydata = rootdata.notify

    if msgtable[1] == "thadd" and #msgtable == 2 then
        srcdata.players = srcdata.players or {}
        if srcdata.players[msgtable[2]] then
            reply = msgtable[2].."已经在关注列表里了"
        else
            srcdata.players[msgtable[2]] = 1
            reply = "嗯！"..msgtable[2].."也得好好监督一下呢"
            needsave = true
        end

    elseif msgtable[1] == "thdel" and #msgtable == 2 then
        srcdata.players = srcdata.players or {}
        if not srcdata.players[msgtable[2]] then
            reply = "没有在关注列表里发现"..msgtable[2]
        else
            srcdata.players[msgtable[2]] = nil
            reply = "不再关注"..msgtable[2].."了"
            needsave = true
        end

    elseif msgtable[1] == "thlist" and #msgtable == 1 then
        local pass = true
        reply = "现在关注了这些天凤ID："

        for k, v in pairs(srcdata.players or {}) do
            pass = false
            reply = reply.."\n"..k
        end
        if pass then
            reply = "现在没有关注任何天凤ID呢"
        end
    elseif msgtable[1] == "thmatch" and #msgtable == 1 then
        local pass = true
        reply = "目前关注的对局有这些："

        update_matchlist()
        for _, rawstr in ipairs(matchlist) do
            local line = utils.split(rawstr, ",")
            local legal = false
            local seat = 0
            local playerstr = tostring((tonumber(utils.split(line[3], ":")[1])+23)%24)..":"..utils.split(line[3], ":")[2].." "
            local matchplayers = {}
            for i=5, #line, 3 do
                table.insert(matchplayers, base64.decode(line[i]))
            end

            for i, player in ipairs(matchplayers) do
                if srcdata.players[player] then
                    legal = true
                    playerstr = playerstr..player.." "
                    seat = i - 1
                end
            end

            if legal then
                pass = false
                reply = reply.."\n"..playerstr.."https://tenhou.net/0/?wg="..line[1]..(seat ~= 0 and "&tw="..seat or "")
            end
        end

        if pass then 
            reply = "目前没有关注的对局哟"
        end

    elseif msgtable[1] == "thnotify" then
        local pass = false

        if #msgtable == 2 then
            if notifydata[srcid] and msgtable[2] == "0" then
                notifydata[srcid] = false
                pass = true
                needsave = true
                reply = "不再通知新的天凤对局了"
            elseif not notifydata[srcid] and msgtable[2] == "1" then
                notifydata[srcid] = true
                pass = true
                needsave = true
                reply = "天凤对局通知任务交给我啦"
            end
        end

        if not pass then
            if notifydata[srcid] then
                reply = "天凤对局通知工作有在好好做呢"
            else
                reply = "天凤对局通知没有开启呢"
            end
        end
    end

    if needsave then
        save_rootdata()
    end

    if reply ~= "" then
        source:sendMessage(reply)
    end
end

thread(function()
    local bot = nil
    local existmatch = {}
    local inited = false
    local delaysecs = 0

    while true do
        for k, v in pairs(Bots) do
            bot = v
        end
        if delaysecs <= 0 then
            delaysecs = 16

            thread(function()
                delaysecs = 60
                local notifydata = rootdata.notify
        
                for k, v in pairs(existmatch) do 
                    existmatch[k] = existmatch[k] - 1
                    if existmatch[k] <= 0 then
                        existmatch[k] = nil
                    end
                end

                update_matchlist()
                for _, rawstr in ipairs(matchlist) do
                    local line = utils.split(rawstr, ",")
                    if inited and not existmatch[line[1]] then
                        local matchplayers = {}
                        for i=5, #line, 3 do
                            table.insert(matchplayers, base64.decode(line[i]))
                        end
                        for srcid, srcdata in pairs(rootdata.srcdata) do
                            local srctype = srcid:sub(1, 1)
                            local srcnum = srcid:sub(2, -1)
                            local source = nil
                            if srctype == "f" then
                                source = bot:getFriend(srcnum)
                            elseif srctype == "g" then
                                source = bot:getGroup(srcnum)
                            end

                            if source and notifydata[srcid] then
                                local players = srcdata.players or {}
                                local legal = false
                                local reply = ""
                                local seat = 0
            
                                for i, player in ipairs(matchplayers) do
                                    if players[player] then
                                        legal = true
                                        reply = reply..player.." "
                                        seat = i - 1
                                    end
                                end
                                if legal then
                                    local strroom = strroomlist[line[4]] or ""
                                    reply = reply.."正在"..strroom.."对局 ".."https://tenhou.net/0/?wg="..line[1]..(seat ~= 0 and "&tw="..seat or "")
                                    source:sendMessage(reply)
                                end
                            end
                        end
                    end
                    existmatch[line[1]] = 30
                end
                
                delaysecs = 16
                inited = true
            end)
        end

        delaysecs = delaysecs - 1
        sleep(1000)
    end
end)

function save_rootdata()
    local fwrite = io.open(savedir..savefile, "w")
    if fwrite then
        fwrite:write(Json.toJson(rootdata))
        fwrite:close()
    end
end

function update_matchlist()
    if os.time() - matchtimer > 20 then
        matchtimer = os.time()
        local body, _ = Http.get("https://mjv.jp/0/wg/0000.js")
        matchlist = Json.parseJson(tostring(body):gsub(".*(%[.+%]).*", [[{"list":%1}]])).list
    end
end
