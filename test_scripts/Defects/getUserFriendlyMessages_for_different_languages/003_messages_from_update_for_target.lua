---------------------------------------------------------------------------------------------------
-- Description: Check that SD is able to send friendly messages for all languages
-- received during PTU, messages from sync policy server with some custom messages for some languages
---------------------------------------------------------------------------------------------------
--[[ Required Shared libraries ]]
local runner = require('user_modules/script_runner')
local common = require('test_scripts/Defects/getUserFriendlyMessages_for_different_languages/common')

--[[ Test Configuration ]]
runner.testSettings.isSelfIncluded = false

--[[ Local Variables ]]
common.friendlyMessage.messages = common.getCustomMessages()

--[[ Scenario ]]
runner.Title("Preconditions")
runner.Step("Clean environment", common.preconditions)
runner.Step("Start SDL, HMI, connect Mobile, start Session", common.start)
runner.Step("RAI", common.registerApp)
runner.Step("Activate App", common.activateApp)
runner.Step("PTU", common.policyTableUpdate, { common.ptu })

for _, messageCode in pairs(common.getMessageCodes()) do
  for _, language in pairs(common.languages) do
    runner.Title("Test " .. language .. " " .. messageCode)
    runner.Step("GetUserFriendlyMessage", common.getUserFriendlyMessage, { language, messageCode })
  end
end

runner.Title("Postconditions")
runner.Step("Stop SDL", common.postconditions)
