---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes OnVehicleData notification with new 'handsOffSteering' parameter for two Apps
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) OnVehicleData notification and handsOffSteering is allowed by policies
-- 3) App_1 is registered and subscribed on handsOffSteering parameter
-- 4) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App_1
-- 5) App_2 is registered and subscribed on handsOffSteering parameter
-- 6) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App_1 and App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { appId_1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App_1",
common.processSubscriptionRPCsSuccess, { rpc_sub, appId_1, isExpectedSubscribeVDonHMI })

common.Title("Test")
for _, v in pairs(value) do
  common.Step("HMI sends OnVehicleData notification with handsOffSteering " .. tostring(v), common.onVehicleData, { v })
end
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App_2",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_2, notExpectedSubscribeVDonHMI })
for _, v in pairs(value) do
  common.Step("HMI sends OnVehicleData notification with handsOffSteering parameter for two Apps" .. tostring(v),
    common.onVehicleDataForTwoApps, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
