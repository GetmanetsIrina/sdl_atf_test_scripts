---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL responds with resultCode INVALID_DATA to UnsubscribeVehicleData request if App sends
-- request with invalid data
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC UnsubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered and subscribed on handsOffSteering parameter
-- 4) App sends invalid UnsubscribeVehicleData(handsOffSteering=123) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = INVALID_DATA") to App
-- - b) not send OnHashChange notification to App
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local resultCode = "INVALID_DATA"
local invalidData = 123

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })

common.Title("Test")
common.Step("RPC UnsubscribeVehicleData, App sends invalid request",
  common.processRPCUnsuccessRequest, { rpc_unsub, invalidData, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
