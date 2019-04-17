---------------------------------------------------------------------------------------------------
-- User story: https://github.com/CustomSDL/Sync3.2v2/issues/499
--
-- Description: App HMI status is not changing to none when exiting via VR
--
-- Steps:
-- 1) SyncProxyTester app running in HMI Full on the phone and SYNC
-- 2) Press the voice command and say Exit <SyncProxyTester)>
--
-- Expected result:
-- 1) OnHMIStatus notification for the SyncProxyTester app should be HMI Level=None and Not_Audible
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/commonDefects')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Functions ]]
local function sendOnExitApplication()
  common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
    {reason = "USER_EXIT", appID = common.getHMIAppId() })

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })

  common.wait(5000)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("App registration", common.registerApp)
runner.Step("Activate App", common.activateApp)

runner.Title("Test")
runner.Step("USER_EXIT from HMI", sendOnExitApplication)
runner.Step("Activation after exit", common.activateApp)

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
