---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL responds with resultCode INVALID_DATA to GetVehicleDate request if App sends request with
-- invalid data
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered
-- 4) App sends invalid GetVehicleData(handsOffSteering=123) request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = INVALID_DATA") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc = "GetVehicleData"
local resultCode = "INVALID_DATA"
local invalidData = 123

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, App with invalid request",
  common.processRPCUnsuccessRequest, { rpc, invalidData, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
