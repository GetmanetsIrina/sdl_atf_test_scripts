---------------------------------------------------------------------------------------------------
-- RC common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local test = require("user_modules/dummy_connecttest")
local events = require('events')
local commonSteps = require("user_modules/shared_testcases/commonSteps")
local commonFunctions = require('user_modules/shared_testcases/commonFunctions')
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')
local json = require("modules/json")

--[[ Local Variables ]]
local commonDefect = actions
commonDefect.wait = utils.wait
local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")

--[[ @unexpectedDisconnect: closing connection
--! @parameters: none
--! @return: none
--]]
function commonDefect.unexpectedDisconnect()
  test.mobileConnection:Close()
  commonDefect.getHMIConnection():ExpectNotification("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = true })
  :Do(function()
      for i = 1, commonDefect.getAppsCount() do
        test.mobileSession[i] = nil
      end
    end)
end

--[[ @connectMobile: create connection
--! @parameters: none
--! @return: none
--]]
function commonDefect.connectMobile()
  test.mobileConnection:Connect()
  EXPECT_EVENT(events.connectedEvent, "Connected")
  :Do(function()
      utils.cprint(35, "Mobile connected")
    end)
end

--[[ @preconditions: delete logs, backup preloaded file, update preloaded
--! @parameters: none
--! updateFunction - update preloadedPT
--! @return: none
--]]
local preconditionsOrig = commonDefect.preconditions
function commonDefect.preconditions(pUpdateFunction)
  preconditionsOrig()
  commonPreconditions:BackupFile(preloadedPT)
  if pUpdateFunction then
    commonDefect.updatePreloadedPT(pUpdateFunction)
  end
end

--[[ @updatePreloadedPT: update preloaded file with custom permissions
--! @parameters:
--! updateFunction - update preloadedPT
--! @return: none
--]]
function commonDefect.updatePreloadedPT(pUpdateFunction)
  local preloadedFile = commonPreconditions:GetPathToSDL() .. preloadedPT
  local pt = utils.jsonFileToTable(preloadedFile)
  pt.policy_table.functional_groupings["DataConsent-2"].rpcs = json.null
  pUpdateFunction(pt)
  utils.tableToJsonFile(pt, preloadedFile)
end

--[[ @postconditions: stop SDL if it's not stopped, restore preloaded file
--! @parameters: none
--! @return: none
--]]
local postconditionsOrig = commonDefect.postconditions
function commonDefect.postconditions()
  postconditionsOrig()
  commonPreconditions:RestoreFile(preloadedPT)
end

--[[ @ignitionOff: ignition off
--! @parameters: none
--! @return: none
--]]
function commonDefect.ignitionOff()
  local timeout = 5000
  local function removeSessions()
    for i = 1, commonDefect.getAppsCount() do
      test.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      commonDefect.wait(1000)
    end)
  commonDefect.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      commonDefect.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, commonDefect.getAppsCount() do
        commonDefect.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(commonDefect.getAppsCount())
  local isSDLShutDownSuccessfully = false
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLClose")
  :Do(function()
      utils.cprint(35, "SDL was shutdown successfully")
      isSDLShutDownSuccessfully = true
      RAISE_EVENT(event, event)
    end)
  :Timeout(timeout)
  local function forceStopSDL()
    if isSDLShutDownSuccessfully == false then
      utils.cprint(35, "SDL was shutdown forcibly")
      RAISE_EVENT(event, event)
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
end

return commonDefect
