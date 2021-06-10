c1_count = 0
c2_count = 0

c1 = coroutine.create(function()
    while true do
        c1_count = c1_count + 1
        coroutine.yield()
    end
end)

c2 = coroutine.create(function()
    c2_count = c2_count + 1
    coroutine.resume(c1)
    coroutine.yield()
end)

coroutine.resume(c1)
coroutine.resume(c2)

--print(c1_count, c2_count)
