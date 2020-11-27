---------------------------------------------------------------------------------------------------
-- User story:https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [OnResetTimeout] SUCCESS: getting SUCCESS on Speak and ScrollableMessage after reseting timeout via OnResetTimeout
-- in case Speak and ScrollableMessage RPCs are processed in the same time
--
-- Steps:
-- 1) HMI and SDL are started
-- 2) App is registered and activated.
--
-- Steps:
-- 1. App requests Speak RPC and ScrollableMessage RPC
-- 2. HMI sends UI.OnResetTimeout() notification to SDL in 5 sec after receiving UI.ScrollableMessage request
-- 3. HMI sends TTS.OnResetTimeout() notification to SDL in 9 sec after receiving TTS.Speak request
-- 4. HMI responds with SUCCESS resultCode in 12 seconds after receiving UI.ScrollableMessage request
-- 5. HMI responds with SUCCESS resultCode in 15 seconds after receiving TTS.Speak request
--
-- Expected:
-- 1. SDL responds with 'SUCCESS, success:true' to mobile application after receiving responses from HMI
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
  :Do(function(_, data)
      local function uiOnResetTimeout()
        common.getHMIConnection():SendNotification("UI.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "UI.ScrollableMessage" })
      end
      local function uiResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(uiOnResetTimeout, 5000)
      RUN_AFTER(uiResp, 12000)
    end)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function(_, data)
      local function ttsOnResetTimeout()
        common.getHMIConnection():SendNotification("TTS.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "TTS.Speak" })
      end
      local function ttsResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      RUN_AFTER(ttsOnResetTimeout, 9000)
      RUN_AFTER(ttsResp, 15000)
    end)
  common.getMobileSession():ExpectResponse(cid1, { success = true, resultCode = "SUCCESS"})
  :Timeout(13000)
  common.getMobileSession():ExpectResponse(cid2, { success = true, resultCode = "SUCCESS"})
  :Timeout(16000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Speak ScrollableMessage SUCCESS with OnResetTimeout", RCPs)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
