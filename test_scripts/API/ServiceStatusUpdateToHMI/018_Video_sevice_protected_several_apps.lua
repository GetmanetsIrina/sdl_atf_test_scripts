---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-- Description: Receiving of the OnStatusUpdate notification by the appropriate app by the Audio, Video services opening
-- Precondition:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')
local constants = require("protocol_handler/ford_protocol_constants")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Function ]]
function common.startServiceFunc(pServiceId, pAppId)
  local msg = {
    frameType = constants.FRAME_TYPE.CONTROL_FRAME,
    serviceType = pServiceId,
    frameInfo = constants.FRAME_INFO.START_SERVICE,
    encryption = false
  }
  common.getMobileSession(pAppId):Send(msg)
end

function common.serviceResponseFunc(pServiceId, _, pAppId)
  common.getMobileSession(pAppId):ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_ACK,
    encryption = false
  })
end

common.policyTableUpdateFunc = function() end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential.pem", false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App 1 registration", common.registerApp, { 1 })
runner.Step("PolicyTableUpdate for app 1", common.policyTableUpdate)
runner.Step("App 2 registration", common.registerApp, { 2 })
runner.Step("PolicyTableUpdate for app 2", common.policyTableUpdate)
runner.Step("App 1 activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Video Service app 1", common.startServiceWithOnServiceUpdate, { 11, 0, 1 })
runner.Step("Start Audio Service app 1", common.startServiceWithOnServiceUpdate, { 10, 0, 1 })
runner.Step("App 2 activation", common.activateApp, { 2 })
runner.Step("Start Video Service app 2", common.startServiceWithOnServiceUpdate, { 11, 0, 2 })
runner.Step("Start Audio Service app 2", common.startServiceWithOnServiceUpdate, { 10, 0, 2 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
