------------------------------------General Settings for Configuration--------------------------------
require('user_modules/all_common_modules')
local common_functions_external_consent_informing_hmi = require('user_modules/ATF_Policies_External_Consent_informing_HMI_common_functions')

---------------------------------------Common Variables-----------------------------------------------
local hmi_app_id_1
local hmi_app_id_2

----------------------------------Preconditions-------------------------------------------------------
PreconditonSteps("mobileConnection","mobileSession" , "mobileSession_2")

------------------------------------------Body-------------------------------------------------------
----------------------------------------------------
-- TEST-02: externalConsentStatus.status is ON.
----------------------------------------------------
-- Test-02.02:  
-- Description: HMI provides <externalConsentStatus> to SDL with status = ON. HMI -> SDL: GetListOfPermissions with appID
-- Expected result: SDL reponds to HMI list of all externalConsentStatus
--------------------------------------------------------------------------
-- Precondition:
--   Prepare JSON file with consent groups. Add all consent group names into app_polices of applications
--   Request Policy Table Update.
--------------------------------------------------------------------------
Test[TEST_NAME.."Precondition_Update_Policy_Table"] = function(self)
  -- create PTU from sdl_preloaded_pt.json
	local data = common_functions_external_consent_informing_hmi:ConvertPreloadedToJson()
  -- insert Group001 into "functional_groupings"
  data.policy_table.functional_groupings.Group001 = {
    user_consent_prompt = "ConsentGroup001",
    disallowed_by_external_consent_entities_off = {{
      entityType = 1, 
      entityID = 127
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  -- insert Group002 into "functional_groupings"
  data.policy_table.functional_groupings.Group002 = {
    user_consent_prompt = "ConsentGroup002",
    disallowed_by_external_consent_entities_off = {{
      entityType = 127, 
      entityID = 1
    }},
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }  
  -- insert Group003 into "functional_groupings"
  data.policy_table.functional_groupings.Group003 = {
    user_consent_prompt = "ConsentGroup003",
    disallowed_by_external_consent_entities_off = {{
      entityType = 1, 
      entityID = 1
    }},    
    rpcs = {
      SubscribeWayPoints = {
        hmi_levels = {"BACKGROUND", "FULL", "LIMITED"}
      }
    }  
  }
  --insert application "0000001" which belong to functional group "Group001" into "app_policies"
  data.policy_table.app_policies["0000001"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group001", "Group002"}
  }
  --insert application "0000002" which belong to functional groups "Group002" and "Group003" into "app_policies"
  data.policy_table.app_policies["0000002"] = {
    keep_context = false,
    steal_focus = false,
    priority = "NONE",
    default_hmi = "NONE",
    groups = {"Base-4", "Group003"}
  }  
  -- create json file for Policy Table Update  
  common_functions_external_consent_informing_hmi:CreateJsonFileForPTU(data, "/tmp/ptu_update.json")
  -- remove preload_pt from json file
  local parent_item = {"policy_table","module_config"}
  local removed_json_items = {"preloaded_pt"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items)
  local removed_json_items_preloaded_date = {"preloaded_date"}
  common_functions:RemoveItemsFromJsonFile("/tmp/ptu_update.json", parent_item, removed_json_items_preloaded_date)
  -- update policy table
  common_functions_external_consent_informing_hmi:UpdatePolicy(self, "/tmp/ptu_update.json")
end

--------------------------------------------------------------------------
-- Precondition:
--   HMI sends OnAppPermissionConsent with externalConsentStatus arrays
--------------------------------------------------------------------------
Test[TEST_NAME .. "Precondition_HMI_sends_OnAppPermissionConsent"] = function(self)
	self.hmiConnection:SendNotification("SDL.OnAppPermissionConsent", {
    externalConsentStatus = {
      {entityType = 1, entityID = 127, status = "ON"},
      {entityType = 127, entityID = 1, status = "ON"},
      {entityType = 1, entityID = 1, status = "ON"}
    }, source = "GUI"})
  -- delay to make sure database is already updated
  common_functions:DelayedExp(2000)
end


--------------------------------------------------------------------------
-- Main check:
--   Check GetListOfPermissions response with externalConsentStatus array list
--------------------------------------------------------------------------

Test[TEST_NAME .. "MainCheck_externalConsentStatus_ON_And_GetListOfPermissions_with_appID"] = function(self)
  --hmi side: sending SDL.GetListOfPermissions request to SDL for application 1
  local request_id = self.hmiConnection:SendRequest("SDL.GetListOfPermissions", {appID = hmi_app_id_1}) 
  -- hmi side: expect SDL.GetListOfPermissions response
  EXPECT_HMIRESPONSE(request_id,{
    result = {
      code = 0, 
      method = "SDL.GetListOfPermissions", 
      allowedFunctions = {
        {name = "ConsentGroup001", allowed = nil}, 
        {name = "ConsentGroup002", allowed = nil}   
      },
      externalConsentStatus = {{status = "ON"}, {status = "ON"}, {status = "ON"}}
    }
  })
  :ValidIf(function(_,data)
    return #data.result.externalConsentStatus == 3 and
    common_functions_external_consent_informing_hmi:Validate_externalConsentStatus_EntityType_EntityId(data, 1, 1) and
    common_functions_external_consent_informing_hmi:Validate_externalConsentStatus_EntityType_EntityId(data, 1, 127) and
    common_functions_external_consent_informing_hmi:Validate_externalConsentStatus_EntityType_EntityId(data, 127, 1)
  end)
end
-- end Test-02.02

-------------------------------------------Postcondition-------------------------------------
-- Stop SDL
Test["Stop_SDL"] = function(self)
  StopSDL()
end