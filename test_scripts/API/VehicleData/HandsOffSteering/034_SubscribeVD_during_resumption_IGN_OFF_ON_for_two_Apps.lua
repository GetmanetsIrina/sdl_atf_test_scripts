---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL restored SubscribeVehicleData on 'handsOffSteering' parameter after IGN_OFF/IGN_ON cycle
-- for two Apps
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App_1 and App_2 are registered and subscribed on handsOffSteering VD
-- 4) IGN_OFF/IGN_ON cycle is performed
-- 5) App_1 re-registers with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) process successful response from HMI
-- - c) respond RAI(SUCCESS) to mobile app
-- 6) App_2 re-registers with actual HashId
-- SDL does:
-- - a) not send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local onVDValue = true
local appId_1 = 1
local appId_2 = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false
local isHMISubscription = true
local notHMISubscription = false

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { appId_1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App_1",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_1, isExpectedSubscribeVDonHMI })
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter App_2",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_2, notExpectedSubscribeVDonHMI })

common.Title("Test")
common.Step("IGNITION_OFF", common.ignitionOff)
common.Step("IGNITION_ON", common.start)
common.Step("Re-register App_1 resumption data",
  common.registerAppSuccessWithResumption, { appId_1, isHMISubscription })
common.Step("Check resumption data OnVehicleData notification", common.onVehicleData, { onVDValue })
common.Step("Re-register App_2 resumption data",
  common.registerAppSuccessWithResumption, { appId_2, notHMISubscription })
common.Step("Check resumption data OnVehicleData notification with handsOffSteering parameter for two Apps",
  common.onVehicleDataForTwoApps, { onVDValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
