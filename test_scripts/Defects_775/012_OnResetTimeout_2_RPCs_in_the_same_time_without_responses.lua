---------------------------------------------------------------------------------------------------
-- User story:https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [OnResetTimeout] GENERIC_ERROR: getting GENERIC_ERROR on Speak and ScrollableMessage after reseting timeout
-- via OnResetTimeout in case Speak and ScrollableMessage RPCs are processed in the same time and HMI does not respond
--
-- Steps:
-- 1) HMI and SDL are started
-- 2) App is registered and activated.
--
-- Steps:
-- 1. App requests Speak RPC and ScrollableMessage RPC
-- 2. HMI sends UI.OnResetTimeout() notification to SDL in 5 sec after receiving UI.ScrollableMessage request
-- 3. HMI sends TTS.OnResetTimeout() notification to SDL in 9 sec after receiving TTS.Speak request
-- 4. HMI does not respond
--
-- Expected:
-- 1. SDL sends Speak response with 'GENERIC_ERROR, success:false' to mobile application in
-- 1. SDL sends Speak response with 'GENERIC_ERROR, success:false' to mobile application in
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function RCPs()
  local scrollableParams = {
    scrollableMessageBody = "scrollableMessageBody text",
    timeout = 5000
  }
  local speakParams = {
    ttsChunks = { { text = "Speak text", type = "TEXT" } }
  }
  local cid1 = common.getMobileSession():SendRPC("ScrollableMessage", scrollableParams)
  local cid2 = common.getMobileSession():SendRPC("Speak", speakParams)
  common.getHMIConnection():ExpectRequest("UI.ScrollableMessage")
  :Do(function()
      -- HMI does not respond
      local function uiOnResetTimeout()
        common.getHMIConnection():SendNotification("UI.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "UI.ScrollableMessage" })
      end
      RUN_AFTER(uiOnResetTimeout, 2000)
    end)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function()
      -- HMI does not respond
      local function ttsOnResetTimeout()
        common.getHMIConnection():SendNotification("TTS.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "TTS.Speak" })
      end
      RUN_AFTER(ttsOnResetTimeout, 5000)
    end)
  common.getMobileSession():ExpectResponse(cid1, { success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(13000)
  common.getMobileSession():ExpectResponse(cid2, { success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(16000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Speak ScrollableMessage GENERIC_ERROR with OnResetTimeout", RCPs)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
