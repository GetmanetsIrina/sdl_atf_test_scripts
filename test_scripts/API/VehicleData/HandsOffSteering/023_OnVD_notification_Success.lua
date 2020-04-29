---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes OnVehicleData notification with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) OnVehicleData notification is allowed by policies
-- 3) App is registered
-- 4) App is subscribed on handsOffSteering parameter
-- Steps:
-- 1) HMI sends valid VehicleInfo.OnVehicleData notification to SDL
-- SDL does:
-- - a) transfer this notification to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variables ]]
local value = { true, false }
local rpc_sub = "SubscribeVehicleData"

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.precondition)
common.Step("Update preloaded file", common.updatedPreloadedPTFile)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)
common.Step("RPC " .. rpc_sub .. " on handsOffSteering parameter", common.processRPCSuccess, { rpc_sub })

common.Title("Test")
for _, v in pairs(value) do
  common.Step("HMI sends OnVehicleData notification with handsOffSteering " .. tostring(v), common.onVehicleData, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postcondition)
