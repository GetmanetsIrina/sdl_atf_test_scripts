---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL doesn't transfer OnVehicleData notification with new 'handsOffSteering' parameter to App
-- if an app not subscribed on 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) OnVehicleData notification and handsOffSteering is allowed by policies
-- 3) App is registered
-- 4) App is subscribed on handsOffSteering parameter
-- 5) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App
-- 6) App is unsubscribed on handsOffSteering parameter
-- 7) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) not transfer this notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local pExpTimes = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })
for _, v in pairs(value) do
  common.Step("Check that SDL does transfer OnVehicleData notification with handsOffSteering to App " .. tostring(v),
    common.onVehicleData, { v })
end

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter",
  common.processSubscriptionRPCsSuccess, { rpc_unsub })
for _, v in pairs(value) do
  common.Step("Check that SDL doesn't transfer OnVehicleData notification with handsOffSteering to App " .. tostring(v),
  common.onVehicleData, { v, pExpTimes })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
