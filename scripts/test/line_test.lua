
function b()
    return string.format("%s", "Hello, Sailor!")
end

function a()
    b()
    b()
    return 0;
end

a()