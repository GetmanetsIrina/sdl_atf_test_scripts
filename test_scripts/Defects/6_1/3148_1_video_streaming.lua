---------------------------------------------------------------------------------------------------
-- Issue: https://github.com/smartdevicelink/sdl_core/issues/3148

-- In case:
-- 1. Navigation app is registered and activated
-- 2. Video streaming is started
-- 3. Wait 15 sec
-- 4. Video streaming is restarted
-- SDL does:
--   a) send Navigation.OnVideoDataStreaming(available=false) by streaming finish
--   b) send Navigation.OnVideoDataStreaming(available=true) by streaming start
-- 5. Mobile app adds AddSubMenu
-- SDL does:
--   a) send UI.AddSubMenu request to HMI
--   b) resend UI.AddSubMenu response from HMI to mobile app
-- 6. Mobile app stops streaming
-- SDL does:
--   a) send Navigation.OnVideoDataStreaming(available=false) by streaming finish
---------------------------------------------------------------------------------------------------

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')
local utils = require("user_modules/utils")
local hmiCapabilities = require("user_modules/hmi_values")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Apps Configuration ]]
common.app.getParams(1).appHMIType = { "NAVIGATION" }
hmiCapabilities.getDefaultHMITable().BasicCommunication.UpdateDeviceList = nil

--[[ Local Variables ]]
local videoStreamServiceId = 11
local videoDataStoppedTimeout = 500
local requestParams = {
  menuID = 1000,
  position = 500,
  menuName ="SubMenupositive"
}

--[[ Local Functions ]]
local function stopStreaming()
  common.getMobileSession():StopStreaming("files/SampleVideo_5mb.mp4")
  common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = false })
end

local function startStreaming(pServiceId)
  common.getMobileSession():StartStreaming(pServiceId, "files/SampleVideo_5mb.mp4")
  common.getHMIConnection():ExpectNotification("Navigation.OnVideoDataStreaming", { available = true })
end

local function startService(pServiceId)
  common.getMobileSession():StartService(pServiceId)
  common.getHMIConnection():ExpectRequest("Navigation.StartStream")
  :Do(function(_, data)
      common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      startStreaming(pServiceId)
  end)
end

local function sendAddSubMenu()
  local corId = common.getMobileSession():SendRPC("AddSubMenu", requestParams)
  common.getHMIConnection():ExpectRequest("UI.AddSubMenu")
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)

  common.getMobileSession():ExpectResponse(corId, { success = true, resultCode = "SUCCESS"})
  common.getMobileSession():ExpectNotification("OnHashChange")
end

local function wait()
  utils.cprint(35, "Wait 15 seconds ...")
  utils.wait(15000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Set VideoDataStoppedTimeout=500 in ini file", common.setSDLIniParameter,
  { "VideoDataStoppedTimeout", videoDataStoppedTimeout })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("Register App", common.registerApp)
runner.Step("Policy Table Update", common.policyTableUpdate)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Start video Service", startService, { videoStreamServiceId })
runner.Step("Wait 15 sec", wait)
runner.Step("Stop streaming", stopStreaming, { videoStreamServiceId })
runner.Step("Start streaming", startStreaming, { videoStreamServiceId })
runner.Step("AddSubMenu", sendAddSubMenu)
runner.Step("Stop streaming", stopStreaming, { videoStreamServiceId })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
