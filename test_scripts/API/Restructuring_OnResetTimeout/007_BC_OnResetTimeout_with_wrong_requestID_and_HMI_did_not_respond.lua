---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
--
-- Description:
-- In case:
-- 1) RPC is requested
-- 2) Some time after receiving RPC request on HMI is passed
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 6000) with wrong requestID to SDL in 6 sec after HMI request
-- 4) HMI does not send response in 10 seconds after receiving request
-- SDL does:
-- 1) Respond in 10 seconds with GENERIC_ERROR resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Local Variables ]]
local wrongRequestID = 1234

local paramsForRespFunction = {
  notificationTime = 6000,
  resetPeriod = 6000
}

local rpcResponse = { success = false, resultCode = "GENERIC_ERROR" }

--[[ Local Functions ]]
local function invalidParamOnResetTimeout(pData, pOnRTParams)
  local function sendOnResetTimeout()
    common.onResetTimeoutNotification(wrongRequestID, pData.method, pOnRTParams.resetPeriod)
  end
  RUN_AFTER(sendOnResetTimeout, pOnRTParams.notificationTime)
end

--[[ Scenario ]]
common.Title("Preconditions")
common.Step("Clean environment", common.preconditions)
common.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
common.Step("App_1 registration", common.registerAppWOPTU)
common.Step("App_2 registration", common.registerAppWOPTU, { 2 })
common.Step("App_1 activation", common.activateApp)
common.Step("Set RA mode: ASK_DRIVER", common.defineRAMode, { true, "ASK_DRIVER" })
common.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

common.Title("Test")
for _, rpc in pairs(common.rpcsArrayWithoutRPCWithCustomTimeout) do
  common.Step("Send " .. rpc , common.rpcs[rpc],
    { 11000, 4000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
end
common.Step("Send PerformInteraction" , common.rpcs.PerformInteraction,
  { 16000, 9000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
common.Step("Send ScrollableMessage" , common.rpcs.ScrollableMessage,
  { 12000, 5000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
common.Step("Send Alert" , common.rpcs.Alert,
  { 14000, 7000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })
common.Step("Send Slider" , common.rpcs.Slider,
  { 12000, 5000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })

common.Step("Module allocation for App_1" , common.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" })
common.Step("App_2 activation", common.activateApp, { 2 })
common.Step("Send SetInteriorVehicleData with consent" , common.rpcs.rpcAllowedWithConsent,
  { 11000, 4000, invalidParamOnResetTimeout, paramsForRespFunction, rpcResponse })

common.Title("Postconditions")
common.Step("Stop SDL", common.postconditions)
