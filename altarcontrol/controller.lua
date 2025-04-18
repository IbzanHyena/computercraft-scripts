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

local function displayStateColour(monitor, state)
    monitor.clear()

    -- featheredKnife
    monitor.setCursorPos(1, 1)
    monitor.setTextColour(colours.yellow)
    monitor.write("F")
    monitor.setTextColour(colours.white)
    monitor.write("eathered Knife: ")
    if state.featheredKnife then
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
    monitor.write("egenration: ")
    if state.regeneration then
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
    monitor.clear()

    -- featheredKnife
    monitor.setCursorPos(1, 1)
    monitor.write("[F]eathered knife: ")
    if state.featheredKnife then
        monitor.write("on")
    else
        monitor.write("off")
    end

    -- regeneration
    monitor.setCursorPos(1, 2)
    monitor.write("[R]egenration: ")
    if state.regeneration then
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

local Monitors = {term}
local State = readState()

local function displayStateAll()
    for _, monitor in pairs(Monitors) do
        displayState(monitor, State)
    end
end

displayStateAll()
while true do
    local event, key, isHeld = os.pullEvent("key")
    local stateChanged = false
    if key == keys.f then
        State.featheredKnife = not State.featheredKnife
        stateChanged = true
    elseif key == keys.r then
        State.regeneration = not State.regeneration
        stateChanged = true
    end

    if stateChanged then
        displayStateAll()
    end
end
