---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL restores the subscription to 'handsOffSteering' parameter after IGN_OFF/IGN_ON
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC SubscribeVehicleData and handsOffSteering is allowed by policies
-- 3) App is registered and subscribed on handsOffSteering VD
-- 4) IGN_OFF and IGN_ON are performed
-- 5) App re-registers with actual HashId
-- SDL does:
-- - a) send VehicleInfo.SubscribeVehicleData request to HMI during resumption
-- - b) process successful response from HMI
-- - c) respond RAI(SUCCESS) to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local rpc = "SubscribeVehicleData"
local appId = 1
local onVDValue = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc .. " on handsOffSteering parameter", common.processSubscriptionRPCsSuccess, { rpc })

common.Title("Test")
common.Step("IGNITION_OFF", common.ignitionOff)
common.Step("IGNITION_ON", common.start)
common.Step("Re-register App resumption data", common.registerAppSuccessWithResumption, { appId, true })
common.Step("Check resumption data OnVehicleData notification", common.onVehicleData, { onVDValue })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
