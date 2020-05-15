---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects GetVD, SubscribeVD, UnsubscribeVD RPCs with new 'handsOffSteering'
-- parameter if an app registered with version less than current version
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPCs GetVD, SubscribeVD, UnsubscribeVD and handsOffSteering is allowed by policies
-- 3) App is registered with syncMsgVersion = 5.0
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
common.getParams().syncMsgVersion.majorVersion = 5
common.getParams().syncMsgVersion.minorVersion = 0

--[[ Local Variables ]]
local rpc_get = "GetVehicleData"
local rpc_sub = "SubscribeVehicleData"
local rpc_unsub = "UnsubscribeVehicleData"
local resultCode = "INVALID_DATA"
local valueVD = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData, handsOffSteering",
  common.processRPCUnsuccessRequest, { rpc_get, valueVD, resultCode })
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter",
  common.processRPCUnsuccessRequest, { rpc_sub, valueVD, resultCode })
common.Step("RPC " .. rpc_unsub .. " on handsOffSteering parameter",
  common.processRPCUnsuccessRequest, { rpc_unsub, valueVD, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
