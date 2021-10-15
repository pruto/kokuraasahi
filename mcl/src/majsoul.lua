local utils = require("src.libs.utils")

local strranklist = {
    {"初心1", 20}, {"初心2", 80}, {"初心3", 200},
    {"雀士1", 600}, {"雀士2", 800}, {"雀士3", 1000},
    {"雀杰1", 1200}, {"雀杰2", 1400}, {"雀杰3", 2000},
    {"雀豪1", 2800}, {"雀豪2", 3200}, {"雀豪3", 3600},
    {"雀圣1", 4500}, {"雀圣2", 6000}, {"雀圣3", 9000},
}
for i=1, 99 do
    table.insert(strranklist, {"魂天"..i, 2000})
end

Event.subscribe("FriendMessageEvent", function(event)
    handle_message(event.friend, event.message)
end)

Event.subscribe("GroupMessageEvent", function(event)
    handle_message(event.group, event.message)
end)

function handle_message(source, message)
    local msgtable = utils.split(tostring(message))
	local reply = ""

    if msgtable[1] == "mspt" and #msgtable == 2 then
    	local empty = true
        reply = msgtable[2]..":"

        for _, args in ipairs({
            {strmode="四麻", url="https://ak-data-2.sapk.ch/api/v2/pl4/search_player/"..utils.urlencode(msgtable[2]).."?limit=20"},
            {strmode="三麻", url="https://ak-data-2.sapk.ch/api/v2/pl3/search_player/"..utils.urlencode(msgtable[2]).."?limit=20"},
            }) do
            local url = args.url
            local strmode = args.strmode

            local body, _ = Http.get(url)
            local plrlist = Json.parseJson(tostring(body):gsub(".*(%[.*%]).*", [[{"list":%1}]])).list
            for _, plr in pairs(plrlist) do
            	if plr.nickname == msgtable[2] then
            		empty = false

            		local rank = 3*(math.floor(plr.level.id/100)%100 - 1) + plr.level.id%100
                    rank = rank >18 and (rank - 3) or rank
            		local pt = plr.level.score + plr.level.delta
                    if pt < 0 then
                        if rank <= 4 then
                            pt = 0
                        else
                            rank = rank - 1
                            pt = .5 * strranklist[rank][2]
                        end
                    elseif pt >= strranklist[rank][2] then
                        rank = rank + 1
                        pt = .5 * strranklist[rank][2]
                    end

                    local strrank = strranklist[rank][1] or "未知"
                    local strpt = rank < 16 and tostring(pt) or string.format("%.1f", pt/100)
                    local strmax = rank < 16 and tostring(strranklist[rank][2]) or string.format("%.1f", strranklist[rank][2]/100)
            		reply = reply.."\n"..strmode.." "..strrank.." ("..strpt.."/"..strmax..")"
            	end
            end
        end

        if empty then
        	reply = "没有发现玩家"..msgtable[2]
        end
    end

    if reply ~= "" then
	    source:sendMessage(reply)
	end
end
