---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes GetVD, SubscribeVD, UnsubscribeVD, OnVD RPCs with new 'handsOffSteering'
-- parameter if an app registered with version large than 6.2 version
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPCs GetVD, SubscribeVD, UnsubscribeVD, OnVD and handsOffSteering is allowed by policies
-- 3) App is registered with syncMsgVersion = 7.3
-- 4) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI sends VehicleInfo.GetVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = SUCCESS") to App
-- 6) App send valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 7) HMI sends VehicleInfo.SubscribeVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App
-- - b) send OnHashChange notification to App
-- 8) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App
-- 9) App sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 10) HMI sends VehicleInfo.UnsubscribeVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App
-- - b) send OnHashChange notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Test Configuration ]]
common.getParams().syncMsgVersion.majorVersion = 7
common.getParams().syncMsgVersion.minorVersion = 3

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local onVDValue = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, handsOffSteering", common.getVehicleData, { true })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc_sub })
common.Step("HMI sends OnVehicleData notification with handsOffSteering", common.onVehicleData, { onVDValue })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter",
  common.processSubscriptionRPCsSuccess, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
