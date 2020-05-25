---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL rejects the request with `DISALLOWED` resultCode if app tries to get `gearStatus` vehicle data in
-- case `gearStatus` parameter does not exist in app assigned policies.
--
-- In case:
-- 1) `gearStatus` parameter does not exist in app assigned policies.
-- 2) App sends valid GetVehicleData request with gearStatus=true to the SDL.
-- SDL does:
--  a) not transfer this request to HMI.
--  b) send response GetVehicleData(success:false, resultCode:`DISALLOWED`) to the mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local rpc = "GetVehicleData"
local result = "DISALLOWED"
local preloadedFileUpdate = true
local vehicleDataGroup = {
    rpcs = {
      GetVehicleData = {
        hmi_levels = { "BACKGROUND", "FULL", "LIMITED" },
        parameters = { "gps" }
      }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions, { preloadedFileUpdate, vehicleDataGroup })
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for gearStatus data DISALLOWED", common.processRPCFailure, { rpc, result })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
