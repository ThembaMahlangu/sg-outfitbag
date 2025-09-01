local QBCore = exports['qb-core']:GetCoreObject()

-- Variables
local placedBags = {}
local currentBag = nil
local isChangingClothes = false

-- Animation functions
local function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

local function PlayPlaceBagAnimation()
    local ped = PlayerPedId()
    loadAnimDict("pickup_object")
    TaskPlayAnim(ped, "pickup_object", "putdown_low", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(1000)
    ClearPedTasks(ped)
end

-- Clothing change sequence
local changeSequence = {
    {name = "Removing Hat/Accessories", components = {}, props = {0, 1, 2, 6, 7}, anim = "mp_masks@standard_car@ds@"},
    {name = "Changing Mask/Face", components = {1, 9}, props = {}, anim = "missfbi4"},
    {name = "Changing Top", components = {3, 8, 11}, props = {}, anim = "clothingshirt"},
    {name = "Changing Pants", components = {4}, props = {}, anim = "re@construction"},
    {name = "Changing Shoes", components = {6}, props = {}, anim = "random@domestic"},
    {name = "Adding Accessories", components = {5, 7}, props = {}, anim = "clothingshirt"},
    {name = "Finishing Up", components = {}, props = {0, 1, 2, 6, 7}, anim = "mp_masks@standard_car@ds@"}
}

local animationSets = {
    ["mp_masks@standard_car@ds@"] = {
        dict = "mp_masks@standard_car@ds@",
        anim = "put_on_mask",
        duration = 800
    },
    ["missfbi4"] = {
        dict = "missfbi4",
        anim = "takeoff_mask",
        duration = 1000
    },
    ["clothingshirt"] = {
        dict = "clothingshirt",
        anim = "try_shirt_positive_d",
        duration = 1500
    },
    ["re@construction"] = {
        dict = "re@construction",
        anim = "out_of_breath",
        duration = 1300
    },
    ["random@domestic"] = {
        dict = "random@domestic",
        anim = "pickup_low",
        duration = 1200
    }
}

local function PlayChangeAnimation(animSet)
    local ped = PlayerPedId()
    local anim = animationSets[animSet]
    if not anim then return end
    
    loadAnimDict(anim.dict)
    TaskPlayAnim(ped, anim.dict, anim.anim, 8.0, -8.0, anim.duration, 0, 0, false, false, false)
    Wait(anim.duration)
    ClearPedTasks(ped)
end

-- Outfit management functions
local function GetCurrentOutfit()
    local ped = PlayerPedId()
    local outfit = {
        model = GetEntityModel(ped),
        components = {},
        props = {}
    }
    
    -- Get all clothing components
    for i = 0, 11 do
        outfit.components[i] = {
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
            palette = GetPedPaletteVariation(ped, i)
        }
    end
    
    -- Get all props
    for i = 0, 7 do
        outfit.props[i] = {
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i)
        }
    end
    
    return outfit
end

local function ApplyOutfitStep(ped, outfit, step)
    -- Apply components for this step
    for _, componentId in ipairs(step.components) do
        if outfit.components[tostring(componentId)] then
            local data = outfit.components[tostring(componentId)]
            SetPedComponentVariation(ped, componentId, data.drawable, data.texture, data.palette)
        end
    end
    
    -- Apply props for this step
    for _, propId in ipairs(step.props) do
        if outfit.props[tostring(propId)] then
            local data = outfit.props[tostring(propId)]
            if data.drawable == -1 then
                ClearPedProp(ped, propId)
            else
                SetPedPropIndex(ped, propId, data.drawable, data.texture, true)
            end
        end
    end
end

local function ApplyOutfitSequence(outfitData)
    if isChangingClothes then return end
    isChangingClothes = true
    
    local ped = PlayerPedId()
    local outfit = json.decode(outfitData)
    
    -- Create a thread for the sequence
    Citizen.CreateThread(function()
        for _, step in ipairs(changeSequence) do
            PlayChangeAnimation(step.anim)
            ApplyOutfitStep(ped, outfit, step)
            Wait(100) -- Small delay between steps
        end
        
        isChangingClothes = false
        QBCore.Functions.Notify('Outfit change completed!', 'success')
    end)
end

-- QB-Target and menu functions
local function SetupBagTarget(bagObject, bagId, bagType)
    exports['qb-target']:AddTargetEntity(bagObject, {
        options = {
            {
                type = "client",
                event = "sg-outfitbag:client:openBagMenu",
                icon = "fas fa-suitcase",
                label = "Open Bag",
                bagId = bagId,
                bagType = bagType
            },
            {
                type = "client",
                event = "sg-outfitbag:client:pickupBag",
                icon = "fas fa-hand",
                label = "Pickup Bag",
                bagId = bagId,
                bagType = bagType
            }
        },
        distance = 2.5
    })
    
    if bagType == Config.LargeOutfit then
        exports['qb-target']:AddTargetEntity(bagObject, {
            options = {
                {
                    type = "client",
                    event = "sg-outfitbag:client:shareBag",
                    icon = "fas fa-share",
                    label = "Share Bag",
                    bagId = bagId
                }
            },
            distance = 2.5
        })
    end
end

-- Events
RegisterNetEvent('sg-outfitbag:client:placeBag', function(bagId, bagType)
    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
    
    PlayPlaceBagAnimation()
    
    local modelHash = `prop_cs_heist_bag_02`
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end
    
    local bagObject = CreateObject(modelHash, coords.x, coords.y, coords.z - 1.0, true, true, true)
    PlaceObjectOnGroundProperly(bagObject)
    FreezeEntityPosition(bagObject, true)
    SetEntityAsMissionEntity(bagObject, true, true)
    
    placedBags[bagId] = bagObject
    TriggerServerEvent('sg-outfitbag:server:setupBagTarget', bagId, bagType)
end)

RegisterNetEvent('sg-outfitbag:client:openBagMenu', function(data)
    currentBag = data.bagId -- Add this line to track the current bag
    TriggerServerEvent('sg-outfitbag:server:getOutfits', data.bagId)
end)

RegisterNetEvent('sg-outfitbag:client:receiveOutfits', function(outfits)
    local menuItems = {
        {
            header = "Outfit Bag",
            isMenuHeader = true
        },
        {
            header = "Save Current Outfit",
            txt = "Save what you're wearing now",
            params = {
                event = "sg-outfitbag:client:saveOutfitMenu",
                args = {
                    bagId = currentBag
                }
            }
        }
    }
    
    for _, outfit in ipairs(outfits) do
        menuItems[#menuItems + 1] = {
            header = outfit.outfitname,
            txt = "Wear this outfit",
            params = {
                event = "sg-outfitbag:client:wearOutfit",
                args = {
                    outfitData = outfit.outfitdata
                }
            }
        }
    end
    
    exports['qb-menu']:openMenu(menuItems)
end)

RegisterNetEvent('sg-outfitbag:client:saveOutfitMenu', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "Save Outfit",
        submitText = "Save",
        inputs = {
            {
                text = "Outfit Name",
                name = "outfitname",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if dialog and dialog.outfitname then
        local outfitData = GetCurrentOutfit()
        TriggerServerEvent('sg-outfitbag:server:saveOutfit', dialog.outfitname, outfitData, data.bagId, currentBag)
    end
end)

RegisterNetEvent('sg-outfitbag:client:wearOutfit', function(data)
    ApplyOutfitSequence(data.outfitData)
end)

RegisterNetEvent('sg-outfitbag:client:wearOutfitCategory', function(data)
    ApplyOutfitSequence(data.outfitData)
end)

RegisterNetEvent('sg-outfitbag:client:wearFullOutfit', function(data)
    ApplyOutfitSequence(data.outfitData)
end)

RegisterNetEvent('sg-outfitbag:client:pickupBag', function(data)
    if placedBags[data.bagId] then
        local bagObject = placedBags[data.bagId]
        PlayPlaceBagAnimation()
        
        TriggerServerEvent('sg-outfitbag:server:pickupBag', data.bagId, data.bagType)
        DeleteObject(bagObject)
        placedBags[data.bagId] = nil
    end
end)

RegisterNetEvent('sg-outfitbag:client:shareBag', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "Share Bag",
        submitText = "Share",
        inputs = {
            {
                text = "Player ID",
                name = "playerid",
                type = "number",
                isRequired = true
            }
        }
    })
    
    if dialog and dialog.playerid then
        TriggerServerEvent('sg-outfitbag:server:shareBag', data.bagId, tonumber(dialog.playerid))
    end
end)

RegisterNetEvent('sg-outfitbag:client:useOutfitBag', function(item)
    TriggerServerEvent('sg-outfitbag:server:useOutfitBag', item)
end)

RegisterNetEvent('sg-outfitbag:client:setupBagTarget', function(bagId, bagType, hasAccess)
    local bagObject = placedBags[bagId]
    if bagObject and hasAccess then
        SetupBagTarget(bagObject, bagId, bagType)
    end
end)
