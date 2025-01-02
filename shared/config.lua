Config = {}

Config.target = true -- Use target system for vehicle push (disables TextUI)
Config.targetSystem = 'ox_target' -- Target System to use. ox_target, qtarget, qb-target
Config.Usebones = true -- Use bones for vehicle push
Config.PushKey = 38 -- Key to push vehicle
Config.TurnRightKey = 35 -- Keys to turn the vehicle while pushing it.
Config.TurnLeftKey = 34 -- Keys to turn the vehicle while pushing it.
Config.TextUI = true -- Use Text UI for vehicle push
Config.useOTSkills = false -- Use OT Skills for XP gain from pushing vehicles.
Config.maxReward = 0 -- Max amount of xp that can be gained from pushing a vehicle per push, make sure this is the same or less than what is set for strength in your OT_skills config.
Config.healthMin = 2000.0 -- Minimum health of vehicle to be able to push it.
Config.flipTime = 10000

Config.blacklist = {
    phantom = true,
    boxville = true,
    pounder = true
}
