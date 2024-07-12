truckStatus = {
	['guarded'] = {
		bone = 'door_dside_f',
		targetOptions = {
			action = function()
				Config.PoliceAlert()
				EjectFrontGuards()
			end,
			icon = 'fas fa-door-open',
			label = Lang:t('info.unlockdoors')
		},
	},

	['unguarded'] = {
		bone = { 'door_pside_r', 'door_dside_r' },
		targetOptions = {
			action = function()
				faceTruck()
				doPlantAnim()
				Entity(truck).state:set('truckstate', TruckState.planted, true)
				Wait((Config.Times.plant + Config.Times.fuse) * 1000 or 100)
				explodeTruck()
				EjectRearGuards()
				Entity(truck).state:set('truckstate', TruckState.exploded, true)
			end,
			icon = 'fas fa-truck-loading',
			label = Lang:t('info.plantbomb')
		},
	},

	['exploded'] = {
		targetOptions = {
			action = function()
				faceTruck()
				doLootAnim()
				Entity(truck).state:set('truckstate', TruckState.looted, true)
			end,
			icon = 'fas fa-truck-loading',
			label = Lang:t('info.loottruck')
		},
	}
}
