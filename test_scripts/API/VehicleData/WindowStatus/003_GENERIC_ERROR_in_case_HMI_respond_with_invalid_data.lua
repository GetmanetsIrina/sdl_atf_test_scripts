---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL sends response `GENERIC_ERROR` to mobile app if HMI sends response with invalid `windowStatus` structure:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
-- In case:
-- 1) App sends GetVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- 2) SDL transfers this request to HMI.
-- 3) HMI sends the invalid `windowStatus` structure in GetVehicleData response:
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
--    - params out of bounds
--    - empty value
-- SDL does:
--  a) respond GENERIC_ERROR to mobile when default timeout is expired.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local windowStatusData = {
  {
    location = { col = 49, row = 49 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

local invalidValue = {
  emptyValue = "",
  invalidType = true,
  beyondMax = 101
}


local resultCode = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for p in pairs(windowStatusData[1].location) do
  common.Title("Check " .. p .. " parameter from Grid structure")
  for k, v in pairs(invalidValue) do
    common.Step("HMI sends GetVehicleData response with invalid " .. p .. "=" .. tostring(k),
      common.sendGetVehicleData, { p, "location", v, windowStatusData, resultCode })
  end
  common.Step("HMI sends GetVehicleData response with missing mandatory " .. p .. " parameter",
    common.sendGetVehicleData, { p, "location", nil, windowStatusData, resultCode })
end

for p in pairs(windowStatusData[1].state) do
  common.Title("Check " .. p .. " parameter from WindowState structure")
  for k, v in pairs(invalidValue) do
    common.Step("HMI sends GetVehicleData response with invalid " .. p .. "=" .. tostring(k),
      common.sendGetVehicleData, { p, "state", v, windowStatusData, resultCode })
  end
  common.Step("HMI sends GetVehicleData response with missing mandatory " .. p .. " parameter",
    common.sendGetVehicleData, { p, "state", nil, windowStatusData, resultCode })
end

common.Title("Check for other parameters")
for k, v in pairs(common.invalidParam) do
  common.Step("HMI sends GetVehicleData response with " .. k, common.getVehicleData, { v, resultCode })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
