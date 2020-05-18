---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL resumes the subscription for 'windowStatus' after unexpected disconnect/connect.
--
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) Unexpected disconnect and reconnect are performed.
-- 3) App re-registered with actual HashId.
-- SDL does:
--  a) send VehicleInfo.SubscribeVehicleData(windowStatus=true) request to HMI.
-- 4) HMI sends VehicleInfo.SubscribeVehicleData response to SDL.
-- SDL does:
--  a) not send SubscribeVehicleData response to mobile app
-- 5) HMI sends valid OnVehicleData notification with all parameters of `windowStatus` structure.
-- SDL does:
--  a) process this notification and transfer it to mobile app.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local appId = 1
local isSubscribed = true

local windowStatusData = {
  {
    location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)
common.Step("Re-register App resumption data", common.registerAppWithResumption, { appId, isSubscribed })
common.Step("OnVehicleData with windowStatus data", common.sendOnVehicleData, { windowStatusData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
