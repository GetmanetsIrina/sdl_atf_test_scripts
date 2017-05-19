-----------------------------Required Shared Libraries---------------------------------------
require('user_modules/all_common_modules')

-------------------------------------------Preconditions-------------------------------------
-- Register App -> Activate App
common_steps:PreconditionSteps("PreconditionSteps", 7)

--------------------------------------------BODY---------------------------------------------
-- Verify: when all params are correct and image of softButtons doesn't exist
-- SDL->MOB: RPC (success:true, resultCode:"WARNINGS", info:"Reference image(s) not found")
---------------------------------------------------------------------------------------------
function Test:Verify_AllParamsCorrect_ImageNotExist_WARNINGS()
  local invalid_image_full_path = common_functions:GetFullPathIcon("invalidImage.png")
  local cid = self.mobileSession:SendRPC("ScrollableMessage", {
      scrollableMessageBody = "abc",
      softButtons =
      {
        {
          softButtonID = 1,
          text = "Button1",
          type = "BOTH",
          image =
          {
            value = "invalidImage_1.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        },
        {
          softButtonID = 2,
          text = "Button2",
          type = "BOTH",
          image =
          {
            value = "invalidImage_2.png",
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        }
      },
    }
  )
  EXPECT_HMICALL("UI.ScrollableMessage",{
      messageText = {
        fieldName = "scrollableMessageBody",
        fieldText = "abc"
      },
      softButtons =
      {
        {
          softButtonID = 1,
          text = "Button1",
          type = "BOTH",
          image =
          {
            value = invalid_image_full_path,
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        },
        {
          softButtonID = 2,
          text = "Button2",
          type = "BOTH",
          image =
          {
            value = invalid_image_full_path,
            imageType = "DYNAMIC"
          },
          isHighlighted = false,
          systemAction = "DEFAULT_ACTION"
        }
      },
    } )
  :Do(function(_,data)
      self.hmiConnection:SendError(data.id, data.method, "WARNINGS","Reference image(s) not found")
    end)
  EXPECT_RESPONSE(cid, { success = true, resultCode = "WARNINGS", info = "Reference image(s) not found"})
end

-------------------------------------------Postconditions-------------------------------------
common_steps:UnregisterApp("Postcondition_UnRegisterApp", const.default_app_name)
common_steps:StopSDL("Postcondition_StopSDL")