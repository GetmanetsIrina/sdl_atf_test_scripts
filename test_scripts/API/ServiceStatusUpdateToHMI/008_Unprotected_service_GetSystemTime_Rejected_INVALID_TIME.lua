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
function common.getSystemTimeRes(pData)
  common.getHMIConnection():SendError(pData.id, pData.method, "REJECTED", "Time is not provided")
end

function common.onServiceUpdateFunc(pServiceTypeValue)
  common.serviceStatusWithGetSystemTimeUnsuccess(pServiceTypeValue)
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

common.policyTableUpdateFunc = function() end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("PolicyTableUpdate", common.policyTableUpdate)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Start Video Service protected with rejected GetSystemTime request",
  common.startServiceWithOnServiceUpdate, { 11, 0 })
runner.Step("Start Audio Service protected with rejected GetSystemTime request",
  common.startServiceWithOnServiceUpdate, { 10, 0 })
runner.Step("Start RPC Service protected with rejected GetSystemTime request",
  common.startServiceWithOnServiceUpdate, { 7, 0 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
