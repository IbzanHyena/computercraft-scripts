if not os.loadAPI("/apis/clientserver") then
    print("Failed to load clientserver API")
end

clientserver.RunReceiver("altarcontrol", "regeneration", "regeneration")
