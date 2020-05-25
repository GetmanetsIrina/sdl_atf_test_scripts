---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0266-New-vehicle-data-GearStatus.md
--
-- Description: SDL resumes the subscription for 'gearStatus' parameter for two Apps after IGN_OFF/ON.
--
-- Precondition:
-- 1) Two apps are registered and activated.
-- 2) Apps are subscribed to `gearStatus` data.
-- 3) IGN_OFF/IGN_ON are performed.
-- In case:
-- 1) Mobile app1 and app2 register with actual hashID.
-- SDL does:
--  a) start data resumption for both apps.
--  b) resume the subscription and sends VI.SubscribeVD request to HMI.
--  c) after success response from HMI SDL resumes the subscription.
-- 2) HMI sends OnVD notification with subscribed VD.
-- SDL does:
--  a) resend OnVD notification to appropriate mobile apps.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/VehicleData/GearStatus/common')

--[[ Local Variables ]]
local appId1 = 1
local appId2 = 2
local isExpectedSubscribeVDonHMI = true
local notExpectedSubscribeVDonHMI = false
local isSubscribed = true
local notSubscribed = false

--[[ Local Function ]]
local function OnVehicleData2Apps(pData)
  common.sendOnVehicleData(pData)
  common.getMobileSession(appId2):ExpectNotification("OnVehicleData", { gearStatus = pData })
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App1", common.registerAppWOPTU)
common.Step("Register App2", common.registerAppWOPTU, { appId2 })
common.Step("Activate App1", common.activateApp)
common.Step("Activate App2", common.activateApp, { appId2 })
common.Step("App1 subscribes to gearStatus data", common.processSubscriptionRPC, { "SubscribeVehicleData", _, _, isExpectedSubscribeVDonHMI })
common.Step("App2 subscribes to gearStatus data", common.processSubscriptionRPC, { "SubscribeVehicleData", _, _, notExpectedSubscribeVDonHMI, appId2 })
common.Step("Ignition Off", common.ignitionOff)
common.Step("Ignition On", common.start)

common.Title("Test")
common.Step("Re-register App1 with data resumption", common.registerAppWithResumption, { appId1, isSubscribed })
common.Step("Re-register App2 with data resumption", common.registerAppWithResumption, { appId2, notSubscribed })
common.Step("OnVehicleData with gearStatus data", OnVehicleData2Apps, { common.getGearStatusParams() })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
