if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

clientserver.RunController(
    {lighting = {toggleKey = keys.l, displayText = "Lighting", inverted = false}},
    "mobfarm",
    {lighting=false}
)
