local argv = { ... }

if #argv ~= 2 and #argv ~= 3 then
    print("Usage: bloodaltar <input> <output> [concurrency]")
end

local Input = string.lower(argv[1])
local Output = string.lower(argv[2])
local Concurrency = tonumber(argv[3]) or 1

local function isInput(data)
    return data ~= nil and string.find(string.lower(data.name), Input) ~= nil
end

local function isOutput(data)
    return data ~= nil and string.find(string.lower(data.name), Output) ~= nil
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
    turtle.suck(1)
    turtle.turnRight()
    -- place the input item in the altar
    select(isInput)
    turtle.drop(Concurrency)
    fillInventory()
    -- now wait for it to be complete
    select(isOutput)
    repeat
        sleep(1)
    until turtle.suck()
end
