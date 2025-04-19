local StateFile = "/state"

local function readState()
    local file = fs.open(StateFile, "r")
    local result = textutils.unserialise(file.readAll())
    file.close()
    return result
end

local function writeState(state)
    local file = fs.open(StateFile, "w")
    file.write(textutils.serialise(state))
    file.flush()
    file.close()
end

local function setScale(monitor, maxW, maxH)
    monitor.setTextScale(1)
    local w, h = monitor.getSize()
    local scaleW, scaleH = w/maxW, h/maxH
    scaleW, scaleH = scaleW*2, scaleH*2
    scaleW, scaleH = math.floor(scaleW+0.5), math.floor(scaleH+0.5)
    scaleW, scaleH = scaleW/2, scaleW/2
    local scale = math.min(scaleW, scaleH)
    monitor.setTextScale(scale)
end

local function displayStateColour(monitor, state)
    if monitor.setTextScale then
        local maxW, maxH = #"Feathered knife: off", 2
        setScale(monitor, maxW, maxH)
    end
    monitor.clear()

    -- featheredKnife
    monitor.setCursorPos(1, 1)
    monitor.setTextColour(colours.yellow)
    monitor.write("F")
    monitor.setTextColour(colours.white)
    monitor.write("eathered Knife: ")
    if state["featheredKnife"] then
        monitor.setTextColour(colours.green)
        monitor.write("on")
    else
        monitor.setTextColour(colours.red)
        monitor.write("off")
    end

    monitor.setTextColour(colours.white)

    -- regeneration
    monitor.setCursorPos(1, 2)
    monitor.setTextColour(colours.yellow)
    monitor.write("R")
    monitor.setTextColour(colours.white)
    monitor.write("egeneration: ")
    if state["regeneration"] then
        monitor.setTextColour(colours.green)
        monitor.write("on")
    else
        monitor.setTextColour(colours.red)
        monitor.write("off")
    end

    monitor.setCursorPos(1, 3)
    monitor.setTextColour(colours.white)
end

local function displayStateNoColour(monitor, state)
    if monitor.setTextScale then
        local maxW, maxH = #"[F]eathered knife: off", 2
        setScale(monitor, maxW, maxH)
    end
    monitor.clear()

    -- featheredKnife
    monitor.setCursorPos(1, 1)
    monitor.write("[F]eathered knife: ")
    if state["featheredKnife"] then
        monitor.write("on")
    else
        monitor.write("off")
    end

    -- regeneration
    monitor.setCursorPos(1, 2)
    monitor.write("[R]egeneration: ")
    if state["regeneration"] then
        monitor.write("on")
    else
        monitor.write("off")
    end

    monitor.setCursorPos(1, 3)
end

local function displayState(monitor, state)
    if monitor.isColour() then
        displayStateColour(monitor, state)
    else
        displayStateNoColour(monitor, state)
    end
end

if not fs.exists(StateFile) then
    writeState({featheredKnife=false, regeneration=false})
end

local sides = peripheral.getNames()
local Monitors = {term}
local ModemSide = nil

for _, side in pairs(sides) do
    local t = peripheral.getType(side)
    if ModemSide == nil and t == "modem" then
        ModemSide = side
    elseif t == "monitor" then
        table.insert(Monitors, peripheral.wrap(side))
    end
end

local function displayStateAll(state)
    for _, monitor in pairs(Monitors) do
        displayState(monitor, state)
    end
end

if ModemSide == nil then
    print("Unable to find modem")
    return
end

local function waitForReceivers()
    local fk, r
    while true do
        fk = rednet.lookup("altarcontrol", "featheredKnife")
        r = rednet.lookup("altarcontrol", "regeneration")
        if fk ~= nil and r ~= nil then
            return
        end
        sleep(1)
    end
end


rednet.open(ModemSide)
rednet.host("altarcontrol", "controller")
local State = readState()
displayStateAll(State)
waitForReceivers()
rednet.broadcast(State, "altarcontrol")

while true do
    local _, key, _ = os.pullEvent("key")
    local stateChanged = false
    if key == keys.f then
        State["featheredKnife"] = not State["featheredKnife"]
        stateChanged = true
    elseif key == keys.r then
        State["regeneration"] = not State["regeneration"]
        stateChanged = true
    end

    if stateChanged then
        writeState(State)
        displayStateAll(State)
        rednet.broadcast(State, "altarcontrol")
    end
end
