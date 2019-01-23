---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-- Description:
-- Precondition:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

-- [[ Local function ]]
local function getSystemTimeRes(pData)
  common.getHMIConnection():SendError(pData.id, pData.method, "REJECTED", "Time is not provided")
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { "0x0B, 0x0A, 0x07" })
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential_expired.pem", false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Video Service protected with rejected GetSystemTime request",
  common.startServiceProtectedGetSystemTimeUnsuccessNACK, { 11, getSystemTimeRes })
runner.Step("Start Audio Service protected with rejected GetSystemTime request",
  common.startServiceProtectedGetSystemTimeUnsuccessNACK, { 10, getSystemTimeRes })
runner.Step("Start RPC Service protected with rejected GetSystemTime request",
  common.startServiceProtectedGetSystemTimeUnsuccessNACK, { 7, getSystemTimeRes })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
