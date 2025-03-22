local function createHamiltonianL(length, width)
    if length % 2 == 1 then
        return nil
    end

    turns = {}
    for row = 1,length do
        turns[row] = {}
        local leftCoordinate
        if row == 1 or row == length then
            leftCoordinate = 1
        else
            leftCoordinate = 2
        end
        local leftSideTurn
        if row == 1 or row == length then
            leftSideTurn = "R"
        else
            leftSideTurn = "L"
        end

        turns[row][leftCoordinate] = leftSideTurn
        turns[row][width] = "R"
    end

    return turns
end

local function createHamiltonianW(length, width)
    if width % 2 == 1 then
        return nil
    end

    turns = {}
    for row = 1,length do
        turns[row] = {}
    end
    for col = 1,width do
        local bottomCoordinate
        if col == 1 or col == width then
            bottomCoordinate = 1
        else
            bottomCoordinate = 2
        end
        local bottomSideTurn
        if col == 1 or col == width then
            bottomSideTurn = "R"
        else
            bottomSideTurn = "L"
        end

        turns[bottomSideCoordinate][col] = bottomSideTurn
        turns[length][col] = "R"
    end

    return turns
end

function createHamiltonian(length, width)
    -- construct a Hamiltonian cycle of a grid graph
    if length % 2 == 0 then
        return createHamiltonianL(length, width)
    elseif width % 2 == 0 then
        return createHamiltonianW(length, width)
    else
        return nil
    end
end

function find(item)
    for n = 1,16 do
        local detail = turtle.getItemDetail(n)
        if detail ~= nil and detail.name == item then
            return n
        end
    end
end


function refuelToMin(amount)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" or amount <= fuelLevel then
        return
    end

    local needed = amount - fuelLevel
    while needed > 0 do
        for n = 1,16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                turtle.refuel(1)
                needed = amount - turtle.getFuelLevel()
            end
        end
    end
end


function tolerantMove(direction, n)
    local functions = {
        down=turtle.down,
        up=turtle.up,
        forward=turtle.forward,
        back=turtle.back,
    }
    local f = functions[direction]
    if f == nil then return end
    if n == nil then n = 1 end
    for k = 1,n do
        while not f() do sleep(1) end
    end
end
