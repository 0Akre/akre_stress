local QBCore = exports['qb-core']:GetCoreObject()

local notifyType = "qb" -- or ox

local stress = 0
local maxStress = 3.0
local minStressEffect = 0.8
local stressIncreaseInterval = 10000
local stressDecreaseInterval = 5000
local shakeReductionFactor = 0.02

local govMaxStress = 3.0
local govMinStressEffect = 0.8
local govStressIncreaseInterval = 15000
local govStressDecreaseInterval = 6500
local govShakeReductionFactor = 0.02

local lastStressIncrease = 0
local lastStressDecrease = 0


function IsGovernmentJob()
    local playerJob = QBCore.Functions.GetPlayerData().job.name
    return playerJob == "police" or playerJob == "sheriff" or playerJob == "sahp" or playerJob == "ambulance"
end

function UpdateStressConfig()
    if IsGovernmentJob() then
        maxStress = govMaxStress
        minStressEffect = govMinStressEffect
        stressIncreaseInterval = govStressIncreaseInterval
        stressDecreaseInterval = govStressDecreaseInterval
        shakeReductionFactor = govShakeReductionFactor
    else
        maxStress = 6.0
        minStressEffect = 1.0
        stressIncreaseInterval = 5000
        stressDecreaseInterval = 10000
        shakeReductionFactor = 0.2
    end
end

local function Notify(title, description, type)
    if notifyType == "ox" then
        exports.ox_lib:notify({
            title = title,
            description = description,
            type = type
        })
    else
        TriggerEvent("QBCore:Notify", description, type)
    end
end

function IncreaseStress()
    if GetGameTimer() - lastStressIncrease >= stressIncreaseInterval then
        local playerPed = PlayerPedId()
        local speed = GetEntitySpeed(playerPed) * 2.23694

        if speed > 85.0 and stress < maxStress then
            stress = math.min(stress + math.random(10, 50) / 100, maxStress)
            lastStressIncrease = GetGameTimer()
            
            if stress < maxStress then
                Notify("Notification", "Stress increased to " .. string.format("%.1f", stress), "error")
            end
        end
    end
end

function DecreaseStress()
    if GetGameTimer() - lastStressDecrease >= stressDecreaseInterval and GetGameTimer() - lastStressIncrease >= 10000 then
        local playerPed = PlayerPedId()
        local speed = GetEntitySpeed(playerPed) * 2.23694

        if speed <= 90.0 and stress > 0 then
            stress = math.max(stress - math.random(10, 40) / 100, 0)
            lastStressDecrease = GetGameTimer()
            
            if stress > 0 then
                Notify("Notification", "Stress reduced to " .. string.format("%.1f", stress), "success")
            end
        end
    end
end

function ApplyStressEffect()
    if stress >= minStressEffect then
        local shakeIntensity = ((stress - minStressEffect) / (maxStress - minStressEffect)) * shakeReductionFactor
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", shakeIntensity)
    else
        StopGameplayCamShaking(true)
    end
end

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    stress = 0
    UpdateStressConfig()
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    stress = 0
end)

CreateThread(function()
    while true do
        Wait(100)
        ApplyStressEffect()
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        UpdateStressConfig()
        IncreaseStress()
        DecreaseStress()
    end
end)