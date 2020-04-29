---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL resumes the subscription for 'windowStatus' parameter for two Apps after IGN_OFF/ON cycle
-- Precondition:
-- 1) Apps are subscribed to `windowStatus` data.
-- 2) IGN_OFF/IGN_ON cycle is performed.
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
local common = require('test_scripts/API/VehicleData/WindowStatus/common')

--[[ Local Function ]]
local function subscribeVD(pFirstApp, pAppId)
  if not pAppId then pAppId = 1 end
  local cid = common.getMobileSession(pAppId):SendRPC("SubscribeVehicleData", { windowStatus = true })
  if pFirstApp then
    common.getHMIConnection():ExpectRequest("VehicleInfo.SubscribeVehicleData", { windowStatus = true })
    :Do(function(_,data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { windowStatus = common.subUnsubParams })
    end)
  end
  common.getMobileSession(pAppId):ExpectResponse(cid,
  { success = true, resultCode = "SUCCESS", windowStatus = common.subUnsubParams })

  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
    common.setHashId(data.payload.hashID, pAppId)
  end)
end

local function checkResumption_NONE()
  common.getMobileSession(1):ExpectNotification("OnHMIStatus",{ hmiLevel = "NONE" })
end

local function checkResumption_FULL()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession(2):ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE" },
    { hmiLevel = "FULL" })
  :Times(2)
end

local function OnInteriorVD2Apps(pData)
  common.sendOnVehicleData(pData)
  common.getMobileSession(2):ExpectNotification("OnVehicleData", { windowStatus = pData })
  :Times(1)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App1", common.registerAppWOPTU)
common.Step("Register App2", common.registerAppWOPTU, { 2 })
common.Step("Activate App1", common.activateApp)
common.Step("Activate App2", common.activateApp, { 2 })
common.Step("App1 subscribes to windowStatus data", subscribeVD, { true })
common.Step("App2 subscribes to windowStatus data", subscribeVD, { false, 2 })
common.Step("Ignition Off", common.ignitionOff)
common.Step("Ignition On", common.start)

common.Title("Test")
common.Step("Re-register App1 resumption data", common.registerWithResumption, { 1, checkResumption_NONE, true })
common.Step("Re-register App2 resumption data", common.registerWithResumption, { 2, checkResumption_FULL, false })
common.Step("Activate App1", common.activateApp)
common.Step("Send OnVehicleData with windowStatus data", OnInteriorVD2Apps, { common.windowStatusData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
