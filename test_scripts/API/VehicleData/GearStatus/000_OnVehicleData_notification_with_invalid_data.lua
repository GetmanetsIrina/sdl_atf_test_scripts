-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL does not transfer OnVehicleData notification to subscribed app if HMI sends notification with
-- invalid values of `gearStatus` structure params: userSelectedGear, actualGear, transmissionType.
--
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) HMI sends the invalid `gearStatus` structure in OnVehicleData notification:
--  1) invalid parameter name
--  2) invalid parameter type
--  3) empty value
--  4) empty structure
-- SDL does:
--  a) ignore this notification.
--  b) not send OnVehicleData notification to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local notExpected = 0
local emptyStructure = {}

local invalidValue = {
  emptyValue = "",
  invalidType = 12345,
  invalidParamValue = "Invalid parameter value"
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { "SubscribeVehicleData" })

common.Title("Test")
for p in pairs(common.getGearStatusParams()) do
  common.Title("Check for " .. p .. " parameter")
  for k, v in pairs(invalidValue) do
    common.Step("OnVehicleData notification with " ..k .. " for ".. p, common.sendOnVehicleData, { common.setValue(p,v), notExpected})
  end
end
common.Step("OnVehicleData with empty gearStatus structure", common.sendOnVehicleData, { emptyStructure, notExpected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
