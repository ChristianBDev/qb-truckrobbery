truckStatus = {
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
				if Entity(entity).state.truckstate ~= TruckState.unguarded then return false end
				return isAtRearOfTruck()
			end
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
			canInteract = function(entity)
				if Entity(entity).state.truckstate ~= TruckState.exploded then return false end
				return isAtRearOfTruck()
			end
		},
	}
}
