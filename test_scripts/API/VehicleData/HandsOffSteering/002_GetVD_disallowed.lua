---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0257-New-vehicle-data-HandsOffSteering.md
--
-- Description: Check that SDL rejects GetVehicleDate request with resultCode: "DISALLOWED" if 'handsOffSteering'
-- parameter is not allowed by policy
--
-- Preconditions:
-- 1) Update preloaded_pt file, add handsOffSteering parameter to VD_RPC group
-- 2) 'handsOffSteering' parameter is Not allowed by policies
-- 3) App is registered
-- 4) App sends valid GetVehicleData(handsOffSteering=true) request to SDL
-- SDL does:
-- - a) send GetVehicleData response with (success = false, resultCode = DISALLOWED") to App
-- - b) not transfer this request to HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/HandsOffSteering/common')

-- [[ Local Variables ]]
local rpc = "GetVehicleData"
local resultCode = "DISALLOWED"
local VDGroup = {
  rpcs = {
    GetVehicleData = {
      hmi_levels = { "NONE", "BACKGROUND", "LIMITED", "FULL" },
      parameters = common.EMPTY_ARRAY
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment and update preloaded_pt file", common.preconditions, { VDGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerAppWOPTU)

common.Title("Test")
common.Step("RPC GetVehicleData DISALLOWED", common.processRPCUnsuccessRequest, { rpc, true, resultCode })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
