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
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 3000) to SDL
-- 4) HMI does not send response in 13 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 13 seconds are expired
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
runner.Step("Send SendLocation", common.sendLocationError, { _, "SendLocation", 3000, 13000 })
runner.Step("Send Alert", common.alertError, { _, "Alert", 3000, 13000 })
runner.Step("Send PerformInteraction", common.performInteractionError, { _, "PerformInteraction", 3000, 13000 })
runner.Step("Send DialNumber", common.dialNumberError, { _, "DialNumber", 3000, 13000 })
runner.Step("Send Slider", common.sliderError, { _, "Slider", 3000, 13000 })
runner.Step("Send Speak", common.speakError, { _, "Speak", 3000, 13000 })
runner.Step("Send DiagnosticMessage", common.diagnosticMessageError, { _, "DiagnosticMessage", 3000, 13000 })
runner.Step("Send ScrollableMessage", common.scrollableMessageError, { _, "ScrollableMessage", 3000, 13000 })

for _, buttonName in pairs(common.buttons) do

	runner.Step("SubscribeButton " .. buttonName, common.subscribeButtonError,
	{ buttonName, _, "SubscribeButton", 3000, 13000 })
end

for _, mod in pairs(common.allModules)  do
  runner.Step("SetInteriorVehicleData " .. mod, common.setVehicleData,
	{ mod, "SetInteriorVehicleData", _, "SetInteriorVehicleData", 3000, 13000 })
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
