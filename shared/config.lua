QBCore = exports['qb-core']:GetCoreObject()

Config = Config or {}

Config.StartPed = {
  model = `MP_M_SecuroGuard_01`,
  coords = vector4(2.91, -713.55, 32.48, 337.56),
}

Config.StartItem = 'thermite' --Item needed to start the job

Config.Truck = {
  model = `stockade`,
  spawnlocations = {
    vector4(-9.6, -727.25, 32.29, 158.25),
    vector4(-1327.77, -90.02, 49.45, 359.51),
    vector4(-2029.88, -260.35, 23.39, 109.32),
    vector4(-896.9, -1532.81, 5.02, 96.55),
    vector4(799.16, -1773.82, 29.32, 226.91)
  }
}

Config.Guards = {
  number = 6,
  model = `MP_M_SecuroGuard_01`,
  weapon = 'weapon_pistol',
}

Config.PoliceAlert = function()
  TriggerServerEvent('police:server:policeAlert', Lang:t('info.palert'))
  -- Add blip
end

Config.Minigames = {
  ['Unlock Doors'] = function()
    local success = exports['qb-minigames']:Skillbar() -- calling like this will set difficulty and keys to press
    if success then
      return true
    else
      return false
    end
  end
}

Config.Route = { -- Locations the truck should go to and stop at.
  vector3(151.17, -1027.81, 29.28),
  vector3(317.31, -266.13, 53.85),
  vector3(-344.33, -30.7, 47.42),
  vector3(-1219.89, -317.63, 37.56)
}


Config.Times = { -- Times in seconds.
  plant = 5,
  fuse = 5,
  loot = 10,
  cooldown = 1800,
  issuedRewardsTimer = 30
}

Config.Rewards = {
  cash  = math.random(1000, 2000),
  items = { --Quantity of items
    ['markedbills'] = math.random(5000, 10000)
  }
}
