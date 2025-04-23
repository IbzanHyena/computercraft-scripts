if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

clientserver.RunController(
    {
        featheredKnife = {toggleKey = keys.f, displayText = "Feathered knife", inverted = true},
        regeneration = {toggleKey = keys.r, displayText = "Regeneration", inverted = true},
    },
    "mobfarm",
    {featheredKnife=false, regeneration=false},
    {"featheredKnife", "regeneration"}
)
