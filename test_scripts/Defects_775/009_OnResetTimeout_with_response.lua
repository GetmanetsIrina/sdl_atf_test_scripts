---------------------------------------------------------------------------------------------------
-- User story:https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [OnResetTimeout] SUCCESS: getting SUCCESS on Speak and ScrollableMessage after reseting timeout via OnResetTimeout
--
-- Steps:
-- 1) HMI and SDL are started
-- 2) App is registered and activated.
--
-- Steps:
-- 1. App requests Speak RPC
-- 2. HMI sends TTS.OnResetTimeout() notification to SDL
-- 3. HMI responds with SUCCESS resultCode in 12 seconds after receiving TTS.Speak request
--
-- Expected:
-- 1. SDL responds with 'SUCCESS, success:true' to mobile application.

-- Steps:
-- 1. App requests ScrollableMessage RPC
-- 2. HMI sends UI.OnResetTimeout() notification to SDL
-- 3. HMI responds with SUCCESS resultCode in 12 seconds after receiving UI.ScrollableMessage request
--
-- Expected:
-- 1. SDL responds with 'SUCCESS, success:true' to mobile application.
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Constants ]]
local timeRunAfterForResp = 12000
local timeRunAfterForNot = 4000

--[[ Local Functions ]]
local function Speak()
  local requestParams = {
    ttsChunks = { { text = "Speak text", type = "TEXT" } }
  }
  local cid = common.getMobileSession():SendRPC("Speak", requestParams)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function(_,data)
      local function ttsResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      local function ttsOnResetTimeout()
        common.getHMIConnection():SendNotification("TTS.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "TTS.Speak" })
      end
      RUN_AFTER(ttsOnResetTimeout, timeRunAfterForNot)
      RUN_AFTER(ttsResp, timeRunAfterForResp)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(13000)
end

local function ScrollableMessage()
  local requestParams = {
    scrollableMessageBody = "scrollableMessageBody text",
    timeout = 5000
  }
  local cid = common.getMobileSession():SendRPC("ScrollableMessage", requestParams)
  common.getHMIConnection():ExpectRequest("UI.ScrollableMessage")
  :Do(function(_,data)
      local function uiResp()
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
      end
      local function uiOnResetTimeout()
        common.getHMIConnection():SendNotification("UI.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "UI.ScrollableMessage" })
      end
      RUN_AFTER(uiOnResetTimeout, timeRunAfterForNot)
      RUN_AFTER(uiResp, timeRunAfterForResp)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS"})
  :Timeout(13000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Speak success with OnResetTimeout", Speak)
runner.Step("ScrollableMessage success with OnResetTimeout", ScrollableMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
