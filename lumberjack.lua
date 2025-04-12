if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

local function isWood(data)
    return data ~= nil and string.find(data.name, "wood") ~= nil
end

local function isNotWood(data)
    return not isWood(data)
end

local function chopTree()
    turtle.dig()
    extraTurtle.tolerantMove("forward")
    local height = 0
    while true do
        local success, data = turtle.inspectUp()
        if not success or not isWood(data) then
            break
        end

        turtle.digUp()
        extraTurtle.refuelToMin(1, isNotWood)
        turtle.tolerantMove("up")
        height = height + 1
    end

    extraTurtle.refuelToMin(height, isNotWood)
    for _ = 1,height do
        turtle.tolerantMove("down")
    end
    turtle.tolerantMove("back")
end

local function returnWood()
    turtle.turnLeft()
    for i = 1,16 do
        if isWood(turtle.getItemDetail(i)) then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.turnRight()
end

local function grabCoal()
    turtle.turnRight()
    for i = 1,16 do
        local data = turtle.getItemDetail(i)
        if data ~= nil and data.name == "minecraft:coal" then
            turtle.select(i)
            turtle.suck(64 - data.count)
            break
        end
    end
    turtle.turnLeft()
end

while true do
    local success, data = turtle.inspect()
    if not success or isNotWood(data) then
        print("No wood yet")
        sleep(5)
        goto continue
    end
    print("Chopping tree")
    chopTree()
    print("Returning wood")
    returnWood()
    print("Grabbing coal")
    grabCoal()
    ::continue::
end
