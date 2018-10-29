---------------------------------------------------------------------------------------------------
-- Proposal: https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0189-Restructuring-OnResetTimeout.md
-- User story: TBD
-- Use case: TBD
--
-- Requirement summary: TBD
--
-- Description:
-- In case:
-- 1) RPC_1 is requested
-- 2) RPC_2 is requested
-- 3) Some time after receiving RPC_1 and RPC_2 requests on HMI is passed
-- 4) HMI sends BC.OnResetTimeout(resetPeriod = 11000) to SDL for RPC_1 and BC.OnResetTimeout(resetPeriod = 13000) for RPC_2
-- 5) HMI does not respond
-- SDL does:
-- 1) Respond in 11 seconds with GENERIC_ERROR resultCode to mobile app to RPC_1
-- 2) Respond in 13 seconds with GENERIC_ERROR resultCode to mobile app to RPC_2
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
runner.Step("Send SendLocation", common.sendLocationError, { _, "SendLocation", 11000, 11000 })
runner.Step("Send SetInteriorVehicleData", common.setInteriorVehicleDataError, { _, "SetInteriorVehicleData", 13000, 13000 })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
