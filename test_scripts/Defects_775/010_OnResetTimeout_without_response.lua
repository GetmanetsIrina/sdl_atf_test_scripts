---------------------------------------------------------------------------------------------------
-- User story:https://github.com/CustomSDL/Sync3.2v2/issues/775
--
-- Description:
-- [OnResetTimeout] GENERIC_ERROR: getting GENERIC_ERROR on mobile app on Speak and ScrollableMessage request
-- in case HMI resets timeout via OnResetTimeout notification and HMI does not respond
--
-- Steps:
-- 1) HMI and SDL are started
-- 2) App is registered and activated.
--
-- Steps:
-- 1. App requests Speak RPC
-- 2. HMI sends TTS.OnResetTimeout() notification to SDL in 1 sec after receiving TTS.Speak request
-- 3. HMI does not respond
--
-- Expected:
-- 1. SDL responds with 'GENERIC_ERROR, success:false' to mobile application in 12 seconds

-- Steps:
-- 1. App requests ScrollableMessage RPC
-- 2. HMI sends UI.OnResetTimeout() notification to SDL in 1 sec after receiving UI.ScrollableMessage request
-- 3. HMI does not respond
--
-- Expected:
-- 1. SDL responds with 'GENERIC_ERROR, success:false' to mobile application in 12 seconds
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('user_modules/sequences/actions')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Constants ]]
local timeRunAfterForNot = 1000

--[[ Local Functions ]]
local function Speak()
  local requestParams = {
    ttsChunks = { { text = "Speak text", type = "TEXT" } }
  }
  local cid = common.getMobileSession():SendRPC("Speak", requestParams)
  common.getHMIConnection():ExpectRequest("TTS.Speak")
  :Do(function()
      -- HMI does not respond
      local function ttsOnResetTimeout()
        common.getHMIConnection():SendNotification("TTS.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "TTS.Speak" })
      end
      RUN_AFTER(ttsOnResetTimeout, timeRunAfterForNot)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(12000)
end

local function ScrollableMessage()
  local requestParams = {
    scrollableMessageBody = "scrollableMessageBody text",
    timeout = 5000
  }
  local cid = common.getMobileSession():SendRPC("ScrollableMessage", requestParams)
  common.getHMIConnection():ExpectRequest("UI.ScrollableMessage")
  :Do(function()
      -- HMI does not respond
      local function uiOnResetTimeout()
        common.getHMIConnection():SendNotification("UI.OnResetTimeout",
          { appID = common.getHMIAppId(), methodName = "UI.ScrollableMessage" })
      end
      RUN_AFTER(uiOnResetTimeout, timeRunAfterForNot)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR"})
  :Timeout(17000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("Speak GENERIC_ERROR with OnResetTimeout", Speak)
runner.Step("ScrollableMessage GENERIC_ERROR with OnResetTimeout", ScrollableMessage)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
