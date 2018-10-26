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
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 3000) to SDL
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 3000) to SDL
-- 5) HMI does not send response in 16 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 16 seconds are expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function diagnosticMessageError()
	local cid = common.getMobileSession():SendRPC("DiagnosticMessage",
	{ targetID = 1, messageLength = 1, messageData = { 1 } })

	EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
	{ targetID = 1, messageLength = 1, messageData = { 1 } })

	:Do(function()
	common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout", {
		requestID = common.getHMIAppId(),
		methodName = "DiagnosticMessage",
		resetPeriod = 3000
	})
	end):Times(2)
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
runner.Step("Send DiagnosticMessage", diagnosticMessageError)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
