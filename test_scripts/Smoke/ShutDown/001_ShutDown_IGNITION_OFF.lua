-- Requirement summary:
-- [Data Resumption]:OnExitAllApplications(IGNITION_OFF) in terms of resumption
--
-- Description:
-- In case SDL receives OnExitAllApplications(IGNITION_OFF),
-- SDL must clean up any resumption-related data
-- Obtained after OnExitAllApplications( SUSPEND). SDL must stop all its processes,
-- notify HMI via OnSDLClose and shut down.
--
-- 1. Used preconditions
-- HMI is running
-- One App is registered and activated on HMI
--
-- 2. Performed steps
-- Perform ignition Off
-- HMI sends OnExitAllApplications(IGNITION_OFF)
--
-- Expected result:
-- 1. SDL sends to App OnAppInterfaceUnregistered
-- 2. SDL sends to HMI OnSDLClose and stops working
---------------------------------------------------------------------------------------------------
--[[ General Precondition before ATF start ]]
config.defaultProtocolVersion = 2

--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local commonSmoke = require('test_scripts/Smoke/commonSmoke')
local utils = require('user_modules/utils')
local actions = require('user_modules/sequences/actions')
local events = require("events")

--[[ Local Functions ]]
local function ShutDown_IGNITION_OFF(self)
  local timeout = 5000
  local function removeSessions()
    for i = 1, actions.getAppsCount() do
      self.mobileSession[i] = nil
    end
  end
  local event = events.Event()
  event.matches = function(event1, event2) return event1 == event2 end
  EXPECT_EVENT(event, "SDL shutdown")
  :Do(function()
      removeSessions()
      StopSDL()
      utils.wait(1000)
    end)
  actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications", { reason = "SUSPEND" })
  EXPECT_HMINOTIFICATION("BasicCommunication.OnSDLPersistenceComplete")
  :Do(function()
      actions.getHMIConnection():SendNotification("BasicCommunication.OnExitAllApplications",{ reason = "IGNITION_OFF" })
      for i = 1, actions.getAppsCount() do
        actions.getMobileSession(i):ExpectNotification("OnAppInterfaceUnregistered", { reason = "IGNITION_OFF" })
      end
    end)
  EXPECT_HMINOTIFICATION("BasicCommunication.OnAppUnregistered", { unexpectedDisconnect = false })
  :Times(actions.getAppsCount())
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
      self:FailTestCase("SDL was shutdown forcibly")
    end
  end
  RUN_AFTER(forceStopSDL, timeout + 500)
  utils.wait(timeout + 500)
end

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", commonSmoke.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", commonSmoke.start)
runner.Step("RAI, PTU", commonSmoke.registerApplicationWithPTU)
runner.Step("Activate App", commonSmoke.activateApp)

runner.Title("Test")
runner.Step("Check that SDL finish it's work properly by IGNITION_OFF", ShutDown_IGNITION_OFF)

runner.Title("Postconditions")
runner.Step("Stop SDL", commonSmoke.postconditions)
