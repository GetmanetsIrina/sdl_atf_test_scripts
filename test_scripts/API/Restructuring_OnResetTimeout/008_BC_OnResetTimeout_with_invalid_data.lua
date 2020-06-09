---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Some time after receiving RPC request on HMI is passed
-- 3) HMI sends invalid BC.OnResetTimeout(resetPeriod = 13000)
-- a) missing mandatory
-- b) value out of bound
-- c) invalid data type
-- d) invalid structure
-- 4) HMI does not send response
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local pOnResetTimeOut = {
  missingMandatory = { resetPeriod = 13000 },
  outOfBounds = { requestID = 65536, methodName = "Navigation.SendLocation", resetPeriod = 13000 },
  invaidType = { requestID = "wrongType", methodName = "Navigation.SendLocation", resetPeriod = 13000 },
  incorrectStructure = { requestID = {}, methodName = "Navigation.SendLocation", resetPeriod = 13000 }
}

local paramsForRespFunction = {
  notificationTime = 6000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invalidParamOnResetTimeout(_, pOnRTParams)
  local function sendOnResetTimeout()
    common.getHMIConnection():SendNotification("BasicCommunication.OnResetTimeout", pOnRTParams.onResetParams)
    common.notificationTime = timestamp()
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

local function getOnResetTimeoutParams(pValue)
  paramsForRespFunction.onResetParams = pValue
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App registration", common.registerAppWOPTU)
common.Step("App activation", common.activateApp)

common.Title("Test")
for k, value in pairs(pOnResetTimeOut) do
  common.Step("Set params for OnResetTimeout notification", getOnResetTimeoutParams, { value })
  common.Step("Send SendLocation" .. k, common.rpcs.SendLocation,
    { 11000, 4000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
end

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
