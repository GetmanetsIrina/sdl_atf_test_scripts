---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL processes GetVehicleData RPC with new 'handsOffSteering' parameter
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) RPC GetVehicleData and handsOffSteering parameter is allowed by policies
-- 3) App is registered
-- 4) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) transfer this request to HMI
-- 5) HMI sends VehicleInfo.GetVehicleData response with handsOffSteering structure to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = true, resultCode = SUCCESS", handsOffSteering = <data received from
-- HMI>) to App
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

--[[ Local Variable ]]
local value = { true, false }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
for _, k in pairs(value) do
  common.Step("RPC GetVehicleData, handsOffSteering " .. tostring(k), common.getVehicleData, { k })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
