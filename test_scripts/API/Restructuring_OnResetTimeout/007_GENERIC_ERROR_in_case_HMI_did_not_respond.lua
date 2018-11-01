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
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 13000) to SDL
-- 4) HMI does not send response in 14 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 14 seconds are expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local paramsForRespFunction = {
	notificationTime = 6000,
	resetPeriod = 6000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

function common.responseWithOnResetTimeout(pData, pParams)
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(pData.id, pData.method, pParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pParams.notificationTime)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
runner.Step("Send SendLocation" , common.SendLocation,
	{13000, paramsForRespFunction.resetPeriod, common.responseWithOnResetTimeout, paramsForRespFunction, rpcResponse })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
