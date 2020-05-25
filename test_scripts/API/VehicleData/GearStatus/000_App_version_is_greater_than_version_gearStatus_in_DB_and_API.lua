---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successfully processes Get/Sub/Unsub/VehicleData requests with new 'gearStatus' parameter in case
-- App is registered with syncMsgVersion is greater than 6.2
--
-- Preconditions:
-- 1) App is registered with syncMsgVersion=7.0
-- 2) New param s`gearStatus` has since=6.2 in DB and API.
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with gearStatus=true.
-- 2) HMI sends valid OnVehicleData notification with all parameters of `gearStatus` structure.
-- SDL does:
--  a) process the requests successful.
--  b) process the OnVehicleData notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

-- [[ Test Configuration ]]
common.getAppParams().syncMsgVersion.majorVersion = 7
common.getAppParams().syncMsgVersion.minorVersion = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)

common.Title("Test")
common.Step("GetVehicleData for gearStatus", common.getVehicleData, { common.getGearStatusParams() })
common.Step("App subscribes to gearStatus data", common.processSubscriptionRPC, { "SubscribeVehicleData" })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.getGearStatusParams() })
common.Step("App unsubscribes from gearStatus data", common.processSubscriptionRPC, { "UnsubscribeVehicleData" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
