truckStatus = {
  ['guarded'] = {
    bone = 'door_dside_f',
    targetOptions = {
      action = function()
        if not Config.Minigames['Unlock Doors']() then return QBCore.Functions.Notify(Lang:t('error.failed_doors'), 'error') end
        if not guards[1] or not truck then return end
        Config.PoliceAlert()
        for _, v in pairs(guards) do
          local guard = NetworkGetEntityFromNetworkId(v.netId)
          if not DoesEntityExist(guard) then return end
          Functions.EjectFrontGuards()
          Functions.updateTruckStatus('unguarded')
        end
      end,
      icon = 'fas fa-door-open',
      label = Lang:t('info.unlockdoors'),
      canInteract = function(entity)
        if entity ~= truck then return false end
        if Entity(truck).state.status ~= 'guarded' then return false end
        return true
      end,
    },
  },

  ['unguarded'] = {
    bone = { 'door_pside_r', 'door_dside_r' },
    targetOptions = {
      action = function()
        Functions.faceTruck()
        Functions.doPlantAnim()
        Functions.updateTruckStatus('planted')
        Wait((Config.Times.plant + Config.Times.fuse) * 1000 or 100)
        Functions.explodeTruck()
        Functions.EjectRearGuards()
        Functions.updateTruckStatus('exploded')
      end,
      icon = 'fas fa-truck-loading',
      label = Lang:t('info.plantbomb'),
      canInteract = function(entity)
        if entity ~= truck then return false end
        if Entity(truck).state.status ~= 'unguarded' then return false end
        return Functions.isAtRearOfTruck()
      end,
    },
  },

  ['exploded'] = {
    targetOptions = {
      action = function()
        Functions.faceTruck()
        Functions.doLootAnim()
        Functions.updateTruckStatus('looted')
        Functions.cleanUp(true)
      end,
      icon = 'fas fa-truck-loading',
      label = Lang:t('info.loottruck'),
      canInteract = function()
        if Entity(truck).state.status ~= 'exploded' then return false end
        Functions.EjectRearGuards()
        return Functions.isAtRearOfTruck()
      end,
    },
  }
}
