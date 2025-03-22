local argv = { ... }

if not os.loadAPI("/apis/extraTurtle") then
    print("Failed to load extraTurtle API")
end

if #argv ~= 3 then
    print("Usage: farm <length> <width> <depth>")
    return
end

Length = tonumber(argv[1])
if Length == nil or Length < 2 then
    print("Length must be positive.")
    return
end

Width = tonumber(argv[2])
if Width == nil or Width < 2 then
    print("Width must be positive.")
    return
end

Depth = tonumber(argv[3])
if Depth == nil or Depth < 1 then
    print("Depth must be positive")
end

for i = 1,Depth do
    extraTurtle.walkGrid(Length, Width, turtle.digDown)
    extraTurtle.refuelToMin(1)
    extraTurtle.tolerantMove("down")
end
