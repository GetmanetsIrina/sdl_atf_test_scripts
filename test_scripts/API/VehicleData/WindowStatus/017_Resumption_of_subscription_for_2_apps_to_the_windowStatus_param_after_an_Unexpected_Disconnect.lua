---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
--
-- Description: Check that SDL resumes the subscription for 'windowStatus' parameter for two Apps after unexpected disconnect/connect.
--
-- Precondition:
-- 1) Two apps are registered and activated.
-- 2) Apps are subscribed to `windowStatus` data.
-- 3) Unexpected disconnect and reconnect are performed.
-- In case:
-- 1) Mobile app1 and app2 register with actual hashID
-- SDL does:
--  a) start data resumption for both apps
--  b) resume the subscription and sends VI.SubscribeVD request to HMI
--  c) after success response from HMI SDL resumes the subscription
-- 2) HMI sends OnVD notification with subscribed VD
-- SDL does:
--  a) resend OnVD notification to appropriate mobile apps.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false
local isSubscribed = true
local notSubscribed = false

local windowStatusData = {
  {
    location = { col = 0, row = 0, level = 0, colspan = 1, rowspan = 1, levelspan = 1 },
    state = {
      approximatePosition = 50,
      deviation = 50
    }
  }
}

--[[ Local Function ]]
local function OnVehicleData2Apps(pData)
	common.sendOnVehicleData(pData)
	common.getMobileSession(appId2):ExpectNotification("OnVehicleData", { windowStatus = pData })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App1", common.registerAppWOPTU)
common.Step("Register App2", common.registerAppWOPTU, { appId2 })
common.Step("Activate App1", common.activateApp)
common.Step("Activate App2", common.activateApp, { appId2 })
common.Step("App1 subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData", isExpectedSubscribeVDonHMI })
common.Step("App2 subscribes to windowStatus data", common.subUnScribeVD, { "SubscribeVehicleData", notExpectedSubscribeVDonHMI, appId2 })
common.Step("Unexpected disconnect", common.unexpectedDisconnect)
common.Step("Connect mobile", common.connectMobile)

common.Title("Test")
common.Step("Re-register App1 resumption data", common.registerAppWithResumption, { appId1, isSubscribed })
common.Step("Re-register App2 resumption data", common.registerAppWithResumption, { appId2, notSubscribed })
-- common.Step("Activate App1", common.activateApp)
common.Step("OnVehicleData with windowStatus data", OnVehicleData2Apps, { windowStatusData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
