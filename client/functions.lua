QBCore = exports['qb-core']:GetCoreObject()
local StartPed = nil
local truck, TruckBlip
status, truckStatus = nil

function isAtRearOfTruck()
  return #(GetEntityCoords(PlayerPedId()) - GetOffsetFromEntityInWorldCoords(truck, 0.0, -4.0, 0.0)) < 1.0
end

function updateTruckStatus(state)
  status = state
  TriggerServerEvent('qb-truckrobbery:server:UpdateTruckStatus', status)
end

function loadAnim(dict)
  while not HasAnimDictLoaded(dict) do
    RequestAnimDict(dict)
    Wait(10)
  end
end

function faceTruck()
  TaskGoToEntity(truck, PlayerPedId(), -1, 5.0, 1.0, 1073741824, 0)
  TaskTurnPedToFaceEntity(PlayerPedId(), truck, 500)
end

function setRelationshipGroups(guard)
  SetPedRelationshipGroupDefaultHash(guard, joaat('COP'))
  SetPedRelationshipGroupHash(guard, joaat('COP'))
  SetPedAsCop(guard, true)
  SetCanAttackFriendly(guard, false, true)
  TaskCombatPed(guard, PlayerPedId(), 0, 16)
end

function EjectFrontGuards()
  for i = -1, 1 do
    local guard = GetPedInVehicleSeat(truck, i - 1)

    if DoesEntityExist(guard) and IsPedInAnyVehicle(guard, false) then
      TaskLeaveVehicle(guard, truck, 0)           -- 0 is the flag to make them leave the vehicle without locking it
      SetEntityAsMissionEntity(guard, true, true) -- Mark the ped as a mission entity
      SetPedAsCop(guard, true)
      SetPedMaxHealth(guard, Config.Guards.health)
      SetPedArmour(guard, Config.Guards.armor)
      SetPedAccuracy(guard, Config.Guards.accuracy)
      GiveWeaponToPed(guard, Config.Guards.weapon, 255, false, true)
      TaskCombatPed(guard, PlayerPedId(), 0, 16) -- Make the ped attack the player
    end
  end
end

function EjectRearGuards()
  for i = 2, 3 do
    local guard = GetPedInVehicleSeat(truck, i - 1)

    if IsPedInAnyVehicle(guard, false) then
      TaskLeaveVehicle(guard, truck, 256)         -- 0 is the flag to make them leave the vehicle without locking it
      SetEntityAsMissionEntity(guard, true, true) -- Mark the ped as a mission entity
      SetPedAsCop(guard, true)
      SetPedMaxHealth(guard, Config.Guards.health)
      SetPedArmour(guard, Config.Guards.armor)
      SetPedAccuracy(guard, Config.Guards.accuracy)
      GiveWeaponToPed(guard, Config.Guards.weapon, 255, false, true)
      TaskCombatPed(guard, PlayerPedId(), 0, 16) -- Make the ped attack the player
    end
  end
end

function explodeTruck()
  local offset = GetOffsetFromEntityInWorldCoords(truck, 0.0, -4.0, 0.0)

  for i = 2, 3 do
    SetVehicleDoorOpen(truck, i, true, false)
    Wait(50)
    SetVehicleDoorBroken(truck, i, true)
  end
  DeleteEntity(prop)
  AddExplosion(offset.x, offset.y, offset.z, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
  AddExplosion(offset.x, offset.y, offset.z + 2.0, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
end

function progressAnim(anim, label, duration, cb)
  QBCore.Functions.Progressbar('name', label, duration, false, false, { -- Name | Label | Time | useWhileDead | canCancel
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true,
  }, anim, {}, {}, function() -- Play When Done
    cb()
  end)
end

function doPlantAnim()
  local ped = PlayerPedId()
  local anim = {
    animDict = 'anim@heists@ornate_bank@thermal_charge_heels',
    anim = 'thermal_charge',
  }
  local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)

  if GetCurrentPedWeapon(PlayerPedId(), true) ~= `WEAPON_UNARMED` then
    SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    Wait(2000)
  end
  SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
  prop = CreateObject(joaat('prop_c4_final_green'), GetEntityCoords(ped) + vector3(0, 0, 0.2), true, true, true)
  AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 60309), 0.06, 0.0, 0.06, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
  SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
  FreezeEntityPosition(ped, true)
  progressAnim(anim, Lang:t('progress.planting'), Config.Times.plant * 1000, function()
    SetCurrentPedWeapon(PlayerPedId(), weaponHash, true) -- Give back the weapon
    ClearPedTasks(ped)
    DetachEntity(prop, false, false)
    TriggerServerEvent('qb-truckrobbery:server:RemoveItem')
    AttachEntityToEntity(prop, truck, GetEntityBoneIndexByName(truck, 'door_pside_r'), -0.7, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    FreezeEntityPosition(ped, false)
  end)
end

function doLootAnim()
  local ped = PlayerPedId()
  local pedCoords = GetEntityCoords((ped))
  local anim = {
    animDict = 'anim@heists@ornate_bank@grab_cash_heels',
    anim = 'grab',
  }
  if GetCurrentPedWeapon(PlayerPedId(), true) ~= `WEAPON_UNARMED` then
    SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    Wait(2000)
  end
  local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
  SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
  local bagObj = CreateObject(joaat('prop_cs_heist_bag_02'), pedCoords.x, pedCoords.y, pedCoords.z, true, true, true)
  AttachEntityToEntity(bagObj, ped, GetPedBoneIndex(ped, 57005), 0.0, 0.0, -0.16, 250.0, -30.0, 0.0, false, false, false, false, 2, true)
  progressAnim(anim, Lang:t('progress.looting'), Config.Times.loot * 1000, function()
    SetCurrentPedWeapon(PlayerPedId(), weaponHash, true) -- Give back the weapon
    ClearPedTasks(ped)
    DeleteEntity(bagObj)
    SetPedComponentVariation(ped, 5, 45, 0, 2)
    TriggerServerEvent('qb-truckrobbery:server:FinishJob')
  end)
end

function addTargetToTruck(truck)
  for _, v in pairs(truckStatus) do
    if v.bone then
      exports['qb-target']:AddTargetBone(v.bone, {
        options = { v.targetOptions },
        distance = 2.5
      })
    else
      exports['qb-target']:AddTargetEntity(truck, {
        options = { v.targetOptions },
        distance = 2.5
      })
    end
  end
end

RegisterNetEvent('qb-truckrobbery:client:StartMission', function(activeJob, truckCoords)
  if activeJob then return QBCore.Functions.Notify(Lang:t('error.active_mission'), 'error') end
  QBCore.Functions.Notify(Lang:t('success.start_misssion'), 'success')

  TruckBlip = AddBlipForRadius(truckCoords.x, truckCoords.y, truckCoords.z, 250.0)
  SetBlipHighDetail(TruckBlip, true)
  SetBlipAlpha(TruckBlip, 90)
  SetBlipRoute(TruckBlip, true)
  SetBlipRouteColour(TruckBlip, 6)
  SetBlipColour(TruckBlip, 1)

  local truckSpawn

  truckSpawn = BoxZone:Create(truckCoords, 300, 300, {
    name = 'truck_spawned',
    debugPoly = true,
    useZ = true,
  })

  if not truckSpawn then return end
  truckSpawn:onPlayerInOut(function(isPointInside)
    if isPointInside then
      Config.PoliceAlert()
      QBCore.Functions.TriggerCallback('qb-truckrobbery:server:spawnTruck', function(truckNetId)
        local truck = NetworkGetEntityFromNetworkId(truckNetId)
        local driver = GetPedInVehicleSeat(truck, -1)

        while not DoesEntityExist(driver) or not DoesEntityExist(truck) do
          Wait(0)
        end

        TruckBlip = AddBlipForEntity(truck)
        SetBlipSprite(TruckBlip, 67)
        SetBlipColour(TruckBlip, 1)
        SetBlipFlashes(TruckBlip, true)
        SetBlipRoute(TruckBlip, true)
        SetBlipRouteColour(TruckBlip, 6)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Armored Truck')
        EndTextCommandSetBlipName(TruckBlip)
        if Config.EnableDriving then
          TaskVehicleDriveToCoordLongrange(driver, truck, Config.Route[math.random(1, #Config.Route)], 80.0, 786603)
        end
        SetVehicleEngineOn(truck, true, true, false)
        addTargetToTruck(truck)
      end, truckCoords)
    else
      return QBCore.Functions.Notify(Lang:t('error.truck_spawn'), 'error')
    end
  end)
  truckSpawn = isPointInside
end)

function setupPed()
  QBCore.Functions.TriggerCallback('qb-truckrobbery:server:GetPed', function(retPed)
    if StartPed then return end
    StartPed = NetworkGetEntityFromNetworkId(retPed)
    SetBlockingOfNonTemporaryEvents(StartPed, true)
    FreezeEntityPosition(StartPed, true)
    SetEntityInvincible(StartPed, true)
    exports['qb-target']:AddTargetEntity(StartPed, {
      options = {
        {
          icon = 'fas fa-truck-loading',
          label = Lang:t('info.startmission'),
          item = Config.StartItem,
          canInteract = function()
            return QBCore.Functions.GetPlayerData().job.type ~= 'leo'
          end,
          action = function()
            TriggerServerEvent('qb-truckrobbery:server:StartJob')
          end,
          debug = true,
        },
      },
      distance = 2.5
    })
  end)
end

RegisterCommand('test', function()
  TriggerServerEvent('qb-truckrobbery:server:StartJob')
end)

RegisterNetEvent('onResourceStart', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  setupPed()
end)
