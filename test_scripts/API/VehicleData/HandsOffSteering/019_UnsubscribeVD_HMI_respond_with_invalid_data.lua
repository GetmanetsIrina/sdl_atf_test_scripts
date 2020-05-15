---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL responds with resultCode GENERIC_ERROR to UnsubscribeVehicleData request if HMI response
-- is invalid
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC UnsubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered and subscribed on handsOffSteering parameter
-- 4) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI response is invalid
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = GENERIC_ERROR") to App
-- - b) not send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local invalidData = 123

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })

common.Title("Test")
common.Step("RPC UnsubscribeVehicleData, HMI with invalid response",
  common.processRPCHMIInvalidResponse, { rpc_unsub, invalidData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
