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
-- 3) HMI sends BC.OnResetTimeout(without resetPeriod) to SDL
-- 4) HMI sends response in 18 seconds after receiving request
-- SDL does:
-- 1) Receive response and successful process it
-- 2) Respond with SUCCESS resultCode to mobile app
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerAppWOPTU)
runner.Step("App activation", common.activateApp)
runner.Step("Create InteractionChoiceSet", common.createInteractionChoiceSet)

runner.Title("Test")
runner.Step("Send SendLocation", common.sendLocation, { "SendLocation", _, 18000 })
runner.Step("Send Alert", common.alert, { "Alert", _, 18000 })
runner.Step("Send PerformInteraction", common.performInteraction, { "PerformInteraction" ,_, 18000 })
runner.Step("Send DialNumber", common.dialNumber, { "DialNumber" , _, 18000 })
runner.Step("Send Slider", common.slider, { "Slider", _, 18000 })
runner.Step("Send Speak", common.speak, { "Speak", _, 18000 })
runner.Step("Send DiagnosticMessage", common.diagnosticMessage, { "DiagnosticMessage", _, 18000 })
runner.Step("Send ScrollableMessage", common.scrollableMessage, { "ScrollableMessage", _,18000 })

for _, buttonName in pairs(common.buttons) do

	runner.Step("SubscribeButton " .. buttonName, common.subscribeButton, { buttonName, "SubscribeButton", _, 18000 })
end

for _, mod in pairs(common.allModules)  do
  runner.Step("SetInteriorVehicleData " .. mod, common.rpcAllowed,
	{ mod, 1, "SetInteriorVehicleData", "SetInteriorVehicleData", _, 18000 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
