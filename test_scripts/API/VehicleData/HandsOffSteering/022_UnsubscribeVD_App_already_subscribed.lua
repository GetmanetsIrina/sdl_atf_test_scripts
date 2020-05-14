---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL receive DATA_NOT_SUBSCRIBED to UnsubscribeVehicleData request if App already unsubscribed
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and UnsubscribeVehicleData are allowed by policies
-- 3) App is registered and subscribed on handsOffSteering VD
-- 4) App is unsubscribed
-- 5) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = DATA_NOT_SUBSCRIBED") to App
-- - b) not send OnHashChange notification to App
-- - c) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local resultCode = "DATA_NOT_SUBSCRIBED"
local onVDValue = true
local pExpTimes = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter",
  common.processSubscriptionRPCsSuccess, { rpc_unsub })

common.Title("Test")
common.Step("App sends RPC " .. rpc_unsub .. " on already unsubscribed parameter",
  common.appAlreadySubUnsubscribed, { rpc_unsub, resultCode })
common.Step("Check that App is unsubscribed", common.onVehicleData, { onVDValue, pExpTimes })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
