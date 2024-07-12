truckStatus = {
  ['guarded'] = {
    bone = 'door_dside_f',
    targetOptions = {
      action = function()
        Config.PoliceAlert()
        EjectFrontGuards()
        updateTruckStatus('unguarded')
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
        faceTruck()
        doPlantAnim()
        updateTruckStatus('planted')
        Wait((Config.Times.plant + Config.Times.fuse) * 1000 or 100)
        explodeTruck()
        EjectRearGuards()
        updateTruckStatus('exploded')
      end,
      icon = 'fas fa-truck-loading',
      label = Lang:t('info.plantbomb'),
      canInteract = function(entity)
        if entity ~= truck then return false end
        if Entity(truck).state.status ~= 'unguarded' then return false end
        return isAtRearOfTruck()
      end,
    },
  },

  ['exploded'] = {
    targetOptions = {
      action = function()
        faceTruck()
        doLootAnim()
        updateTruckStatus('looted')
      end,
      icon = 'fas fa-truck-loading',
      label = Lang:t('info.loottruck'),
      canInteract = function()
        if Entity(truck).state.status ~= 'exploded' then return false end
        return isAtRearOfTruck()
      end,
    },
  }
}
