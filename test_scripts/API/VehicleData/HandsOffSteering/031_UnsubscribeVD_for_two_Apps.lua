---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes UnsubscribeVehicleData RPC for two Apps with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC UnsubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App_1 and App_2 are registered and Subscribed on handsOffSteering parameter
-- 4) App_1 sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App_1
-- - b) send OnHashChange notification to App_1
-- - c) not transfer this request to HMI
-- 5) App_2 sends valid UnsubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 6) HMI sends VehicleInfo.UnsubscribeVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = true, resultCode = SUCCESS",
-- handsOffSteering = <data received from HMI>) to App_2
-- - b) send OnHashChange notification to App_2
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local appId_1 = 1
local appId_2 = 2

--[[ Local Function ]]
local function processSubscriptionRPCsSuccess(pRpcName, pAppId)
  local handsOffSteeringResponseData = {
    dataType = "VEHICLEDATA_HANDSOFFSTEERING",
    resultCode = "SUCCESS"
  }
  local cid = common.getMobileSession(pAppId):SendRPC(pRpcName, { handsOffSteering = true })
  common.getMobileSession(pAppId):ExpectResponse(cid,
    { success = true, resultCode = "SUCCESS", handsOffSteering = handsOffSteeringResponseData })
    common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App_1", common.registerAppWOPTU, { appId_1 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_1",
  common.processSubscriptionRPCsSuccess, { rpc_sub, appId_1 })
common.Step("Register App_2", common.registerAppWOPTU, { appId_2 })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter for App_2",
  processSubscriptionRPCsSuccess, { rpc_sub, appId_2 })

common.Title("Test")
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter for App_1",
  common.processRPCForSecondApp, { rpc_unsub, appId_1 })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter for App_2",
  common.processSubscriptionRPCsSuccess, { rpc_unsub, appId_2 })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
