--[[ Description ]]
-- Requirement summary:
-- [APPLINK-23970]: [Policies] PreloadPT one invalid and other valid values in "RequestType" array

-- Description:
-- In case PreloadedPT has several values in "RequestType" array and one of them is invalid
-- SDL must:cut off this invalid value treat such PreloadedPT as valid continue working.

-- Preconditions:
-- -- 1. SDL and HMI are started
-- -- 2. Preloaded PT exists at the path defined in .ini file

-- Steps:
-- -- 1. Policies manager checks PreloadedPT
-- -- 2. PreloadedPT-> "app_policies" -> "default" -> RequestType has {TRAFFIC_MESSAGE_CHANNEL, HTTP, PROPRIETARY, IVSU}

-- Expected result:
-- -- 1. SDL cuts off IVSU from RequestType
-- -- 2. SDL continue working

--[[ Generic precondition ]]
require('user_modules/all_common_modules')

--[[ Local Variables ]]
local ivsu_cache_folder = common_functions:GetValueFromIniFile("SystemFilesPath") .. "/"
local snapshot_file = ivsu_cache_folder .. "sdl_snapshot.json"
local parent_item = {"policy_table", "app_policies", "default", "RequestType"}

local request_type_before_cut_off = {
  "TRAFFIC_MESSAGE_CHANNEL",
  "HTTP",
  "PROPRIETARY",
  "IVSU"
}

local request_type_after_cut_off = {
  "TRAFFIC_MESSAGE_CHANNEL",
  "HTTP",
  "PROPRIETARY"
}

--[[ Specific Precondition ]]
common_steps:AddNewTestCasesGroup("Preconditions")
common_steps:BackupFile("PreconditionSteps_Backup_sdl_preloaded_pt.json", "sdl_preloaded_pt.json")

function Test.PreconditionSteps_Update_RequestType_has_IVSU_In_PreloadedPT_file()
  common_functions:AddItemsIntoJsonFile(
    config.pathToSDL .. "sdl_preloaded_pt.json", parent_item, request_type_before_cut_off)
end

function Test.PreconditionSteps_Remove_Existing_Snapshot_File()
  if common_functions:IsFileExist(snapshot_file) then
    os.execute( "rm -f " .. snapshot_file)
  end
end

common_steps:PreconditionSteps("PreconditionSteps", const.precondition.ACTIVATE_APP)

--[[ Test ]]
common_steps:AddNewTestCasesGroup("Test")
function Test:Check_SDL_cuts_off_IVSU_from_RequestType()
  local count_sleep = 1
  while not common_functions:IsFileExist(snapshot_file) and count_sleep < 9 do
    os.execute("sleep 1")
    count_sleep = count_sleep + 1
  end

  if not common_functions:IsFileExist(snapshot_file) then
    self:FailTestCase("snapshot does not exist")
  end
  local snapshot_request_type = common_functions:GetParameterValueInJsonFile(snapshot_file, parent_item)

  if not common_functions:CompareTablesNotSorted(snapshot_request_type, request_type_after_cut_off) then
    self:FailTestCase("RequestType in snapshot is incorrect. Please check!")
  end
end

function Test:Check_SDL_continue_working()
  os.execute(" sleep 5 ")
  if sdl:CheckStatusSDL() ~= sdl.RUNNING then
    self:FailTestCase("SDL is stopped.")
  end
end

--[[ Postconditions ]]
common_steps:AddNewTestCasesGroup("Postconditions")
common_steps:RestoreIniFile("Postcondition_Restore_sdl_preloaded_pt.json", "sdl_preloaded_pt.json")
common_steps:StopSDL("Postcondition_StopSDL")