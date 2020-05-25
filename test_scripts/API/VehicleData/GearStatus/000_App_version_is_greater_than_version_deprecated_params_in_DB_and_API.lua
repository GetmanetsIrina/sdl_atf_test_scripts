---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL successfully processes Get/Subscribe/On/UnsubscribeVehicleData with deprecated `prndl` param in case
-- app version is greater than parameters version from API.
--
-- Preconditions:
-- 1) App is registered with syncMsgVersion=7.0
-- 2) `prndl` is deprecated since=6.2 in API and DB
-- In case:
-- 1) App requests Get/Sub/UnsubVehicleData with prndl=true.
-- 2) HMI sends valid OnVehicleData notification with all parameters of `prndl` structure.
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
common.Step("GetVehicleData for prndl", common.getVehicleData, { common.prndlData, "prndl" })
common.Step("App subscribes to prndl data", common.processSubscriptionRPC, { "SubscribeVehicleData", "prndl" })
common.Step("OnVehicleData with prndl data", common.sendOnVehicleData, { common.prndlData, _, "prndl" })
common.Step("App unsubscribes from prndl data", common.processSubscriptionRPC, { "UnsubscribeVehicleData", "prndl" })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
