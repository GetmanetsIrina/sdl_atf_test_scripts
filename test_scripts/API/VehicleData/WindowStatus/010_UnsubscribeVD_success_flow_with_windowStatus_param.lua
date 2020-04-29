---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL successful processes UnsubscribeVehicleData RPC with `windowStatus` param.
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) App sends UnsubscribeVehicleData request with windowStatus=true to the SDL and this request is allowed by Policies.
-- 3) HMI responds with SUCCESS result to UnsubscribeVehicleData request.
-- SDL does:
-- 1) transfer this requests to HMI.
-- 2) respond with resultCode:"SUCCESS" to mobile application for `windowStatus` param.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local expected = 0

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("App unsubscribes to windowStatus data", common.subUnScribeVD, { "UnsubscribeVehicleData" })
common.Step("Send OnVehicleData with windowStatus data", common.sendOnVehicleData, { common.windowStatusData, expected })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
