local StateFile = "/state"

local function readState()
    local file = fs.open(StateFile, "r")
    local result = textutils.unserialiseJSON(file.readAll())
    file.close()
    return result
end

local function writeState(state)
    local file = fs.open(StateFile, "w")
    file.write(textutils.serialiseJSON(state))
    file.flush()
    file.close()
end

local function displayStateColour(monitor, state)
    monitor.clear()

    -- featheredKnife
    monitor.setTextColour("yellow")
    monitor.write("F")
    monitor.setTextColour("white")
    monitor.write("eathered Knife: ")
    if state.featheredKnife then
        monitor.setTextColour("green")
        monitor.write("on")
    else
        monitor.setTextColour("red")
        monitor.write("off")
    end

    monitor.setTextColour("white")
    monitor.write("\n")

    -- regeneration
    monitor.setTextColour("yellow")
    monitor.write("R")
    monitor.setTextColour("white")
    monitor.write("egenration: ")
    if state.regeneration then
        monitor.setTextColour("green")
        monitor.write("on")
    else
        monitor.setTextColour("red")
        monitor.write("off")
    end

    monitor.setTextColour("white")
end

local function displayStateNoColour(monitor, state)
    monitor.clear()

    -- featheredKnife
    monitor.write("[F]eathered knife: ")
    if state.featheredKnife then
        monitor.write("on")
    else
        monitor.write("off")
    end
    monitor.write("\n")

    -- regeneration
    monitor.write("[R]egenration: ")
    if state.regeneration then
        monitor.write("on")
    else
        monitor.write("off")
    end
    monitor.write("\n")
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
        for _, monitor in pairs(Monitors) do
            displayState(monitor, State)
        end
    end
end
