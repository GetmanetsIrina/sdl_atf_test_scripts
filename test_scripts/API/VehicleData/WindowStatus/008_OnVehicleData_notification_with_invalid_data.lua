---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL does not transfer OnVehicleData notification to subscribed app if HMI sends notification
-- with invalid values of `windowStatus` structure params:
--    location: { col, row, level, colspan, rowspan, levelspan }
--    state: { approximatePosition, deviation }
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) HMI sends the invalid `windowStatus` structure in OnVehicleData notification:
--    - invalid parameter name
--    - invalid parameter type
--    - missing mandatory parameter
--    - params out of bounds
--    - empty value
-- SDL does:
-- 1) ignore this notification.
-- 2) not send OnVehicleData notification to mobile.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local expTime = 0

--[[ Local Function ]]
local function sendOnVehicleData( pParam, pData, pValue)
  local params = common.windowStatusData
  params[1][pData][pParam] = pValue

  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { windowStatus = params })
  common.getMobileSession():ExpectNotification("OnVehicleData", { windowStatus = params })
  :Times(0)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
for param in pairs(common.windowStatusData[1].location) do
  common.Title("HMI sends with invalid `windowStatus` structure for " .. param)
  for k, v in pairs(common.invalidValue) do
    common.Step("OnVehicleData with invalid value for " .. param .. "=" .. tostring(k),
      sendOnVehicleData, { param, "location", v })
  end
  common.Step("OnVehicleData with missing mandatory " .. param .. " parameter", sendOnVehicleData, { param, "location", nil })
end

for param in pairs(common.windowStatusData[1].state) do
  common.Title("HMI sends with invalid `windowStatus` structure for " .. param)
  for k, v in pairs(common.invalidValue) do
    common.Step("OnVehicleData with invalid value for " .. param .. "=" .. tostring(k),
      sendOnVehicleData, { param, "state", v })
  end
  common.Step("OnVehicleData with missing mandatory " .. param .. " parameter", sendOnVehicleData, { param, "state", nil })
end

common.Title("Check for other parameters")
for k, v in pairs(common.invalidParam) do
  common.Step("OnVehicleData with " .. k, common.sendOnVehicleData, { v, expTime })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
