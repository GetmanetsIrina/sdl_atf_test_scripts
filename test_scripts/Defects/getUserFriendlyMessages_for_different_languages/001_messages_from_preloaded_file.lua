---------------------------------------------------------------------------------------------------
-- Description: Check that SD is able to send friendly messages for all languages
-- received from sdl_preloaded_pt.json file
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/getUserFriendlyMessages_for_different_languages/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)

for _, messageCode in pairs(common.getMessageCodes()) do
  for _, language in pairs(common.languages) do
    runner.Title("Test " .. language .. " " .. messageCode)
    runner.Step("GetUserFriendlyMessage", common.getUserFriendlyMessage, { language, messageCode })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
