---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) DialNumber is requested
-- 2) Some time after receiving DialNumber request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 12000) to SDL
-- 4) HMI sends response in 14 sec
-- SDL does:
-- 1) not apply RPC timeout and not reset timeout by BC.OnResetTimeout
-- 2) process response from HMI and respond SUCCESS to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local paramsForRespFunction = {
  respTime = 14000,
  notificationTime = 0,
  resetPeriod = 12000
}

--[[ Local Functions ]]
local function DialNumber()
  local cid = common.getMobileSession():SendRPC("DialNumber", { number = "#3804567654*" })
  EXPECT_HMICALL("BasicCommunication.DialNumber", { appID = common.getHMIAppId(), number = "#3804567654*" })
  :Do(function(_, data)
      common.responseWithOnResetTimeout(data, paramsForRespFunction)
    end)
  common.getMobileSession():ExpectResponse(cid, { success = true, resultCode = "SUCCESS" })
  :Timeout(15000)
  :ValidIf(function()
      return common.responseTimeCalculation(14000)
    end)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
common.Step("Send DialNumber", DialNumber)

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
