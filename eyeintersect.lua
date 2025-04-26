local argv = { ... }
if #argv ~= 8 then
    error("Usage: <x1> <z1> <x2> <z2> <x3> <z3> <x4> <z4>")
end

local function parse(x)
    x = tonumber(x)
    if not x then error("failed to parse numbers") end
    return x
end

for i = 1,#argv do
    argv[i] = parse(argv[i])
end

local x1, z1, x2, z2, x3, z3, x4, z4 = table.unpack(argv)

local denom = (x1 - x2) * (z3 - z4) - (z1 - z2) * (x3 - x4)
if denom == 0 then
    print("lines are parallel")
    return
end

local x = (x1 * z2 - z1 * x2) * (x3 - x4) - (x1 - x2) * (x3 - z4 * z3 * x4)
x = x / denom

local z = (x1 * z2 - z1 * x2) * (z3 - z4) - (z1 - z2) * (x3 * z4 - z3 * x4)
z = z / denom

print(string.format("Intersection at x=%f z=%f", x, z))
