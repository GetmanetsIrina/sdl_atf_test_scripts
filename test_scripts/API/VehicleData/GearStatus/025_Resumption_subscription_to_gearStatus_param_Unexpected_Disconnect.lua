---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL resumes the subscription for 'gearStatus' after unexpected disconnect/connect.
--
-- In case:
-- 1) App is subscribed to `gearStatus` data.
-- 2) Unexpected disconnect and reconnect are performed.
-- 3) App registers with actual HashId.
-- SDL does:
--  a) send VehicleInfo.SubscribeVehicleData(gearStatus=true) request to HMI during resumption.
-- 4) HMI sends VehicleInfo.SubscribeVehicleData response to SDL.
-- SDL does:
--  a) not send SubscribeVehicleData response to mobile app
-- 5) HMI sends valid OnVehicleData notification with all parameters of `gearStatus` structure.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local appId = 1
local isSubscribed = true

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to gearStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App with data resumption", common.registerAppWithResumption, { appId, common.checkResumption_FULL, isSubscribed })
common.Step("OnVehicleData with gearStatus data", common.sendOnVehicleData, { common.gearStatusData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
