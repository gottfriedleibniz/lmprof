function f_callpar(f) f() end
function f1() error("Hello, World!") ; return 0 end
function f2() f1() ; return 0 end
function f3() f2() ; return 0 end
local function profile_something()
    f_callpar(f3)
end

local function start()
    print(pcall(profile_something))
    print("Hello, World!")
end

start()
