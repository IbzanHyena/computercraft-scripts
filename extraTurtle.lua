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


Turns = {}

function Turns:new(o)
    o = o or {}
    setmetatable(o, self)
    return o
end


function Turns:__index(key)
    if Turns[key] then
        return Turns[key]
    end
    self[key] = {}
    return self[key]
end


function Turns:createZigZag(length, width)
    for j = 1,width do
        self[1][j] = "A"
        self[length][j] = "B"
    end
    self[1][1] = nil
    self[length][width] = nil
end


function Turns:createGHC2(length, width)
    if length ~= 2 or width ~= 2 then
        return false
    end

    self[1][1] = "R"
    self[length][1] = "R"
    self[length][width] = "R"
    self[1][width] = "R"

    return true
end


function Turns:createGHCL(length, width)
    if length % 2 == 1 then
        return false
    end

    for row = 1,length do
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

        self[row][leftCoordinate] = leftSideTurn
        self[row][width] = "R"
    end

    return true
end


function Turns:createGHCW(length, width)
    if width % 2 == 1 then
        return false
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

        self[bottomCoordinate][col] = bottomSideTurn
        self[length][col] = "R"
    end

    return true
end


function Turns:createGHC(length, width)
    -- construct a Hamiltonian cycle of a grid graph
    if length == 2 or width == 2 then
        return self:createGHC2(length, width)
    elseif length % 2 == 0 then
        return self:createGHCL(length, width)
    elseif width % 2 == 0 then
        return self:createGHCW(length, width)
    else
        return nil
    end
end


local dx = {N=1, E=0, S=-1, W=0}
local dy = {N=0, E=1, S=0, W=-1}
local leftTurns = {N="W", E="N", S="E", W="S"}
local rightTurns = {N="E", E="S", S="W", W="N"}

GridPath = {}


function GridPath:new(l, w, o)
    if o ~= nil then
        o, l, w = l, w, o
    end

    if l == nil or w == nil then
        print("oh no")
        return
    end

    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.length = l
    self.width = w
    self.turns = Turns:new()
    self.turns:createZigZag(self.length, self.width)

    return o
end


function GridPath:walk(callback, inReverse)
    local x, y, direction, ts
    if inReverse then
        x, y = self.length, self.width
        direction = "S"
        ts = {A="R", B="L"}
    else
        x, y = 1, 1
        direction = "N"
        ts = {A="L", B="R"}
    end

    repeat
        if callback then callback() end
        tolerantMove("forward")
        x = x + dx[direction]
        y = y + dy[direction]

        local t = ts[self.turns[x][y]]
        if t == "L" then
            turtle.turnLeft()
            direction = leftTurns[direction]
        elseif t == "R" then
            turtle.turnRight()
            direction = rightTurns[direction]
        end
    until (x == 1 and y == 1) or (x == self.length and y == self.width)
end


GridHamiltonianCycle = {}


function GridHamiltonianCycle:new(l, w, o)
    if o ~= nil then
        o, l, w = l, w, o
    end

    if l == nil or w == nil then
        print("oh no")
        return
    end

    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.length = l
    self.width = w
    self.turns = Turns:new()
    if not self.turns:createGHC(self.length, self.width) then
        return nil
    end

    return o
end


function GridHamiltonianCycle:walk(callback)
    local x, y = 1, 1
    local direction = "N"
    repeat
        if callback then callback() end
        tolerantMove("forward")
        x = x + dx[direction]
        y = y + dy[direction]

        local t = self.turns[x][y]
        if t == "L" then
            turtle.turnLeft()
            direction = leftTurns[direction]
        elseif t == "R" then
            turtle.turnRight()
            direction = rightTurns[direction]
        end
    until x == 1 and y == 1
end


function find(item)
    for n = 1,16 do
        local detail = turtle.getItemDetail(n)
        if detail ~= nil and detail.name == item then
            return n
        end
    end
end
