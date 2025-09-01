local QBCore = exports['qb-core']:GetCoreObject()

-- Create database table if it doesn't exist
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS ]] .. Config.DatabaseTable .. [[ (
            id INT AUTO_INCREMENT PRIMARY KEY,
            citizenid VARCHAR(50),
            outfitname VARCHAR(50),
            outfitdata LONGTEXT,
            bagid VARCHAR(50),
            bagtype VARCHAR(50),
            shared BOOLEAN DEFAULT false,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
end)

-- Server-side functions for outfit management
local function GenerateBagId()
    return "bag_" .. math.random(100000, 999999)
end

-- Save outfit to database
local function SaveOutfit(citizenid, outfitName, outfitData, bagId, bagType)
    MySQL.Async.insert('INSERT INTO ' .. Config.DatabaseTable .. ' (citizenid, outfitname, outfitdata, bagid, bagtype) VALUES (?, ?, ?, ?, ?)',
        {citizenid, outfitName, json.encode(outfitData), bagId, bagType})
end

-- Get all outfits for a specific bag
local function GetOutfits(bagId)
    local result = MySQL.Sync.fetchAll('SELECT * FROM ' .. Config.DatabaseTable .. ' WHERE bagid = ?', {bagId})
    return result
end

-- Get bag owner
local function GetBagOwner(bagId)
    local result = MySQL.Sync.fetchScalar('SELECT citizenid FROM ' .. Config.DatabaseTable .. ' WHERE bagid = ? LIMIT 1', {bagId})
    return result
end

-- Check if bag is shared with player or is owner
local function IsBagSharedWithPlayer(bagId, citizenid)
    -- First check if any outfits exist for this bag
    local outfitExists = MySQL.Sync.fetchScalar('SELECT COUNT(*) FROM ' .. Config.DatabaseTable .. ' WHERE bagid = ?', {bagId})
    
    -- If no outfits exist yet, allow access (new bag)
    if outfitExists == 0 then
        return true
    end
    
    -- Otherwise check permissions
    local result = MySQL.Sync.fetchScalar('SELECT 1 FROM ' .. Config.DatabaseTable .. ' WHERE bagid = ? AND (citizenid = ? OR shared = 1) LIMIT 1', {bagId, citizenid})
    return result ~= nil
end

-- Register useable items
QBCore.Functions.CreateUseableItem(Config.SmallOutfit, function(source, item)
    TriggerClientEvent('sg-outfitbag:client:useOutfitBag', source, item)
end)

QBCore.Functions.CreateUseableItem(Config.LargeOutfit, function(source, item)
    TriggerClientEvent('sg-outfitbag:client:useOutfitBag', source, item)
end)

-- Server events
RegisterNetEvent('sg-outfitbag:server:useOutfitBag', function(itemData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local bagType = itemData.name
    if bagType ~= Config.SmallOutfit and bagType ~= Config.LargeOutfit then return end

    -- Generate new bag ID if item doesn't have metadata
    if not itemData.info or not itemData.info.bagId then
        local bagId = GenerateBagId()
        local info = {
            bagId = bagId,
            owner = Player.PlayerData.citizenid
        }
        -- Remove the old item first
        Player.Functions.RemoveItem(itemData.name, 1)
        -- Add the new item with metadata
        Player.Functions.AddItem(itemData.name, 1, false, info)
        -- Remove the item again when placing
        Player.Functions.RemoveItem(itemData.name, 1)
        TriggerClientEvent('sg-outfitbag:client:placeBag', src, bagId, bagType)
    else
        -- Remove the item when placing the bag
        Player.Functions.RemoveItem(itemData.name, 1)
        TriggerClientEvent('sg-outfitbag:client:placeBag', src, itemData.info.bagId, bagType)
    end
    -- Show inventory update
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[bagType], "remove")
end)

RegisterNetEvent('sg-outfitbag:server:saveOutfit', function(outfitName, outfitData, bagId, bagType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check if player has access to this bag
    if not IsBagSharedWithPlayer(bagId, Player.PlayerData.citizenid) then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have access to this bag!', 'error')
        return
    end

    SaveOutfit(Player.PlayerData.citizenid, outfitName, outfitData, bagId, bagType)
    TriggerClientEvent('QBCore:Notify', src, 'Outfit saved successfully!', 'success')
end)

RegisterNetEvent('sg-outfitbag:server:getOutfits', function(bagId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check if player has access to this bag
    if not IsBagSharedWithPlayer(bagId, Player.PlayerData.citizenid) then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have access to this bag!', 'error')
        return
    end

    local outfits = GetOutfits(bagId)
    TriggerClientEvent('sg-outfitbag:client:receiveOutfits', src, outfits)
end)

RegisterNetEvent('sg-outfitbag:server:shareBag', function(bagId, targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then 
        TriggerClientEvent('QBCore:Notify', src, 'Player not found!', 'error')
        return 
    end

    -- Check if source player owns the bag
    local bagOwner = GetBagOwner(bagId)
    if bagOwner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t own this bag!', 'error')
        return
    end
    
    -- Update bag sharing status
    MySQL.Async.execute('UPDATE ' .. Config.DatabaseTable .. ' SET shared = true WHERE bagid = ?', {bagId})
    
    -- Notify both players
    TriggerClientEvent('QBCore:Notify', targetId, 'You have been given access to ' .. Player.PlayerData.charinfo.firstname .. '\'s outfit bag!', 'success')
    TriggerClientEvent('QBCore:Notify', src, 'You shared your outfit bag with ' .. Target.PlayerData.charinfo.firstname .. '!', 'success')
end)

RegisterNetEvent('sg-outfitbag:server:pickupBag', function(bagId, bagType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local info = {
        bagId = bagId
    }
    
    Player.Functions.AddItem(bagType, 1, false, info)
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[bagType], "add")
end)

RegisterNetEvent('sg-outfitbag:server:setupBagTarget', function(bagId, bagType)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check if player has access to this bag
    local hasAccess = IsBagSharedWithPlayer(bagId, Player.PlayerData.citizenid)
    
    -- Send the result back to the client
    TriggerClientEvent('sg-outfitbag:client:setupBagTarget', src, bagId, bagType, hasAccess)
    
    -- If the bag is shared, also set up targeting for all online players
    if hasAccess then
        local Players = QBCore.Functions.GetPlayers()
        for _, playerId in ipairs(Players) do
            if tonumber(playerId) ~= src then -- Skip the original player
                local TargetPlayer = QBCore.Functions.GetPlayer(tonumber(playerId))
                if TargetPlayer then
                    local targetHasAccess = IsBagSharedWithPlayer(bagId, TargetPlayer.PlayerData.citizenid)
                    if targetHasAccess then
                        TriggerClientEvent('sg-outfitbag:client:setupBagTarget', playerId, bagId, bagType, true)
                    end
                end
            end
        end
    end
end)
