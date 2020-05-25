---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL transfers OnVehicleData notification to app if HMI sends it with only one param in `gearStatus` structure.
--
-- Preconditions:
-- 1) App is subscribed to `gearStatus` data.
-- In case:
-- 1) HMI sends valid OnVehicleData notification with only one param of `gearStatus` structure.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Functions ]]
local function sendOnVehicleData(pData)
  common.getHMIConnection():SendNotification("VehicleInfo.OnVehicleData", { gearStatus = pData })
  common.getMobileSession():ExpectNotification("OnVehicleData", { gearStatus = pData })
  :ValidIf(function(_, data)
    return common.checkParam(data, "OnVehicleData")
  end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { "SubscribeVehicleData" })

common.Title("Test")
for k,v in pairs(common.getGearStatusParams()) do
  common.Step("OnVehicleData with one param " .. k, sendOnVehicleData, { { [k] = v } })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
