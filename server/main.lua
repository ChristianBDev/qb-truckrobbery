local QBCore = exports['qb-core']:GetCoreObject()
local AddStateBagChangeHandler = QBCore.Functions.AddStateBagChangeHandler
local activeJob = false
local onCooldown = false
local truck, truckNetId
local guards = {}
local truckStatus

exports('IsActive', function()
  return activeJob
end)

local function spawnPed()
  startPed = CreatePed(4, Config.StartPed.model, Config.StartPed.coords.x, Config.StartPed.coords.y, Config.StartPed.coords.z, Config.StartPed.coords.w, false, true)
  startPedNetId = NetworkGetNetworkIdFromEntity(startPed)
end

local function spawnGuards()
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

QBCore.Functions.CreateCallback('qb-truckrobbery:server:spawnTruck', function(source, cb, coords)
  if truck then return end
  local plate = 'ARMD' .. math.random(1000, 9999)
  truck = CreateVehicle(Config.Truck.model, coords, true, true)
  Wait(100)
  spawnGuards()
  SetVehicleNumberPlateText(truck, plate)
  truckNetId = NetworkGetNetworkIdFromEntity(truck)
  Entity(truck).state:set('truckstate', TruckState.guarded, true)
  cb(truckNetId)
end)

local function deleteTruck()
  if not truck then return end
  truck = NetworkGetEntityFromNetworkId(truckNetId)
  if DoesEntityExist(truck) then DeleteEntity(truck) end
  truck = nil
end

local function deleteGuards()
  if #guards == 0 then return end
  for i = 1, #guards do
    if DoesEntityExist(guards[i].id) then DeleteEntity(guards[i].id) end
  end
end

local function startJob()
  if onCooldown then return end
  if not activeJob then
    local coords = Config.Truck.spawnlocations[math.random(1, #Config.Truck.spawnlocations)]
    TriggerClientEvent('qb-truckrobbery:client:StartMission', source, activeJob, coords)
    activeJob = true
  end
end

function StartCooldown()
  onCooldown = true
  SetTimeout(Config.Times.cooldown * 1000, function()
    onCooldown = false
    activeJob = false
  end)
end

local function FinishMission()
  activeJob = false
  deleteGuards()
  deleteTruck()
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
  cb(false, startJob())
end)

QBCore.Functions.CreateCallback('qb-truckrobbery:server:GetPed', function(_, cb)
  cb(startPedNetId)
end)

RegisterNetEvent('qb-truckrobbery:server:StartJob', startJob)
RegisterNetEvent('qb-truckrobbery:server:FinishJob', function()
  IssueRewards(source)
end)

RegisterNetEvent('onResourceStop', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  if DoesEntityExist(startPed) then DeleteEntity(startPed) end
  deleteGuards()
  deleteTruck()
end)

RegisterNetEvent('onResourceStart', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  spawnPed()
end)
