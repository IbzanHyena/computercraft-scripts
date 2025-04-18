if not os.loadAPI("/apis/altarcontrol") then
    print("Failed to load altarcontrol API")
end

altarcontrol.RunReceiver("featheredKnife")
