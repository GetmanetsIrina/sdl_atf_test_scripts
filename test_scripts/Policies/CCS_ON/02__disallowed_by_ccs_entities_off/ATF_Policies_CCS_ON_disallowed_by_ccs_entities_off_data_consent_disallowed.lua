------------------------------------------------------------------------------------------------------
------------------------------------General Settings for Configuration--------------------------------
------------------------------------------------------------------------------------------------------
require('user_modules/all_common_modules')
local common_functions_ccs_on = require('user_modules/ATF_Policies_CCS_ON_OFF_common_functions')
------------------------------------------------------------------------------------------------------
---------------------------------------Common Variables-----------------------------------------------
------------------------------------------------------------------------------------------------------
local policy_file = config.pathToSDL .. "storage/policy.sqlite"
------------------------------------------------------------------------------------------------------
---------------------------------------Preconditions--------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Start SDL and register application
common_functions_ccs_on:PreconditonSteps("mobileConnection","mobileSession")
-- Activate application
common_steps:ActivateApplication("Activate_Application_1", config.application1.registerAppInterfaceParams.appName)
------------------------------------------------------------------------------------------------------
------------------------------------------Tests-------------------------------------------------------
------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------
-- TEST 02: 
  -- In case:
  -- SDL Policies database contains "disallowed_by_css_entities_off" param in "functional grouping" section
  -- and SDL gets SDL.OnAppPermissionConsent ("ccsStatus: ON") 
  -- allow this "functional grouping" and process requested RPCs from such "functional groupings" assigned to mobile app
--------------------------------------------------------------------------
-- Test 02.01:  
-- Description: disallowed_by_ccs_entities_off exists. Data consent is disallowed. HMI -> SDL: OnAppPermissionConsent(ccsStatus ON)
-- Expected Result: requested RPC is disallowed by data consent
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_Update_Policy_Table"] = function(self)
  -- create json for PTU from sdl_preloaded_pt.json
  local data = common_functions_ccs_on:ConvertPreloadedToJson()
  data.policy_table.module_config.preloaded_pt = false
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_ccs_entities_off = {{
      entityType = 2, 
      entityID = 5
    }},
    rpcs = {
      Alert = {
        hmi_levels = {"NONE", "BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  --insert application "0000001" which belong to functional group "Group001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001"}
  }
  --insert "ConsentGroup001" into "consumer_friendly_messages"
  data.policy_table.consumer_friendly_messages.messages["ConsentGroup001"] = {languages = {}}
  data.policy_table.consumer_friendly_messages.messages.ConsentGroup001.languages["en-us"] = {
        tts = "tts_test",
        label = "label_test",
        textBody = "textBody_test"
  }
  -- create json file for Policy Table Update  
  common_functions_ccs_on:CreateJsonFileForPTU(data, "/tmp/ptu_update.json", "/tmp/ptu_update_debug.json")
  -- update policy table
  common_functions_ccs_on:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
--   Check GetListOfPermissions response with empty ccsStatus array list. Get group id.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_GetListOfPermissions"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions") 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {{name = "ConsentGroup001", allowed = nil}},
      ccsStatus = {}
    }
  })
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAllowSDLFunctionality with data consent = disallowed
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAllowSDLFunctionality"] = function(self)
  --hmi side: send request SDL.OnAllowSDLFunctionality
  self.hmiConnection:SendNotification("SDL.OnAllowSDLFunctionality", 
    {allowed = false, source = "GUI"})
  common_functions:DelayedExp(2000)    
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with ccs status = ON
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
  -- hmi side: sending SDL.OnAppPermissionConsent for applications
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    appID = nil, source = "GUI",
    ccsStatus = {{entityType = 2, entityID = 5, status = "ON"}}
  })
  self.mobileSession:ExpectNotification("OnPermissionsChange")
  :Times(1)  
  common_functions:DelayedExp(2000)  
end

--------------------------------------------------------------------------
-- Main check:
--   Check device_consent_group in Policy Table: is_consented = 0
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Device_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM device_consent_group WHERE device_id = '" .. config.deviceMAC .. "' and functional_group_id = 'DataConsent-2';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m device consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "0" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   Check consent_group in Policy Table: is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m group consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   Check ccs_consent_group in Policy Table: is_consented = 1
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_Check_Ccs_Consent_Group"] = function(self)
  local sql_query = "SELECT is_consented FROM ccs_consent_group WHERE application_id = '0000001' and functional_group_id = 'Group001';"
  local result = common_functions_ccs_on:QueryPolicyTable(policy_file, sql_query)
  print(" \27[33m ccs consent = " .. tostring(result) .. ". \27[0m ")
  if result ~= "1" then
    self.FailTestCase("Incorrect ccs consent status.")    
  end
end

--------------------------------------------------------------------------
-- Main check:
--   RPC is disallowed to process.
--------------------------------------------------------------------------
Test[TEST_NAME_ON .. "MainCheck_RPC_is_disallowed"] = function(self)
  corid = self.mobileSession:SendRPC("Alert", {
    alertText1 = "alertText1",
    alertText2 = "alertText2",
    alertText3 = "alertText3",
    ttsChunks = { 
      {text = "TTSChunk", type = "TEXT"} 
    }, 
    duration = 5000,
    playTone = false,
    progressIndicator = true
  })
  -- UI.Alert 
  EXPECT_HMICALL("UI.Alert")
  :Times(0)
  :Timeout(RESPONSE_TIMEOUT)  
  -- TTS.Speak request 
  EXPECT_HMICALL("TTS.Speak")
  :Times(0)
  :Timeout(RESPONSE_TIMEOUT)
  EXPECT_RESPONSE(corid, {success = false, resultCode = "DISALLOWED"})
end

-- end Test 02.01
----------------------------------------------------
---------------------------------------------------------------------------------------------
--------------------------------------Postcondition------------------------------------------
---------------------------------------------------------------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end
