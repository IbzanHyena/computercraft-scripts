local argv = { ... }

if #argv ~= 2 and #argv ~= 3 then
    print("Usage: bloodaltar <input> <output> [concurrency]")
end

local Input = argv[1]
local Output = argv[2]
local Concurrency = tonumber[argv[3]] or 1

local function isInput(data)
    return data ~= nil and string.find(data.name, Input) ~= nil
end

local function isOutput(data)
    return data ~= nil and string.find(data.name, Output) ~= nil
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
        if not turtle.getItemCount(i) then
            for j = 1,16 do
                if i ~= j and turtle.getItemCount(j) > 1 then
                    turtle.select(j)
                    turtle.transferTo(i, 1)
                end
            end
        end
    end
end

-- fill the inventory with items to remove any free slots
fillInventory()

while true do
    -- start by placing items in the altar
    select(isInput)
    turtle.drop(Concurrency)
    fillInventory()
    -- now wait for it to be complete
    select(isOutput)
    repeat
        sleep(1)
    until turtle.suck()
end
