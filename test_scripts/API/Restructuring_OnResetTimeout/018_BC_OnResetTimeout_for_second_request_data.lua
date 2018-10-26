---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC_1 is requested
-- 2) RPC_1 is requested one more time
-- 3) Some time after receiving RPC_1 requests on HMI is passed
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 3000) to SDL for second request
-- 5) HMI does not respond
-- SDL does:
-- Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app to first request
-- Respond in 13 seconds with GENERIC_ERROR resultCode to mobile app to second request
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
	:Do(function(_, _)
	-- HMI does not respond
	end)

	local corId = common.getMobileSession():SendRPC("DiagnosticMessage",
	{ targetID = 1, messageLength = 1, messageData = { 1 } })

	EXPECT_HMICALL("VehicleInfo.DiagnosticMessage",
	{ targetID = 1, messageLength = 1, messageData = { 1 } })
	:Do(function()
	common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout", {
		requestID = common.getHMIAppId(),
		methodName = "DiagnosticMessage",
		resetPeriod = 3000
	})
	end):Times(1)
	:Do(function(_, _)
	-- HMI does not respond
	end)
	common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "GENERIC_ERROR" })
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
