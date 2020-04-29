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
-- 1) respond GENERIC_ERROR to mobile when default timeout expired.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local resultCode = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for p in pairs(common.windowStatusData[1].location) do
  common.Title("Check " .. p .. " parameter from Grid structure")
  for k, v in pairs(common.invalidValue) do
    common.Step("HMI sends GetVehicleData response with invalid " .. p .. "=" .. tostring(k),
      common.sendGetVehicleData, { p, "location", v, resultCode })
  end
  common.Step("HMI sends GetVehicleData response with missing mandatory " .. p .. " parameter",
    common.sendGetVehicleData, { p, "location", nil, resultCode })
end

for p in pairs(common.windowStatusData[1].state) do
  common.Title("Check " .. p .. " parameter from WindowState structure")
  for k, v in pairs(common.invalidValue) do
    common.Step("HMI sends GetVehicleData response with invalid " .. p .. "=" .. tostring(k),
      common.sendGetVehicleData, { p, "state", v, resultCode })
  end
  common.Step("HMI sends GetVehicleData response with missing mandatory " .. p .. " parameter",
    common.sendGetVehicleData, { p, "state", nil, resultCode })
end

common.Title("Check for other parameters")
for k, v in pairs(common.invalidParam) do
  common.Step("HMI sends GetVehicleData response with " .. k, common.getVehicleData, { v })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
