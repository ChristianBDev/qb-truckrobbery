local QBCore = exports['qb-core']:GetCoreObject()
local onCooldown = false
local Peds = {}
local Trucks = {}
local Timeout = {}

-- Peds
function Peds.create(self, model, coords)
	self.ped = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, true, true)
	Peds.setState(self, false)
	return self.ped
end

function Peds.delete(self)
	assert(self.ped, 'Ped does not exist')
	if DoesEntityExist(self.ped) then DeleteEntity(self.ped) end
end

function Peds.setState(self, state)
	Entity(self.ped).state:set('pedState', state, true)
end

function Peds.getState(self)
	local state = Entity(self.ped).state
	return state.pedState
end

function Peds.location(self)
	if GetEntityCoords(self.ped) then
		return GetEntityCoords(self.ped)
	end
end

-- Trucks
function Trucks.create(self, coords)
	local plate = 'ARMD' .. math.random(1000, 9999)
	self.truck = CreateVehicleServerSetter(Config.Truck.model, 'automobile', coords.x, coords.y, coords.z, coords.w)
	Entity(self.truck).state:set('truckState', TruckState.guarded, true)
	SetVehicleDirtLevel(self.truck, 0.0)
	SetVehicleOnGroundProperly(self.truck)
	SetVehicleNumberPlateText(self.truck, plate)
	AddBlipForCoord(GetEntityCoords(self.truck))
	-- SetBlipSprite(self.blip, 67)t
	SetVehicleEngineOn(self.truck, true, true, false)
	SetVehicleDoorsLocked(self.truck, 2)
	SetVehicleDoorsLockedForAllPlayers(self.truck, true)
	Wait(500)
end

function Trucks.guard(self)
	local temp = {}
	for i = -1, 2 do
		local guard = CreatePedInsideVehicle(self.truck, 4, Config.Guards.model, i, true, true)
		temp[#temp + 1] = guard
		Wait(100)
		self.guards = temp
	end
end

function Trucks.deleteGuard(self)
	if not self.truck then return end
	if DoesEntityExist(self.truck) then DeleteEntity(self.truck) end
	for _, guard in ipairs(self.guards) do
		DeleteEntity(guard)
	end
end

function Trucks.delete(self)
	if not self.truck then return end
	if DoesEntityExist(self.truck) then DeleteEntity(self.truck) end
end

local function startMission()
	if Peds:getState() then return end
	Peds:setState(true)
	Trucks:create(Config.Truck.spawnlocations[math.random(1, #Config.Truck.spawnlocations)])
	Trucks:guard()
	Timeout:set()
end

local function finishMission()
	Peds:setState(false)
	Trucks:delete()
	Trucks:deleteGuard()
	IssueRewards(source)
end

function IssueRewards(source)
	local Player = QBCore.Functions.GetPlayer(source)
	Reward = Config.Rewards
	local chance = math.random(1, 100)

	if chance >= 85 then
		exports['qb-inventory']:AddItem(source, 'security_card_01', 1, false)
		TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items['security_card_01'], 'add')
	end
	assert(Reward, 'Please check the config file for the rewards table')
	Player.Functions.AddMoney('cash', Reward.cash)
	for k, v in pairs(Reward.items) do
		local info = { worth = v }
		if k == 'markedbills' then
			local amount = math.random(1, 5)
			exports['qb-inventory']:AddItem(source, 'markedbills', amount, false, info)
			TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items['markedbills'], 'add', amount)
		end
	end
	Wait(Config.Times.issuedRewardsTimer * 1000)
	FinishMission()
end

-- Timeouts
function Timeout.set()
	SetTimeout(Config.Times.cooldown * 1000, function()
		onCooldown = true
	end)
	onCooldown = false
end

-- Net Events
RegisterNetEvent('qb-truckrobbery:server:startMission', startMission)
RegisterNetEvent('qb-truckrobbery:server:finishMission', finishMission)

RegisterNetEvent('qb-truckrobbery:server:RemoveItem', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	Player.Functions.RemoveItem(Config.StartItem, 1)
	TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[Config.StartItem], 'remove')
end)

RegisterNetEvent('onResourceStop', function()
	Peds:delete()
	Trucks:delete()
	Trucks:deleteGuard()
end)

RegisterNetEvent('onResourceStart', function()
	Peds:create(Config.StartPed.model, Config.StartPed.coords)
end)
