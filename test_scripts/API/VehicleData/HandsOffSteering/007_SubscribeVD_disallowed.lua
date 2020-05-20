---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects SubscribeVehicleData request with resultCode "DISALLOWED" if 'handsOffSteering'
-- parameter is not allowed by policy
--
-- Preconditions:
-- 1) Update preloaded_pt file, add permissions for SubscribeVehicleData RPC
-- 2) 'handsOffSteering' parameter is Not allowed by policies
-- 3) App is registered
--
-- In case:
-- 1) App sends valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
-- - c) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local handsOffSteeringValue = true
local resultCode = { success = false, resultCode = "DISALLOWED" }
local VDGroup = {
  rpcs = {
    SubscribeVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = { "gps" }
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC " .. rpc .. " with handsOffSteering parameter DISALLOWED",
  common.processRPCUnsuccessRequest, { rpc, handsOffSteeringValue, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
