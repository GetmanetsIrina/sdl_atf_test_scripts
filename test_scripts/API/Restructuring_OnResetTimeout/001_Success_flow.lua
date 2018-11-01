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
-- 4) HMI sends response in 12 seconds after receiving request
-- SDL does:
-- 1) Receive response and successful process it
-- 2) Wait response from HMI
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

local paramsForRespFunction = {
	respTime = 11000,
	notificationTime = 0,
	resetPeriod = 15000
}

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
-- for _, rpc in pairs(common.rpcs) do
runner.Step("Send SendLocation" , common.SendLocation,
	{12000, paramsForRespFunction.respTime, common.responseWithOnResetTimeout, paramsForRespFunction })
-- end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
