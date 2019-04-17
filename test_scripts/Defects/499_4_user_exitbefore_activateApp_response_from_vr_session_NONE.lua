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
config.application1.registerAppInterfaceParams.appHMIType = { "MEDIA" }

--[[ Local Functions ]]
local function sendOnExitApplication()
  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "VRSESSION", appID = common.getHMIAppId()})
  common.getHMIConnection():SendNotification("VR.Started",{})

  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "HMI_OBSCURED", appID = common.getHMIAppId()})

  common.getHMIConnection():SendNotification("UI.OnSystemContext",
    { systemContext = "VRSESSION", appID = common.getHMIAppId()})

  common.getMobileSession():ExpectNotification("OnHMIStatus",
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "VRSESSION" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "HMI_OBSCURED" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "VRSESSION" },
    { hmiLevel = "FULL", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "FULL", audioStreamingState = "AUDIBLE", systemContext = "MAIN" },
    { hmiLevel = "NONE", audioStreamingState = "NOT_AUDIBLE", systemContext = "MAIN" })
  :Do(function(exp)
    if exp.occurences == 1 then
      common.getHMIConnection():SendNotification("UI.OnSystemContext",
        { systemContext = "MAIN", appID = common.getHMIAppId()})

      common.getHMIConnection():SendNotification("VR.Stopped",{})

      common.getHMIConnection():SendNotification("BasicCommunication.OnExitApplication",
        {reason = "USER_EXIT", appID = common.getHMIAppId() })
    end
  end)
  :Times(7)

  common.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered")
  :Times(0)

  common.getHMIConnection():ExpectRequest("BasicCommunication.ActivateApp")
  :Times(0)

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
