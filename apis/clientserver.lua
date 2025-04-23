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


function WaitForReceivers(receivers)
    while true do
        local allValid = true
        for _, p in pairs(receivers) do
            local rx = rednet.lookup(p[0], p[1])
            if rx == nil then
                allValid = false
                break
            end
        end

        if allValid then return end
        sleep(1)
    end
end


local function setScale(monitor, maxW, maxH)
    monitor.setTextScale(1)
    local w, h = monitor.getSize()
    local scaleW, scaleH = w/maxW, h/maxH
    scaleW, scaleH = scaleW*2, scaleH*2
    scaleW, scaleH = math.floor(scaleW), math.floor(scaleH)
    scaleW, scaleH = scaleW/2, scaleW/2
    local scale = math.min(scaleW, scaleH)
    scale = math.min(math.max(scale, 0.5), 5)
    monitor.setTextScale(scale)
end


function DisplayStateColour(config, monitor, state)
    if monitor.setTextScale then
        local maxH = #config
        local maxW = 0
        for _, t in pairs(config) do
            local maxDisplayLength = #t["displayText"]
            if not string.find(t["displayText"], keys.getName(t["toggleKey"])) then
                maxDisplayLength = maxDisplayLength + 4
            end
            maxDisplayLength = maxDisplayLength + 5
            maxW = math.max(maxW, maxDisplayLength)
        end
        setScale(monitor, maxW, maxH)
    end

    monitor.clear()

    local i = 0
    for k, t in pairs(config) do
        i = i + 1
        local key = keys.getName(t["toggleKey"])
        local keyShown = false
        monitor.setCursorPos(1, i)
        for j = 1,#t["displayText"] do
            local char = string.sub(t["displayText"], j, j)
            if not keyShown and string.lower(char) == key then
                monitor.setTextColour(colours.yellow)
                monitor.write(char)
                keyShown = true
                monitor.setTextColour(colours.white)
            else
                monitor.write(char)
            end
        end

        if not keyShown then
            monitor.write(" [")
            monitor.setTextColour(colours.yellow)
            monitor.write(string.upper(key))
            monitor.setTextColour(colours.white)
            monitor.write("]: ")
        else
            monitor.write(": ")
        end

        local on = state[k]
        if t["inverted"] then on = not on end
        if on then
            monitor.setTextColour(colours.green)
            monitor.write("on")
        else
            monitor.setTextColour(colours.red)
            monitor.write("off")
        end

        monitor.setTextColour(colours.white)
    end
end


function DisplayStateNoColour(config, monitor, state)
    if monitor.setTextScale then
        local maxH = #config
        local maxW = 0
        for _, t in pairs(config) do
            local maxDisplayLength = #t["displayText"]
            if string.find(t["displayText"], keys.getName(t["toggleKey"])) then
                maxDisplayLength = maxDisplayLength + 2
            else
                maxDisplayLength = maxDisplayLength + 4
            end
            maxDisplayLength = maxDisplayLength + 5
            maxW = math.max(maxW, maxDisplayLength)
        end
        setScale(monitor, maxW, maxH)
    end

    monitor.clear()

    local i = 0
    for k, t in pairs(config) do
        i = i + 1
        local key = keys.getName(t["toggleKey"])
        local keyShown = false
        monitor.setCursorPos(1, i)
        for j = 1,#t["displayText"] do
            local char = string.sub(t["displayText"], j, j)
            if not keyShown and string.lower(char) == key then
                monitor.write("[" .. char .. "]")
                keyShown = true
            else
                monitor.write(char)
            end
        end

        if not keyShown then
            monitor.write(" [" .. string.upper(key) .. "]: ")
        else
            monitor.write(": ")
        end

        if state[k] then
            monitor.write("on")
        else
            monitor.write("off")
        end
    end
end


function DisplayState(config, monitor, state)
    if monitor.isColour() then
        DisplayStateColour(config, monitor, state)
    else
        DisplayStateNoColour(config, monitor, state)
    end
end


function RunController(config, protocol, defaultState, receivers)
    -- initialise the variables for the server
    if not fs.exists(StateFile) then
        writeState(defaultState)
    end

    local sides = peripheral.getNames()
    local monitors = {term}
    local modemSide = nil

    for _, side in pairs(sides) do
        local t = peripheral.getType(side)
        if modemSide == nil and t == "modem" then
            modemSide = side
        elseif t == "monitor" then
            table.insert(monitors, peripheral.wrap(side))
        end
    end

    local function displayStateAll(state)
        for _, monitor in pairs(monitors) do
            DisplayState(config, monitor, state)
        end
    end

    if modemSide == nil then
        print("Unable to find modem")
        return
    end

    -- start the server
    rednet.open(modemSide)
    rednet.host(protocol, "controller")
    local state = readState()
    displayStateAll(state)
    if receivers then WaitForReceivers(receivers) end
    rednet.broadcast(state, protocol)

    while true do
        local _, key, _ = os.pullEvent("key")
        local stateChanged = false
        for k, t in pairs(config) do
            if key == t["toggleKey"] then
                state[k] = not state[k]
                stateChanged = true
                break
            end
        end

        if stateChanged then
            writeState(state)
            displayStateAll(state)
            rednet.broadcast(state, protocol)
        end
    end
end


function RunReceiver(protocol, key, hostname)
    local ModemSide = nil

    for _, side in pairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            ModemSide = side
            break
        end
    end

    if ModemSide == nil then
        print("Unable to find modem")
        return
    end

    rednet.open(ModemSide)
    if hostname then rednet.host(protocol, hostname) end

    while true do
        local _, message = rednet.receive(protocol)
        if message[key] ~= nil then
            for _, side in pairs(redstone.getSides()) do
                redstone.setOutput(side, message[key])
            end
        end
    end
end
