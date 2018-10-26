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
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 3000) with right requestID but wrong methodName to SDL
-- 4) HMI does not send response
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local pOnResetTO = {
	missingMandatory = { resetPeriod = 3000 },
	outOfBounds = { requestID = 65536, methodName = 111, resetPeriod = 1000001 },
	wrongType = { requestID = "wrongType", methodName = 111, resetPeriod = "wrongType" }
}

local function performIError( pRequestID, pMethodName, pResetPeriod )
  local params = {
    initialText = "StartPerformInteraction",
    interactionMode = "VR_ONLY",
    interactionChoiceSetIDList = { 100 },
    initialPrompt = {
      { type = "TEXT", text = "pathToFile1" }
    }
  }
  local corId = common.getMobileSession():SendRPC("PerformInteraction", params)
  common.getHMIConnection():ExpectRequest("UI.PerformInteraction")
  :Do(function()
	common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout",
	{ 	requestID = pRequestID,
		methodName = pMethodName,
		resetPeriod = pResetPeriod
	})
  end)
  :Do(function(_, data)
    common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", {})
  end)
  common.getHMIConnection():ExpectRequest("VR.PerformInteraction", {
    initialPrompt = params.initialPrompt
  })
  :Do(function(_, _)
    -- HMI does not respond
  end)
  common.getMobileSession():ExpectResponse(corId, { success = false, resultCode = "GENERIC_ERROR" })
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
for k, v in pairs(pOnResetTO) do
	runner.Step("Send PerformInteraction" .. k, performIError, { v })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
