require 'config'

-- Initialize variables
local noPlayersTime = 0
local timerActive = true
local firstLoad = true

-- Function to get the number of maps in the map list
local function getMapCount()
    local result = RCON:SendCommand('mapList.list')

    if result[1] == 'OK' and result[2] ~= nil then
        local mapCount = tonumber(result[2])
        if mapCount ~= nil then
            return mapCount
        else
            print('Error: mapCount is nil.')
            return 0
        end
    else
        print('Error: Failed to retrieve map list.')
        return 0
    end
end

-- Adjusted function to set and print the correct map index
local function setRandomNextMap()
    -- Get the map count
    local mapCount = getMapCount()

    if mapCount > 0 then
        -- Seed the random number generator with high-resolution time
        math.randomseed(SharedUtils:GetTimeMS())

        -- Generate a random index between 0 and mapCount - 1
        local randomIndex = math.random(1, mapCount)
        local nextMapIndex = randomIndex - 1

        -- Set the next map index
        local result = RCON:SendCommand('mapList.setNextMapIndex', { tostring(nextMapIndex) })

        -- Check if the command was successful
        if result[1] == 'OK' then
            -- Run the next round to load the random map
            RCON:SendCommand('mapList.runNextRound')
            print('Random map selected (Index: ' .. randomIndex .. '). Map change initiated.')
        else
            print('Error setting next map index: ' .. table.concat(result, ' '))
        end

    else
        print('No maps found in the map list.')
    end
end

-- Event to randomize the next map on server start
Events:Subscribe('Level:Loaded', function(levelName, gameMode, round, roundsPerMap)
    if firstLoad and RandomizeMapAtStart then
        firstLoad = false
        setRandomNextMap()
    elseif firstLoad then
        firstLoad = false
    end
end)

-- Event to handle player leaving
Events:Subscribe('Player:Left', function(player)
    if PlayerManager:GetPlayerCount() == 1 then
        -- Start the timer when no players are on the server
        timerActive = true
        noPlayersTime = 0
        print("All players left, timer activated.")
    end
end)

-- Event to handle player joining
Events:Subscribe('Player:Joining', function(name, playerGuid, ipAddress, accountGuid)
    -- Cancel the timer if it's active
    if timerActive then
        timerActive = false
        noPlayersTime = 0
        print("Player joined, timer stopped.")
    end
end)

-- Update event to manage timers
Events:Subscribe('Engine:Update', function(deltaTime, simulationDeltaTime)
    -- Handle no-player map skip timer
    if MapCyclingEnabled and timerActive then
        noPlayersTime = noPlayersTime + deltaTime
        if noPlayersTime >= SkipTime then
            setRandomNextMap()
            print('No players are on the server! Skipping map...')
            timerActive = false
            noPlayersTime = 0
        end
    end
end)
