local QBCore = exports['qb-core']:GetCoreObject()
local activeJob = false
local onCooldown = false
local startPed, startPedNetId, truck, truckNetId, TruckBlip
local guards = {}
local truckStatus

exports('IsActive', function()
  return activeJob
end)

local spawnPed = function()
  startPed = CreatePed(4, Config.StartPed.model, Config.StartPed.coords.x, Config.StartPed.coords.y, Config.StartPed.coords.z, Config.StartPed.coords.w, false, true)
  startPedNetId = NetworkGetNetworkIdFromEntity(startPed)
end

local spawnGuards = function()
  for i = 1, Config.Guards.number < 5 and Config.Guards.number or 4 do
    local spawnGuard = CreatePedInsideVehicle(truck, 4, Config.Guards.model, i - 2, true, true) -- Change seat val to i - 2
    while not DoesEntityExist(spawnGuard) do Wait(10) end
    Wait(100)
    guards[i] = {
      id = spawnGuard,
      netId = NetworkGetNetworkIdFromEntity(spawnGuard),
      seat = i - 2,
    }
  end
  return guards
end

local spawnTruck = function()
  if truck then return end
  local plate = 'ARMD' .. math.random(1000, 9999)
  local locOfVeh = Config.Truck.spawnlocations[math.random(1, #Config.Truck.spawnlocations)]
  truck = CreateVehicle(Config.Truck.model, locOfVeh.x, locOfVeh.y, locOfVeh.z, locOfVeh.w, true, true)
  Wait(100)
  TruckBlip = AddBlipForCoord(GetEntityCoords(truck))
  SetBlipSprite(TruckBlip, 67)
  SetVehicleNumberPlateText(truck, plate)
  truckNetId = NetworkGetNetworkIdFromEntity(truck)
  truckStatus = 'guarded' --MUST BE CHANGED TO guarded
  Entity(truck).state:set('status', truckStatus, true)
  return truckNetId
end

local deleteTruck = function()
  if not truck then return end
  truck = NetworkGetEntityFromNetworkId(truckNetId)
  if DoesEntityExist(truck) then DeleteEntity(truck) end
  truck = nil
end

local deleteGuards = function()
  if #guards == 0 then return end
  for i = 1, #guards do
    if DoesEntityExist(guards[i].id) then DeleteEntity(guards[i].id) end
  end
end

local deletePed = function()
  if DoesEntityExist(startPed) then DeleteEntity(startPed) end
end

local deleteAllEntities = function(keepStartPed)
  if not keepStartPed then deletePed() end
  deleteGuards()
  deleteTruck()
end

local startJob = function()
  activeJob = true
  local truck, guards = spawnTruck(), spawnGuards()
  return truck, guards
end

local updateTruckStatus = function(status)
  local avalableStatus = {
    ['guarded'] = true,
    ['unguarded'] = true,
    ['planted'] = true,
    ['exploded'] = true,
    ['looted'] = true,
  }
  assert(avalableStatus[status], 'Please provide a valid status for truck')
  truckStatus = status
  Entity(truck).state:set('status', truckStatus, true)
end

function StartCooldown()
  onCooldown = true
  SetTimeout(Config.Times.cooldown * 1000, function()
    onCooldown = false
  end)
end

local FinishMission = function()
  activeJob = false
  deleteAllEntities(true)
  StartCooldown()
end

RegisterNetEvent('qb-truckrobbery:server:RemoveItem', function()
  local src = source
  local Player = QBCore.Functions.GetPlayer(src)
  Player.Functions.RemoveItem(Config.StartItem, 1)
  TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[Config.StartItem], 'remove')
end)

function IssueRewards(source)
  local Player = QBCore.Functions.GetPlayer(source)
  Reward = Config.Rewards
  local chance = math.random(1, 100)

  if chance >= 85 then
    exports['qb-inventory']:AddItem(source, 'security_card_01', 1, false, 'qb-truckrobbery:server:recieveItem')
    TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items['security_card_01'], 'add')
  end
  assert(Reward, 'Please check the config file for the rewards table')
  Player.Functions.AddMoney('cash', Reward.cash)
  for k, v in pairs(Reward.items) do
    local info = { worth = v }
    if k == 'markedbills' then
      local amount = math.random(1, 5)
      exports['qb-inventory']:AddItem(source, 'markedbills', amount, false, info, 'qb-truckrobbery:server:recieveItem')
      TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], 'add', amount)
    end
  end
  Wait(Config.Times.issuedRewardsTimer * 1000)
  FinishMission()
end

QBCore.Functions.CreateCallback('qb-truckrobbery:server:StartJob', function(source, cb)
  if activeJob then return cb(activeJob) end
  local truck, guards = startJob()
  cb(false, truck, guards)
end)

QBCore.Functions.CreateCallback('qb-truckrobbery:server:GetPed', function(_, cb)
  cb(startPedNetId)
end)

QBCore.Functions.CreateCallback('qb-truckrobbery:server:GetTruckStatus', function(source, cb)
  cb(truckStatus)
end)

RegisterNetEvent('qb-truckrobbery:server:StartJob', startJob)
RegisterNetEvent('qb-truckrobbery:server:UpdateTruckStatus', updateTruckStatus)
RegisterNetEvent('qb-truckrobbery:server:FinishJob', function()
  IssueRewards(source)
end)

RegisterNetEvent('onResourceStop', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  deleteAllEntities()
end)

RegisterNetEvent('onResourceStart', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  spawnPed()
end)
