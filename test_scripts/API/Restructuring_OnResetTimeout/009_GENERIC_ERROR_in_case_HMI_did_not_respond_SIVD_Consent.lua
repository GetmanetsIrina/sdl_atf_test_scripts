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
-- 3) HMI sends BC.OnResetTimeout(resetPeriod = 13000) to SDL
-- 4) HMI does not send response in 14 seconds after receiving request
-- SDL does:
-- 1) Respond with GENERIC_ERROR resultCode to mobile app after 14 seconds are expired
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/API/Restructuring_OnResetTimeout/common_OnResetTimeout')
local commonRC = require('test_scripts/RC/commonRC')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI1", common.registerAppWOPTU)
runner.Step("Activate App1", common.activateApp)
runner.Step("RAI2", common.registerAppWOPTU, { 2 })
runner.Step("Activate App2", common.activateApp, { 2 })

runner.Title("Test")
runner.Step("Set RA mode: ASK_DRIVER", commonRC.defineRAMode, { true, "ASK_DRIVER" })
runner.Step("App1 SetInteriorVehicleData", commonRC.rpcAllowed, { "CLIMATE", 1, "SetInteriorVehicleData" } )
runner.Step("App2 ButtonPress 1st ", common.rpcAllowedWithConsentError, { 2, "ButtonPress", _, "ButtonPress", 13000, 14000  })

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
