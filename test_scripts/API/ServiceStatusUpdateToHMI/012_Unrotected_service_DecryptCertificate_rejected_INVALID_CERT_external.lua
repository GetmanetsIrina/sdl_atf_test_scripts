---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0211-ServiceStatusUpdateToHMI.md
-- Description:
-- Precondition:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ServiceStatusUpdateToHMI/common')
local events = require("events")

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
function common.decryptCertificateRes(pData)
  common.getHMIConnection():SendError(pData.id, pData.method, "REJECTED", "Cert is not decrypted")
end

function common.onServiceUpdateFunc(pServiceTypeValue)
  common.getHMIConnection():ExpectNotification("BasicCommunication.OnServiceUpdate",
    { serviceEvent = "REQUEST_RECEIVED", serviceType = pServiceTypeValue, appID = common.getHMIAppId() },
    { serviceEvent = "REQUEST_REJECTED", serviceType = pServiceTypeValue, reason = "INVALID_CERT", appID = common.getHMIAppId() })
  :Times(2)

  local startserviceEvent = events.Event()
  startserviceEvent.level = 3
    startserviceEvent.matches = function(_, data)
      return
      data.method == "BasicCommunication.DecryptCertificate"
    end

  common.getHMIConnection():ExpectEvent(startserviceEvent, "DecryptCertificate")
  :Do(function(_, data)
      common.decryptCertificateRes(data)
    end)
end

function common.serviceResponseFunc(pServiceId, pStreamingFunc)
  if pServiceId ~= 7 then
    common.getMobileSession():ExpectControlMessage(pServiceId, {
      frameInfo = common.frameInfo.START_SERVICE_ACK,
      encryption = false
    })
    :Do(function(_, data)
      if data.frameInfo == common.frameInfo.START_SERVICE_ACK then
        pStreamingFunc()
      end
    end)
  else
    common.getMobileSession():ExpectControlMessage(pServiceId, {
      frameInfo = common.frameInfo.START_SERVICE_NACK,
      encryption = false
    })
  end
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Init SDL certificates", common.initSDLCertificates,
  { "./files/Security/client_credential_expired.pem", false })
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Video Service protected", common.startServiceWithOnServiceUpdate, { 11, 0 })
runner.Step("Start Audio Service protected", common.startServiceWithOnServiceUpdate, { 10, 0 })
runner.Step("Start RPC Service protected", common.startServiceWithOnServiceUpdate, { 7, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
