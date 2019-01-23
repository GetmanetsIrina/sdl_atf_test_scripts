---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-- Description:
-- Precondition:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')
local utils = require("user_modules/utils")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions]]
function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceTypeValue, reason = "PTU_FAILED", appID = common.getHMIAppId() })
  :Times(2)
  :Timeout(65000)
end

function common.serviceResponseFunc(pServiceId)
  common.getMobileSession():ExpectControlMessage(pServiceId, {
    frameInfo = common.frameInfo.START_SERVICE_NACK,
    encryption = false
  })
  :Timeout(65000)
end

function common.policyTableUpdateFunc()
  common.getHMIConnection():ExpectNotification("SDL.OnStatusUpdate",
  { status = "UPDATE_NEEDED" }, { status = "UPDATING" },
  { status = "UPDATE_NEEDED" }, { status = "UPDATING" })
  :Times(4)
  :Timeout(65000)
  :Do(function(exp, data)
    if exp.occurences == 2 and data.params.status == "UPDATING" then
      utils.cprint(35, "Waiting for PTU retry")
    end
  end)

  common.policyTableUpdateUnsuccess()

  common.wait(65000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions, { "0x0B" })
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential_expired.pem", false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Audio Service protected", common.startServiceWithOnServiceUpdate, { 10, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
