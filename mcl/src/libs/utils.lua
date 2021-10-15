local _M = {}

function _M.split(str, sep)
    str = str or ""
    sep = sep or "%s"
    local ret = {}
    for field in str:gmatch("[^"..sep.."]+") do
        ret[#ret+1] = field
    end
    return ret
end

function _M.urlencode(s)
     s = string.gsub(s,"([^%w%.%- ])", function(c) return string.format("%%%02X",string.byte(c)) end)
    return string.gsub(s," ","+")
end
 
function _M.urldecode(s)
    s = string.gsub(s,'%%(%x%x)', function(h) return string.char(tonumber(h,16)) end)
    return s
end

return _M
