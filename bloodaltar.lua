local argv = { ... }

if #argv ~= 2 and #argv ~= 3 then
    print("Usage: bloodaltar <input> <output> [concurrency]")
end

local Input = string.lower(argv[1])
local Output = string.lower(argv[2])
local Concurrency = tonumber(argv[3]) or 1

if Concurrency < 1 or Concurrency > 63 then
    print("concurrency must be in 1..63")
    return
end

local function is(data, needle)
    return data ~= nil and string.find(string.lower(data.name), needle) ~= nil
end

local function isInput(data)
    return is(data, Input)
end

local function isOutput(data)
    return is(data, Output)
end

local function isBloodOrb(data)
    return is(data, "bloodorb")
end

local function select(predicate)
    for i = 1,16 do
        if predicate(turtle.getItemDetail(i)) then
            turtle.select(i)
            return true
        end
    end
    return false
end

local function fillInventory()
    for i = 1,16 do
        if turtle.getItemCount(i) == 0 then
            for j = 1,16 do
                if i ~= j and turtle.getItemCount(j) > 1 then
                    turtle.select(j)
                    turtle.transferTo(i, 1)
                end
            end
        end
    end
end

local function makeSpace()
    for i = 1,16 do
        local iData = turtle.getItemDetail(i)
        if not iData then return end
        if iData and iData.count == 1 then
            for j = 1,16 do
                local jData = turtle.getItemDetail(j)
                if i ~= j and iData.name == jData.name then
                    turtle.select(i)
                    turtle.transferTo(j, 1)
                    return
                end
            end
        end
    end
end

local found = false
for i = 1,16 do
    if isOutput(turtle.getItemDetail(i)) then
        found = true
        break
    end
end
if not found then
    print("no output item found")
    return
end

-- fill the inventory with items to remove any free slots
fillInventory()
for i = 1,16 do
    if turtle.getItemCount(i) == 0 then
        print("could not fill inventory")
        return
    end
end

while true do
    -- start by retrieving an input item
    makeSpace()
    turtle.turnLeft()
    if not turtle.suck(1) then
        print("could not retrieve input item")
        break
    end

    -- drop off any excess output items
    select(isOutput)
    local count = turtle.getItemCount()
    if count > 64 - Concurrency then
        turtle.turnLeft()
        turtle.drop(count - 1)
        turtle.turnRight()
    end

    turtle.turnRight()
    -- place the input item in the altar
    if not select(isInput) then
        print("could not find input item")
        return
    end
    -- wait for redstone input on the right
    while redstone.getInput("right") do
        sleep(0.1)
    end
    turtle.drop(Concurrency)
    fillInventory()
    -- now wait for it to be complete
    select(isOutput)
    repeat
        sleep(0.1)
    until turtle.suck()
end

-- drop off any output items
turtle.turnLeft()
while select(isOutput) do
    turtle.drop()
end
turtle.turnRight()
turtle.turnRight()

if turtle.select(isBloodOrb) then
    turtle.drop()
end
