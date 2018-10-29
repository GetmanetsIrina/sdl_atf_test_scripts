---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Some time after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 13000) with right methodName but wrong requestID to SDL
-- 4) HMI does not send response
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function scrollableMessageError( )
  local requestParams = {
    scrollableMessageBody = "abc",
    timeout = 5000
  }
  local cid = common.getMobileSession():SendRPC("ScrollableMessage", requestParams)
  EXPECT_HMICALL("UI.ScrollableMessage",
    { messageText = {
      fieldName = "scrollableMessageBody",
      fieldText = requestParams.scrollableMessageBody
    },
    appID = common.getHMIAppId()
  })
  :Do(function()
  common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout", {
    requestID = 111, -- wrong requestID
    methodName = "ScrollableMessage",
    resetPeriod = 130000
  })
  end)
  :Do(function(_, _)
    -- HMI does not respond
  end)
  common.getMobileSession():ExpectResponse(cid, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Send ScrollableMessage", scrollableMessageError)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
