local limit = tonumber(arg[1]) or 1
local dlimit = tonumber(arg[2]) or 100

local function d(t)
    if #t == 2 then return end
    for i=1,dlimit do local a = { } end
    t[#t + 1] = math.abs(-1)
    return d(t)
end

function c(t)
    for i=1,limit do local a = { } end
    return d(t)
end

function b(t)
    for i=1,limit do local a = { } end
    return c(t)
end

function a()
    for i=1,limit do local a = { } end
    return b({ })
end

a()
