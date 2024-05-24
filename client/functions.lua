QBCore = exports['qb-core']:GetCoreObject()
startPed = nil
truck = nil
guards = nil
truckStatus = nil
TruckBlip = nil
Functions = {}

Functions.isAtRearOfTruck = function()
  return #(GetEntityCoords(PlayerPedId()) - GetOffsetFromEntityInWorldCoords(truck, 0.0, -4.0, 0.0)) < 1.0
end

Functions.updateTruckStatus = function(state)
  TriggerServerEvent('qb-truckrobbery:server:UpdateTruckStatus', state)
end

Functions.loadAnim = function(dict)
  while not HasAnimDictLoaded(dict) do
    RequestAnimDict(dict)
    Wait(10)
  end
end

Functions.faceTruck = function()
  TaskGoToEntity(truck, PlayerPedId(), -1, 5.0, 1.0, 1073741824, 0)
  TaskTurnPedToFaceEntity(PlayerPedId(), truck, 500)
end

Functions.setRelationshipGroups = function(guard)
  SetPedRelationshipGroupDefaultHash(guard, joaat('COP'))
  SetPedRelationshipGroupHash(guard, joaat('COP'))
  SetPedAsCop(guard, true)
  SetCanAttackFriendly(guard, false, true)
  TaskCombatPed(guard, PlayerPedId(), 0, 16)
end

Functions.EjectFrontGuards = function()
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

Functions.EjectRearGuards = function()
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

Functions.explodeTruck = function()
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

Functions.progressAnim = function(anim, label, duration, cb)
  QBCore.Functions.Progressbar('name', label, duration, false, false, { -- Name | Label | Time | useWhileDead | canCancel
    disableMovement = true,
    disableCarMovement = true,
    disableMouse = false,
    disableCombat = true,
  }, anim, {}, {}, function() -- Play When Done
    cb()
  end)
end

Functions.doPlantAnim = function()
  local ped = PlayerPedId()
  local anim = {
    animDict = 'anim@heists@ornate_bank@thermal_charge_heels',
    anim = 'thermal_charge',
  }
  if GetCurrentPedWeapon(PlayerPedId(), true) ~= `WEAPON_UNARMED` then
    SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    Wait(2000)
  end
  local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
  SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
  prop = CreateObject(joaat('prop_c4_final_green'), GetEntityCoords(ped) + vector3(0, 0, 0.2), true, true, true)
  AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 60309), 0.06, 0.0, 0.06, 90.0, 0.0, 0.0, true, true, false, true, 1, true)
  SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
  FreezeEntityPosition(ped, true)
  Functions.progressAnim(anim, Lang:t('progress.planting'), Config.Times.plant * 1000, function()
    SetCurrentPedWeapon(PlayerPedId(), weaponHash, true) -- Give back the weapon
    ClearPedTasks(ped)
    DetachEntity(prop, false, false)
    TriggerServerEvent('qb-truckrobbery:server:RemoveItem')
    AttachEntityToEntity(prop, truck, GetEntityBoneIndexByName(truck, 'door_pside_r'), -0.7, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    FreezeEntityPosition(ped, false)
  end)
end

Functions.doLootAnim = function()
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
  Functions.progressAnim(anim, Lang:t('progress.looting'), Config.Times.loot * 1000, function()
    SetCurrentPedWeapon(PlayerPedId(), weaponHash, true) -- Give back the weapon
    ClearPedTasks(ped)
    DeleteEntity(bagObj)
    SetPedComponentVariation(ped, 5, 45, 0, 2)
    TriggerServerEvent('qb-truckrobbery:server:FinishJob')
  end)
end

Functions.addTargetToTruck = function(truck)
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


Functions.startJob = function()
  QBCore.Functions.TriggerCallback('qb-truckrobbery:server:StartJob', function(activeJob, retTruck, retguards)
    if activeJob then return QBCore.Functions.Notify(Lang:t('error.active_mission'), 'error') end
    truck = NetworkGetEntityFromNetworkId(retTruck)
    guards = retguards
    driver = NetworkGetEntityFromNetworkId(guards[1].netId)
    QBCore.Functions.Notify(Lang:t('success.start_misssion'), 'success')
    while not DoesEntityExist(driver) or not DoesEntityExist(truck) do
      Wait(0)
    end
    TruckBlip = AddBlipForEntity(truck)
    SetEntityAsMissionEntity(truck, true, true)
    SetBlipSprite(TruckBlip, 477)
    SetBlipColour(TruckBlip, 5)
    SetBlipRoute(TruckBlip, true)
    SetBlipRouteColour(TruckBlip, 5)
    TaskVehicleDriveToCoordLongrange(driver, truck, Config.Route[math.random(1, #Config.Route)], 80.0, 786603)
    SetVehicleEngineOn(truck, true, true, false)
    if not guards then return end
    Functions.addTargetToTruck(truck)
  end)
end

CreateThread(function()
  while true do
    Wait(3000)
    local plyCoords = GetEntityCoords(PlayerPedId(), false)
    local dist = #(plyCoords - vector3(Config.StartPed.coords.x, Config.StartPed.coords.y, Config.StartPed.coords.z))
    if dist <= 50 then
      Functions.setupPed()
    else
      if StartPed then
        DeletePed(StartPed)
        startPed = nil
      end
    end
  end
end)

Functions.setupPed = function()
  QBCore.Functions.TriggerCallback('qb-truckrobbery:server:GetPed', function(retPed)
    startPed = NetworkGetEntityFromNetworkId(retPed)
    SetBlockingOfNonTemporaryEvents(startPed, true)
    FreezeEntityPosition(startPed, true)
    SetEntityInvincible(startPed, true)
    exports['qb-target']:AddTargetEntity(startPed, {
      options = {
        {
          icon = 'fas fa-truck-loading',
          label = Lang:t('info.startmission'),
          item = Config.StartItem,
          action = Functions.startJob,
        },
      },
      distance = 2.5
    })
  end)
end

Functions.setUpScript = function()
  Functions.setupPed()
end

Functions.cleanUp = function(keepStartPed)
  if not keepStartPed then
    exports['qb-target']:RemoveTargetEntity(startPed)
  end
  exports['qb-target']:RemoveTargetEntity(truck)
  RemoveBlip(TruckBlip)
  for k, v in pairs(truckStatus) do
    if v.bone then
      exports['qb-target']:RemoveTargetBone(v.bone, v.label)
    end
  end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
  Functions.setUpScript()
end)

RegisterNetEvent('onResourceStart', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  Functions.setUpScript()
end)

RegisterNetEvent('onResourceStop', function(resoucename)
  if GetCurrentResourceName() ~= resoucename then return end
  Functions.cleanUp()
end)
