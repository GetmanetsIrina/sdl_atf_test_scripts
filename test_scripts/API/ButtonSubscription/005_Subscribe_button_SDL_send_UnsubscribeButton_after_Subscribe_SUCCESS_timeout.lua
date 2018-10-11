---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) Mobile app requests SubscribeButton(button_1)
-- 2) SDL sends Buttons.SubscribeButton(button_1, appId) to HMI
-- 3) HMI does not respond during default timeout
-- 4) SDL responds SubscribeButton(GENERIC_ERROR) to mobile app
-- 5) HMI sends Buttons.SubscribeButton(SUCCESS) to SDL
-- SDL does:
-- 1) Sends Buttons.UnsubscribeButton(button_1, appId) to HMI
-- 2) Receives response Buttons.UnsubscribeButton(SUCCESS) and keep actual unsubscribed state for button_1
-- 3) Not send SubscribeButton response to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName = "OK"
local errorCode = "GENERIC_ERROR"
local himCID

--[[ Local function ]]
function rpcGenericError(pAppId, pRpc, pButtonName)
    local cid = common.getMobileSession(pAppId):SendRPC(pRpc, { buttonName = pButtonName })
    appIdVariable = common.getHMIAppId(pAppId)
    EXPECT_HMICALL("Buttons." .. pRpc,{ appID = appIdVariable, buttonName = pButtonName })
    :Do(function(_, data)
        -- HMI did not response
        himCID = data.id
    end)
    common.getMobileSession(pAppId):ExpectResponse(cid, { success = false, resultCode = errorCode })
    :Do(function()
        common.getHMIConnection():SendResponse(himCID, "Buttons.SubscribeButton", "SUCCESS", { })    
    end)
    EXPECT_HMICALL("Buttons.UnsubscribeButton",{ appID = appIdVariable, buttonName = pButtonName })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)

runner.Title("Test")
runner.Step("Unsubscribe in timeout case", rpcGenericError, { 1, "SubscribeButton", buttonName, errorCode })
runner.Step("Button ".. buttonName .. " wasn't Subscribe", common.buttonPressUnsuccess, { 1, buttonName })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
