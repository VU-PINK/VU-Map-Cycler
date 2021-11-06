require 'config'

local lastCheckTime = 0

Events:Subscribe('Engine:Update', function(deltaTime, simulationDeltaTime)
    lastCheckTime = lastCheckTime + deltaTime

    if lastCheckTime > SkipTime and PlayerManager:GetPlayerCount() == 0 then
        RCON:SendCommand("mapList.runNextRound")
        lastCheckTime = 0
        print("No players are on the server! Skipping map...")
    elseif PlayerManager:GetPlayerCount() > 0 then
        lastCheckTime = 0
    end
end)