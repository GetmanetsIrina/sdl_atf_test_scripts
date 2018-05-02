---------------------------------------------------------------------------------------------------
-- Issue:
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local common = require('test_scripts/MobileProjection/Phase2/common')
local runner = require('user_modules/script_runner')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
local testCases = {
  [1] = { t = "PROJECTION",    m = false, s = "NOT_AUDIBLE" },
  [2] = { t = "DEFAULT",       m = false, s = "NOT_AUDIBLE" },
  [3] = { t = "NAVIGATION",    m = false, s = "AUDIBLE" },
  [4] = { t = "COMMUNICATION", m = false, s = "AUDIBLE" },
  [5] = { t = "NAVIGATION",    m = true,  s = "AUDIBLE" },
  [6] = { t = "COMMUNICATION", m = true,  s = "AUDIBLE" },
  [7] = { t = "PROJECTION",    m = true,  s = "AUDIBLE" },
  [8] = { t = "MEDIA",         m = true,  s = "AUDIBLE" },
  [9] = { t = "DEFAULT",       m = true,  s = "AUDIBLE" }
}

--[[ Local Functions ]]
local function activateApp(pTC, pAudioSS)
  local requestId = common.getHMIConnection():SendRequest("SDL.ActivateApp", { appID = common.getHMIAppId() })
  common.getHMIConnection():ExpectResponse(requestId)
  common.getMobileSession():ExpectNotification("OnHMIStatus")
  :ValidIf(function(_, data)
      return common.checkAudioSS(pTC, "App1", pAudioSS, data.payload.audioStreamingState)
    end)
end

--[[ Scenario ]]
for n, tc in common.spairs(testCases) do
  runner.Title("TC[" .. common.getTCNum(testCases, n) .. "]: "
    .. "[hmiType:" .. tc.t .. ", isMedia:" .. tostring(tc.m) .. "]")
  runner.Step("Clean environment", common.preconditions)
  runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
  runner.Step("Set App Config", common.setAppConfig, { 1, tc.t, tc.m })
  runner.Step("Register App", common.registerApp)
  runner.Step("Activate App, audioState:" .. tc.s, activateApp, { n, tc.s })
  runner.Step("Clean sessions", common.cleanSessions)
  runner.Step("Stop SDL", common.postconditions)
end
runner.Step("Print failed TCs", common.printFailedTCs)
