local argv = { ... }

if #argv ~= 2 then
    print("Usage: wget <url> <target>")
end

local url = argv[1]
local target = argv[2]

if not http then
    print("http not enabled")
    return
end

local response = http.get(url)
if not response then
    print("failed to connect")
    return
end

local file = fs.open(target, "w")
if not file then
    print("failed to open file")
    return
end

file.write(response.readAll())
file.close()
