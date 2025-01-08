local QBCore = exports['qb-core']:GetCoreObject()
local onCooldown = false
local Peds = {}
local Trucks = {}
local Timeout = {}
local TruckCoords = Config.Truck.spawnlocations[math.random(1, #Config.Truck.spawnlocations)]

RegisterServerEvent('AttackTransport:akceptujto', function()
	local copsOnDuty = 0
	local _source = source
	local xPlayer = QBCore.Functions.GetPlayer(_source)
	local accountMoney = xPlayer.PlayerData.money['bank']
	if ActiveMission == 0 then
		if accountMoney < Config.ActivationCost then
			TriggerClientEvent('QBCore:Notify', _source, 'You need ' .. Config.Currency .. '' .. Config.ActivationCost .. ' in the bank to accept the mission')
		else
			for _, v in pairs(QBCore.Functions.GetPlayers()) do
				local Player = QBCore.Functions.GetPlayer(v)
				if Player ~= nil then
					if (Player.PlayerData.job.name == 'police' or Player.PlayerData.job.type == 'leo') and Player.PlayerData.job.onduty then
						copsOnDuty = copsOnDuty + 1
					end
				end
			end
			if copsOnDuty >= Config.ActivePolice then
				TriggerClientEvent('AttackTransport:Pozwolwykonac', _source)
				xPlayer.Functions.RemoveMoney('bank', Config.ActivationCost, 'armored-truck')
				OdpalTimer()
			else
				TriggerClientEvent('QBCore:Notify', _source, 'Need at least ' .. Config.ActivePolice .. ' police to activate the mission.')
			end
		end
	else
		TriggerClientEvent('QBCore:Notify', _source, 'Someone is already carrying out this mission')
	end
end)

RegisterServerEvent('qb-armoredtruckheist:server:callCops', function(streetLabel, coords)
	-- local place = "Armored Truck"
	-- local msg = "The Alarm has been activated from a "..place.. " at " ..streetLabel
	-- Why is this unused?
	TriggerClientEvent('qb-armoredtruckheist:client:robberyCall', -1, streetLabel, coords)
end)

function OdpalTimer()
	ActiveMission = 1
	Wait(Config.ResetTimer * 1000)
	ActiveMission = 0
	TriggerClientEvent('AttackTransport:CleanUp', -1)
end

RegisterServerEvent('AttackTransport:zawiadompsy', function(x, y, z)
	TriggerClientEvent('AttackTransport:InfoForLspd', -1, x, y, z)
end)

RegisterServerEvent('AttackTransport:graczZrobilnapad', function()
	local _source = source
	local xPlayer = QBCore.Functions.GetPlayer(_source)
	local bags = math.random(1, 3)
	local info = {
		worth = math.random(Config.Payout.Min, Config.Payout.Max)
	}
	exports['qb-inventory']:AddItem(_source, 'markedbills', bags, false, info, 'AttackTransport:graczZrobilnapad')
	TriggerClientEvent('qb-inventory:client:ItemBox', _source, QBCore.Shared.Items['markedbills'], 'add')

	local chance = math.random(1, 100)
	TriggerClientEvent('QBCore:Notify', _source, 'You took ' .. bags .. ' bags of cash from the van')

	if chance >= 95 then
		exports['qb-inventory']:AddItem(_source, 'security_card_01', 1, false, false, 'AttackTransport:graczZrobilnapad')
		TriggerClientEvent('qb-inventory:client:ItemBox', _source, QBCore.Shared.Items['security_card_01'], 'add')
	end
end

-- Trucks
function Trucks.create(self, coords)
	local plate = 'ARMD' .. math.random(1000, 9999)
	self.truck = CreateVehicleServerSetter(Config.Truck.model, 'automobile', coords.x, coords.y, coords.z, coords.w)
	Entity(self.truck).state:set('truckState', TruckState.guarded, true)
	Trucks:blip()
	SetVehicleDirtLevel(self.truck, 0.0)
	SetVehicleNumberPlateText(self.truck, plate)
	Wait(500)
end

function Trucks.blip(self, coords)
	coords = TruckCoords
	self.blip = AddBlipForCoord(coords.x, coords.y, coords.z)
	SetBlipSprite(self.blip, 67)
	return self.blip
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
	Trucks:create(TruckCoords)
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
	finishMission()
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
