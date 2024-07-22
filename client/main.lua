local QBCore = exports['qb-core']:GetCoreObject()
local Eject = {}
local Truck = {}
local Animations = {}
local Blips = {}

function Eject.setTruck(self, truck)
	self.truck = truck
end

function Eject.frontGuards(self)
	for i = 0, 1 do
		local guard = GetPedInVehicleSeat(self.truck, i - 1)

		if DoesEntityExist(guard) and IsPedInAnyVehicle(guard, false) then
			TaskLeaveVehicle(guard, self.truck, 0)
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

function Eject.RearGuards(self)
	for i = 2, 3 do
		local guard = GetPedInVehicleSeat(self.truck, i - 1)

		if DoesEntityExist(guard) and IsPedInAnyVehicle(guard, false) then
			TaskLeaveVehicle(guard, self.truck, 0)
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

function Truck.explodeDoors(self)
	local offset = GetOffsetFromEntityInWorldCoords(self.truck, 0.0, -4.0, 0.0)

	for i = 2, 3 do
		SetVehicleDoorOpen(self.truck, i, true, false)
		Wait(50)
		SetVehicleDoorBroken(self.truck, i, true)
	end
	DeleteEntity(prop)
	AddExplosion(offset.x, offset.y, offset.z, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
	AddExplosion(offset.x, offset.y, offset.z + 2.0, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
end

function Truck.set(self, truck)
	self.truck = truck
end

function Truck.setState(self, state)
	Entity(self.truck).state:set('truckState', state, true)
end

function Truck.get(self)
	return self.truck
end

function Truck.getState(self)
	return Entity(self.truck).state.truckState
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

function Animations.setTruck(self, truck)
	self.truck = truck
end

function Animations.getTruck(self)
	return self.truck
end

function Animations.plant(self)
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
		AttachEntityToEntity(prop, self.truck, GetEntityBoneIndexByName(self.truck, 'door_pside_r'), -0.7, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
		FreezeEntityPosition(ped, false)
	end)
end

function Animations.loot(self)
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

function Blips.set(self, truck)
	self.truck = truck
end

function Blips.AddBlipEntity(self)
	local blip = AddBlipForEntity(self.truck)
	SetBlipHighDetail(blip, true)
	SetBlipSprite(blip, 67)
	SetBlipColour(blip, 1)
	SetBlipFlashes(blip, true)
	SetBlipRoute(blip, true)
	SetBlipRouteColour(blip, 6)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(Lang:t('info.robbery'))
	EndTextCommandSetBlipName(blip)
end

local function setTargetEntity(missionPed)
	exports['qb-target']:AddTargetEntity(missionPed, {
		options = {
			{
				icon = 'fas fa-truck-loading',
				label = Lang:t('info.startmission'),
				item = Config.StartItem,
				canInteract = function(entity)
					if Entity(entity).state.pedState then return false end
					return QBCore.Functions.GetPlayerData().job.type ~= 'leo'
				end,
				action = function()
					TriggerServerEvent('qb-truckrobbery:server:RemoveItem')
					TriggerServerEvent('qb-truckrobbery:server:startMission')
					QBCore.Functions.Notify(Lang:t('success.start_misssion'), 'success')
				end,
				debug = true,
			},
		},
		distance = 2.5
	})
end

local function setTargetTruck(truck)
	if not truck then return end

	exports['qb-target']:AddTargetBone('seat_dside_f', {
		options = {
			{
				icon = 'fas fa-door-open',
				label = Lang:t('info.unlockdoors'),
				canInteract = function(entity)
					if entity ~= truck then return false end
					if Truck:getState() ~= TruckState.guarded then return false end
					return true
				end,
				action = function()
					Config.PoliceAlert()
					Eject:frontGuards()
					Truck:setState(TruckState.unGuarded)
					exports['qb-target']:RemoveTargetBone('seat_dside_f')
				end,
			},
		},
		distance = 1.5
	})
	exports['qb-target']:AddTargetBone({ 'door_pside_r', 'door_dside_r' }, {
		options = {
			{
				icon = 'fas fa-truck-loading',
				label = Lang:t('info.plantbomb'),
				canInteract = function(entity)
					if entity ~= truck then return false end
					if Truck:getState() ~= TruckState.unGuarded then return false end
					return true
				end,
				action = function()
					Truck:setState(TruckState.planted)
					exports['qb-target']:RemoveTargetBone({ 'door_pside_r', 'door_dside_r' })
					Animations:plant()
					Wait((Config.Times.plant + Config.Times.fuse) * 1000)
					Truck:explodeDoors()
					Eject:RearGuards()
				end,
			},
		},
		distance = 1.5
	})
	exports['qb-target']:AddTargetBone({ 'seat_dside_r', 'seat_pside_r' }, {
		options = {
			{
				icon = 'fas fa-truck-loading',
				label = Lang:t('info.loottruck'),
				canInteract = function(entity)
					if entity ~= truck then return false end
					if Truck:getState() ~= TruckState.planted then return false end
					return true
				end,
				action = function()
					Truck:setState(TruckState.looted)
					exports['qb-target']:RemoveTargetBone({ 'seat_dside_r', 'seat_pside_r' })
					Animations:loot()
					Wait(Config.Times.loot * 1000)
					TriggerServerEvent('qb-truckrobbery:server:finishMission')
				end,
			},
		},
		distance = 1.5
	})
end

-- StateBags
AddStateBagChangeHandler('truckState', nil, function(bagName, _, _)
	local entity = GetEntityFromStateBagName(bagName)
	if entity == 0 then return end
	Wait(100)
	while not HasCollisionLoadedAroundEntity(entity) do
		if not DoesEntityExist(entity) then return end
		Wait(250)
	end

	setTargetTruck(entity)
	Blips:set(entity)
	Blips:AddBlipEntity()
	Truck:set(entity)
	Eject:setTruck(entity)
	Animations:setTruck(entity)
end)


AddStateBagChangeHandler('pedState', nil, function(bagName, _, _)
	local entity = GetEntityFromStateBagName(bagName)
	if entity == 0 then return end
	while not HasCollisionLoadedAroundEntity(entity) do
		if not DoesEntityExist(entity) then return end
		Wait(250)
	end
	setTargetEntity(entity)
	SetEntityInvincible(entity, true)
	FreezeEntityPosition(entity, true)
	TaskSetBlockingOfNonTemporaryEvents(entity, true)
end)

RegisterCommand('test', function()
	TriggerServerEvent('qb-truckrobbery:server:RemoveItem')
	TriggerServerEvent('qb-truckrobbery:server:startMission')
end)
