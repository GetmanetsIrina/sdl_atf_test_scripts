---------------------------------------------------------------------------------------------------
-- Proposal:
-- https://github.com/smartdevicelink/sdl_evolution/blob/master/proposals/0204-same-app-from-multiple-devices.md
--
-- Description: Check that SDL defines the same application from second device as known and does not trigger the PTU
-- for it in case second app is registered during first PTU
--
-- Preconditions:
-- 1) SDL and HMI are started
-- 2) Mobile №1 and №2 are connected to SDL and are consented
-- 3) App1 is registered from Mobile №1 and triggers PTU
--
-- Steps:
-- 1) App1 is registered from Mobile №2 during PTU for App1 from Mobile №1 is in progress
--   Check: SDL does not send BC.PolicyUpdate to HMI during the app registration
-- 2) First PTU is performed successful
--   Check: SDL does not trigger new PTU after the first one is finished
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/TheSameApp/commonTheSameApp')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Data ]]
local devices = {
  [1] = { host = "1.0.0.1", port = config.mobilePort },
  [2] = { host = "192.168.100.199", port = config.mobilePort }
}

local appParams = {
  [1] = {
    appName = "Test App",
    isMediaApplication = true,
    appHMIType = { "NAVIGATION" },
    appID = "0008",
    fullAppID = "0000008"
  }
}

local function registerApp2WithoutPTU()
  common.registerAppEx(2, appParams[1], 2, false)
  common.hmi.getConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Times(0)
  common.run.wait(2500)
end

local function PTUisNotTriggeredAfterSecondAppRegistration()
  common.hmi.getConnection():ExpectRequest("BasicCommunication.PolicyUpdate")
  :Times(0)
  common.hmi.getConnection():ExpectRequest("SDL.OnStatusUpdate")
  :Times(0)
  common.run.wait(2500)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL and HMI", common.start)
runner.Step("Connect two mobile devices to SDL", common.connectMobDevices, {devices})

runner.Title("Test")
runner.Step("Register App1 from device 1", common.registerAppEx, {1, appParams[1], 1, true})
runner.Step("Register App1 from device 2", registerApp2WithoutPTU)
runner.Step("PTU", common.ptu.policyTableUpdate)
runner.Step("PTU is not triggered by App registration from device 2", PTUisNotTriggeredAfterSecondAppRegistration)

runner.Title("Postconditions")
runner.Step("Remove mobile devices", common.clearMobDevices, {devices})
runner.Step("Stop SDL", common.postconditions)
