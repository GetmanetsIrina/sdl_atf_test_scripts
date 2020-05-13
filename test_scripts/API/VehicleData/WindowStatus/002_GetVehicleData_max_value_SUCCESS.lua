---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL processes GetVehicleData if HMI responds with boundary values for params from `windowStatus` structure:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
-- In case:
-- 1) App sends GetVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- 2) SDL transfers this request to HMI.
-- 3) HMI sends GetVehicleData response with `windowStatus` structure with max value (100) for one of the parameters
-- of `Grid` and `WindowState` types.
-- SDL does:
--  a)  process this response and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local windowStatusData = {
  {
    location = { col = 49, row = 49, level = 49, colspan = 49, rowspan = 49, levelspan = 49 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

local boundaryValues = {
  maxvalue = 100,
  minvalue = -1
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for k in pairs(windowStatusData[1].state) do
  if windowStatusData[1].state then boundaryValues.minvalue = 0 end
  for key, value in pairs(boundaryValues) do
    common.Step("GetVehicleData param " .. k .. "=" .. key, common.sendGetVehicleData, { k, "state", value, windowStatusData })
  end
end

for k in pairs(windowStatusData[1].location) do
  if windowStatusData[1].location.colspan or
    windowStatusData[1].location.rowspan or
    windowStatusData[1].location.levelspan then boundaryValues.minvalue = 1
  end
  for key, value in pairs(boundaryValues) do
    common.Step("GetVehicleData param " .. k .. "=" .. key, common.sendGetVehicleData, { k, "location", value, windowStatusData })
  end
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
