-----------------------------------Test cases----------------------------------------
-- Checks resumption of media app that was in FULL before unexpected disconnect after "ApplicationResumingTimeout"
-- if SDL receives BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":true)
-- and BasicCommunication.OnEventChanged("DEACTIVATE_HMI","isActive":false)
-- notifications during "ApplicationResumingTimeout".
-- Precondition:
-- -- 1. Default HMI level = NONE.
-- -- 2. Core and HMI are started.
-- -- 3. These values are configured in .ini file:
-- -- -- AppSavePersistentDataTimeout =10;
-- -- -- ResumptionDelayBeforeIgn = 30;
-- -- -- ResumptionDelayAfterIgn = 30;
-- Steps:
-- -- 1. Register media app and activate it
-- -- 2. Disconnect and then connect transport
-- -- 3. After app registration make aActivate Carplay/GAL and than defctivate Carplay/GAL (during 3 seconds after RAI)
-- Expected result
-- -- 1. SDL sends UpdateDeviceList with appropriate deviceID
-- -- 2. App is unexpected disconnected and than connected
-- -- 3. App is registered. HMI sends BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true)
-- -- -- and then BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":false) to SDL.
-- -- -- ApplicationResumingTimeout is expired and SDL resumes app to HMI level FULL.
-- Postcondition
-- -- 1.UnregisterApp
-- -- 2.StopSDL
-------------------------------------Required Shared Libraries-------------------------------
require('user_modules/all_common_modules')
------------------------------------ Common Variables ---------------------------------------
resume_timeout = 5000
local mobile_session = "mobileSession"
media_app = common_functions:CreateRegisterAppParameters(
    {appID = "1", appName = "MEDIA", isMediaApplication = true, appHMIType = {"MEDIA"}})
--------------------------------------Preconditions------------------------------------------
common_steps:BackupFile("Backup Ini file", "smartDeviceLink.ini")
-- update ApplicationResumingTimeout with the time enough to check app is (not) resumed
common_steps:SetValuesInIniFile("Update ApplicationResumingTimeout value", 
    "%p?ApplicationResumingTimeout%s? = %s-[%d]-%s-\n", "ApplicationResumingTimeout", resume_timeout)
common_steps:PreconditionSteps("Precondition", 5)
-----------------------------------------------Steps------------------------------------------
--1. Register media app and activate it
common_steps:RegisterApplication("Precondition_Register_App", mobile_session, media_app)
common_steps:ActivateApplication("Precondition_Activate_App", media_app.appName)

-- 2. App is unexpected disconnected and than connected
common_steps:CloseMobileSession("Close_Mobile_Session",mobile_session)

-- 3. After app registration activate Carplay/GAL and than deactivate Carplay/GAL (during 3 seconds after RAI)
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Start_DeactivateHmi()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= true, eventName="DEACTIVATE_HMI"})
end

function Test:Stop_DeactivateHmi()
  function to_run()
    self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",{isActive= false, eventName="DEACTIVATE_HMI"})
  end
  RUN_AFTER(to_run, 1000)
end

function Test:Check_App_Is_Resumed_Successful()
  EXPECT_HMICALL("BasicCommunication.ActivateApp")
  :Do(function(_,data)
      self.hmiConnection:SendResponse(data.id,"BasicCommunication.ActivateApp", "SUCCESS", {})
    end)
  self[mobile_session]:ExpectNotification("OnHMIStatus", {hmiLevel = "FULL", systemContext = "MAIN", audioStreamingState = "AUDIBLE"})
end

-------------------------------------------Postcondition-------------------------------------
common_steps:UnregisterApp("UnRegister_App", media_app.appName)
common_steps:StopSDL("StopSDL")
common_steps:RestoreIniFile("Restore_Ini_file")