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

return _M
