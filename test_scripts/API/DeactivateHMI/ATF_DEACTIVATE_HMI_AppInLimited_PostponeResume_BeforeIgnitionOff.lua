-----------------------------------Test cases----------------------------------------
-- Checks that resumption of HMI Level does not happen 
-- when application is running on SDL in LIMITED 
-- and disconnects due to activation of CarPlay an then re-connects after IGNITION_OFF.
-- The HMI level is stored and postponed 
-- when SDL receives BasicCommunication.OnEventChanged ("DEACTIVATE_HMI","isActive":true) notification.
-- The HMILevel is not resumed after IGNITION_OFF and the default HMILevel NONE is used
-- Precondition:
-- -- 1. SDL is started
-- -- 2. HMI is started
-- -- 3. App is registered via BT.
-- -- 4. App is in "LIMITED" and "AUDIBLE" HMI Level.  
-- Steps:
-- -- 1. Activate Carplay/GAL
-- -- 2. Device disconnects
-- -- 3. Device reconnects
-- -- 4. Make IGN_OFF
-- -- 5. Make IGN_ON
-- Expected result
-- -- 1. SDL receives BasicCommunication.OnEventChanged("eventName":"DEACTIVATE_HMI","isActive":true) from HMI.
-- -- -- SDL sends OnHMIStatus (“HMILevel: BACKGROUND, audioStreamingState: NOT_AUDIBLE”) 
-- -- 2. SDL sends BasicCommunication.OnAppUnregistered ("unexpectedDisconnect = true)"
-- -- 3. SDL receives RegisterAppInterface (SUCCESS)
-- -- -- SDL sends OnAppRegistered
-- -- -- SDL sends OnHMIStatus (“HMILevel: NONE, audioStreamingState: NOT_AUDIBLE”) this is the default HMI level (NONE)
-- -- -- SDL postpones HMI level resumption and stores postponedHMILevel=LIMITED (not current)
-- -- 4. SDL is reloaded.
-- -- -- SDL receives OnExitAllApplications (IGNITION_OFF)
-- -- -- SDL sends OnAppInterfaceUnregistred (IGNITION_OFF) and OnSDLClose
-- -- 5. SDL receives OnReady
-- -- -- SDL receives RegisterAppInterface (SUCCESS)
-- -- -- SDL sends OnAppRegistered 
-- -- -- SDL sends OnHMIStatus with default HMI level (NONE)
-- Postcondition
-- -- 1.StopSDL
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
common_steps:RegisterApplication("Precondition_Register_App", mobile_session, media_app)
common_steps:ActivateApplication("Precondition_Activate_App", media_app.appName)
common_steps:ChangeHMIToLimited("Precondition_Change_App_To_LIMITED", media_app.appName)
-----------------------------------------------Steps------------------------------------------
-- 1. Activate Carplay/GAL
function Test:Start_DeactivateHmi()
  self.hmiConnection:SendNotification("BasicCommunication.OnEventChanged",
	    {isActive= true, eventName="DEACTIVATE_HMI"})
end

-- 2. Device disconnects
common_steps:CloseMobileSession("Close_Mobile_Session",mobile_session)

-- 3. Device reconnects
common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Check_App_Is_Not_Resumed_After_ResumingTimeout()
  common_functions:DelayedExp(resume_timeout + 1000)
  self[mobile_session]:ExpectNotification("OnHMIStatus"):Times(0)
end

-- 4. Make IGN_OFF
common_steps:IgnitionOff("Precondition_Ignition_Off")

-- 5. Make IGN_ON
common_steps:IgnitionOn("Precondition_Ignition_On")

common_steps:AddMobileSession("Add_Mobile_Session", _, mobile_session)
common_steps:RegisterApplication("Register_App", mobile_session, media_app)

function Test:Check_App_Is_Not_Resumed_After_ResumingTimeout()
  common_functions:DelayedExp(resume_timeout + 1000)
  self[mobile_session]:ExpectNotification("OnHMIStatus"):Times(0)
end
-------------------------------------------Postcondition-------------------------------------
common_steps:StopSDL("Postcondition_StopSDL")
common_steps:RestoreIniFile("Postcondition_Restore_Ini_file")