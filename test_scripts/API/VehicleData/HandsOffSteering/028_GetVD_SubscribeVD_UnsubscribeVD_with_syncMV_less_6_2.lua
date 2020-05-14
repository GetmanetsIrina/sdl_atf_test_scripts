---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects GetVD, SubscribeVD, UnsubscribeVD RPCs with new 'handsOffSteering'
-- parameter if an app registered with version less than 6.2 version
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPCs GetVD, SubscribeVD, UnsubscribeVD and handsOffSteering is allowed by policies
-- 3) App is registered with syncMsgVersion = 6.0
-- 4) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = INVALID_DATA") to App
-- - b) not transfer this request to HMI
-- 5) App send valid SubscribeVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send SubscribeVehicleData response with (success = false, resultCode = INVALID_DATA") to App
-- - b) not transfer this request to HMI
-- 6) App send valid UnsubscribeVehicleData request to SDL
-- SDL does:
-- - a) send UnsubscribeVehicleData response with (success = false, resultCode = INVALID_DATA") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Test Configuration ]]
common.getParams().syncMsgVersion.majorVersion = 6
common.getParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"

--[[ Local Functions ]]
local function getVDInvalidData()
  local cid = common.getMobileSession():SendRPC("GetVehicleData", { handsOffSteering = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo.GetVehicleData") :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
end

local function processRPCInvalidData(pRpcName)
  local cid = common.getMobileSession():SendRPC(pRpcName, { handsOffSteering = true })
  common.getHMIConnection():ExpectRequest("VehicleInfo" .. pRpcName) :Times(0)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "INVALID_DATA" })
  common.getMobileSession():ExpectNotification("OnHashChange") :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.precondition)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, handsOffSteering", getVDInvalidData)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", processRPCInvalidData, { rpc_sub })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter", processRPCInvalidData, { rpc_unsub })

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
