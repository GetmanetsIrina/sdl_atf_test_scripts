---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL successfully processes GetVehicleData with new `windowStatus` param.
--
-- In case:
-- 1) App sends GetVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- SDL does:
--  a) transfer this request to HMI.
-- 2) HMI sends GetVehicleData response with all params of structure `windowStatus`.
-- SDL does:
--  a) send GetVehicleData response to mobile with all parameters in `windowStatus` structure.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local windowStatusData = {
  {
    location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for windowStatus", common.getVehicleData, { windowStatusData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
