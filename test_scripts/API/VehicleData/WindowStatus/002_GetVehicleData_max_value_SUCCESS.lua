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
-- 1) process this response and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local value = 100

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
for k in pairs(common.windowStatusData[1].state) do
  common.Step("Send GetVehicleData param " .. k .. "=" .. tostring(100), common.sendGetVehicleData, { k, "state", value })
end

for k in pairs(common.windowStatusData[1].location) do
  common.Step("Send GetVehicleData param " .. k .. "=" .. tostring(100), common.sendGetVehicleData, { k, "location", value })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
