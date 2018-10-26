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
-- 4) HMI does not send response in 20 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 20 seconds are expired
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
runner.Step("Send SendLocation", common.sendLocationError, { "SendLocation", _, 20000 })
runner.Step("Send Alert", common.alertError, { "Alert", _, 20000 })
runner.Step("Send PerformInteraction", common.performInteractionError, { "PerformInteraction", _, 20000 })
runner.Step("Send DialNumber", common.dialNumberError, { "DialNumber", _, 20000 })
runner.Step("Send Slider", common.sliderError, { "Slider", _, 20000 })
runner.Step("Send Speak", common.speakError, { "Speak", _, 20000 })
runner.Step("Send DiagnosticMessage", common.diagnosticMessageError, { "DiagnosticMessage", _, 20000 })
runner.Step("Send ScrollableMessage", common.scrollableMessageError, {  "ScrollableMessage", _, 20000 })

for _, buttonName in pairs(common.buttons) do

	runner.Step("SubscribeButton " .. buttonName, common.subscribeButtonError,
	{ buttonName, "SubscribeButton", _, 20000 })
end

for _, mod in pairs(common.allModules)  do
  runner.Step("SetInteriorVehicleData " .. mod, common.setVehicleData,
	{ mod, "SetInteriorVehicleData", "SetInteriorVehicleData", _, 20000 })
end
