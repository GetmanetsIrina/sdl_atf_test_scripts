---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0192-button_subscription_response_from_hmi.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) Mobile app starts registration
-- SDL does:
-- 1) Sends Buttons.SubscribeButton(custom_button, appId) to HMI during registration
-- 2) Wait response from HMI
-- 3) Receives Buttons.SubscribeButton(SUCCESS)
-- 4) Not send response SubscribeButton(SUCCESS) to mobile app
-- 5) Does not update hashId
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/ButtonSubscription/common_buttonSubscription')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local variable ]]
local buttonName = "CUSTOM_BUTTON"
local ButtonPressModes = "SHORT" 
local CustomButtonID = 1

--[[ Local function ]]
local function registerApp(pAppId, pRpc, pButtonName)
    common.registerAppWOPTU()
    EXPECT_HMICALL("Buttons." .. pRpc, { appID = common.getHMIAppId(pAppId), buttonName = pButtonName })
    :Do(function(_, data)
        common.getHMIConnection():SendResponse(data.id, data.method, "SUCCESS", { })
    end)
    EXPECT_HMICALL("Buttons.OnButtonSubscription", { appID = common.getHMIAppId(pAppId), buttonName = pButtonName })
    :Times(0)
end

local function pressButton_CUSTOM_BUTTON(pButtonName, pCustomButtonID, pAppID)
    common.getHMIConnection():SendNotification("Buttons.OnButtonEvent", 
        { name = pButtonName, mode = "BUTTONDOWN", customButtonID = pCustomButtonID, appID = common.getHMIAppId(pAppID) })
    common.getHMIConnection():SendNotification("Buttons.OnButtonEvent", 
        { name = pButtonName, mode = "BUTTONUP", customButtonID = pCustomButtonID, appID = common.getHMIAppId(pAppID) })
    common.getHMIConnection():SendNotification("Buttons.OnButtonPress", 
        { name = pButtonName, mode = "SHORT", customButtonID = pCustomButtonID, appID = common.getHMIAppId(pAppID) })
    common.getMobileSession():ExpectNotification("Buttons.OnButtonEvent", 
        { buttonName = pButtonName, buttonEventMode = "BUTTONUP", customButtonID = pCustomButtonID },
        { buttonName = pButtonName, buttonEventMode = "BUTTONDOWN", customButtonID = pCustomButtonID })
    :Times(2)
    common.getMobileSession():ExpectNotification("Buttons.OnButtonPress", 
        { buttonName = pButtonName, buttonPressMode = "SHORT", customButtonID = pCustomButtonID })
end 
    
--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)

runner.Title("Test")
runner.Step("App registration and Subscribe on CUSTOM_BUTTON", registerApp, { 1, "SubscribeButton", buttonName })
runner.Step("On Button Press ", pressButton_CUSTOM_BUTTON, { buttonName, CustomButtonID, 1 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
