---------------------------------------------------------------------------------------------------
-- Proposal:https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0261-New-vehicle-data-WindowStatus.md
-- Description: Check that SDL resumes the subscription for 'windowStatus' after IGN_OFF/ON cycle
-- In case:
-- 1) App is subscribed to `windowStatus` data.
-- 2) IGN_OFF/IGN_ON cycle is performed.
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

--[[ Local Function ]]
local function subscribeVD(pRPC, pAppId)
  if not pAppId then pAppId = 1 end
  common.getMobileSession(pAppId):ExpectNotification("OnHashChange")
  :Do(function(_, data)
      common.setHashId(data.payload.hashID, pAppId)
    end)
  common.subUnScribeVD(pRPC, pAppId)
end

local function checkResumption_FULL()
  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp", {})
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE" },
    { hmiLevel = "FULL" })
  :Times(2)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Update local PT", common.updatePreloadedPT)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("Register App", common.registerApp)
common.Step("Activate App", common.activateApp)
common.Step("App subscribes to windowStatus data", subscribeVD, { "SubscribeVehicleData" })

common.Title("Test")
common.Step("Ignition Off", common.ignitionOff)
common.Step("Ignition On", common.start)
common.Step("Re-register App resumption data", common.registerWithResumption, { 1, checkResumption_FULL, true })
common.Step("Send OnVehicleData with windowStatus data", common.sendOnVehicleData, { common.windowStatusData })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
common.Step("Restore PreloadedPT", common.restorePreloadedPT)
