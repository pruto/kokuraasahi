local utils = require("src.libs.utils")

Event.subscribe("FriendMessageEvent", function(event)
    handle_message(event.friend, event.message)
end)

Event.subscribe("GroupMessageEvent", function(event)
    handle_message(event.group, event.message)
end)

Event.subscribe("BotMuteEvent", function(event)
    event.group:quit()
end)

function handle_message(source, message)
    local msgtable = utils.split(tostring(message))

    if msgtable[1] == "asahi" then
        source:sendMessage([[
asahi (朝日能帮上什么忙呢)
thadd (关注天凤ID)
thdel (取消关注天凤ID)
thlist (查看关注的天凤ID列表)
thmatch (查看天凤可以瞪的对局)
thnotify 1/0 (开启/关闭对局通知)
setu (没有这个功能)]])
    end
end
