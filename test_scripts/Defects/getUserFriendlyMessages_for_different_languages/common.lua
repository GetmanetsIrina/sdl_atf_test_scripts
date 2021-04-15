---------------------------------------------------------------------------------------------------
-- Common module
---------------------------------------------------------------------------------------------------
--[[ General configuration parameters ]]
config.defaultProtocolVersion = 2
config.checkAllValidations = true

--[[ Required Shared libraries ]]
local actions = require("user_modules/sequences/actions")
local utils = require('user_modules/utils')
local commonFunctions = require("user_modules/shared_testcases/commonFunctions")
local commonPreconditions = require('user_modules/shared_testcases/commonPreconditions')

--[[ Local Variables ]]
local commonDefect = actions
commonDefect.jsonFileToTable = utils.jsonFileToTable

commonDefect.languages = { "EN-US", "ES-MX", "FR-CA", "DE-DE", "ES-ES", "EN-GB", "RU-RU", "TR-TR", "PL-PL", "FR-FR", "IT-IT",
  "SV-SE", "PT-PT", "NL-NL", "EN-AU", "ZH-CN", "ZH-TW", "JA-JP", "AR-SA", "KO-KR", "PT-BR", "CS-CZ", "DA-DK", "NO-NO",
  "NL-BE", "EL-GR", "HU-HU", "FI-FI", "SK-SK", "EN-IN", "TH-TH"
}

--[[ Common Functions ]]
function utils.getDeviceName()
  return config.mobileHost
end

local function getFriendlyMessage()
  local appConfigFolder = commonFunctions:read_parameter_from_smart_device_link_ini("AppConfigFolder")
  if appConfigFolder == nil or appConfigFolder == "" then
    appConfigFolder = commonPreconditions:GetPathToSDL()
  end
  local preloadedPT = commonFunctions:read_parameter_from_smart_device_link_ini("PreloadedPT")
  local pptsFile = appConfigFolder .. preloadedPT
  if utils.isFileExist(pptsFile) then
    return utils.jsonFileToTable(pptsFile).policy_table.consumer_friendly_messages
  end
  utils.cprint(35, "PreloadedPT was not found")
  return {}
end
commonDefect.friendlyMessage = getFriendlyMessage()

local function getFriendlyMessageTexts(pLanguage, pMessageCode)
  if commonDefect.friendlyMessage.messages[pMessageCode].languages[pLanguage:lower()] then
    return commonDefect.friendlyMessage.messages[pMessageCode].languages[pLanguage:lower()]
  end
  return commonDefect.friendlyMessage.messages[pMessageCode].languages["en-us"]
end

function commonDefect.getMessageCodes()
  local out = {}
  for key in pairs(commonDefect.friendlyMessage.messages) do
    table.insert(out, key)
  end
  return out
end

function commonDefect.ptu(pTbl)
  local messageCodes = commonDefect.getMessageCodes()
  pTbl.policy_table.consumer_friendly_messages.version = "001.001.027"
  pTbl.policy_table.consumer_friendly_messages.messages = commonDefect.friendlyMessage.messages
  local additionalLanguages = {
    ["JA-JP"] = "SYNCでモバイルアプリを有効にしますか？ \r \n \r \nSYNCでモバイルデバイスからモバイルアプリの使用を有効にすると、SYNCがデバイスのデータプランを定期的に使用して、設定を最新に保ち、アプリの機能を有効にするデータを送受信できることに同意するものとします。 Ford U.S.に送信されるデータには、VINおよびSYNCモジュール番号が含まれます。標準料金が適用される場合があります。 \r \n \r \n設定を変更したり、後でオフにしたりするには、SYNCモバイルアプリの設定メニューにアクセスします。詳細については、オーナーズマニュアルを参照してください。私は同意し、同意します。",
    ["KO-KR"] = "SYNC에서 모바일 앱을 활성화 하시겠습니까? \r \n \r \nSYNC의 모바일 장치에서 모바일 앱 사용을 활성화하면 SYNC가 주기적으로 장치의 데이터 요금제를 사용하여 설정을 최신 상태로 유지하고 앱 기능을 활성화하는 데이터를 보내고받을 수 있다는 데 동의합니다. Ford U.S.로 전송되는 데이터에는 VIN 및 SYNC 모듈 번호가 포함됩니다. 표준 요금이 적용될 수 있습니다. \r \n \r \n 설정을 변경하거나 나중에 끄려면 SYNC 모바일 앱 설정 메뉴를 방문하십시오. 자세한 내용은 사용 설명서를 참조하십시오. 동의하고 동의합니다.",
    ["NL-BE"] = "Wilt u mobiele apps inschakelen op SYNC? \r \n \r \nAls u het gebruik van mobiele apps vanaf uw mobiele apparaat op SYNC inschakelt, gaat u ermee akkoord dat SYNC periodiek het gegevensabonnement van uw apparaat kan gebruiken om gegevens te verzenden en te ontvangen die uw instellingen actueel houden en app-functionaliteit mogelijk maken. De gegevens die naar Ford U.S. worden verzonden, bevatten uw VIN- en SYNC-modulenummer. Er kunnen standaardtarieven van toepassing zijn. \r \n \r \nOm instellingen te wijzigen of later uit te schakelen, gaat u naar het instellingenmenu van SYNC Mobile Apps. Zie de gebruikershandleiding voor meer informatie. Ik ga akkoord en stem in.",
    ["EL-GR"] = "Θέλετε να ενεργοποιήσετε τις εφαρμογές για κινητές συσκευές στο SYNC; \r \n \r \nΑν ενεργοποιήσετε τη χρήση εφαρμογών για κινητά από την κινητή συσκευή σας στο SYNC, συμφωνείτε ότι το SYNC μπορεί περιοδικά να χρησιμοποιεί το πρόγραμμα δεδομένων της συσκευής σας για την αποστολή και λήψη δεδομένων που διατηρούν τις ρυθμίσεις σας ενημερωμένες και επιτρέπει τη λειτουργία της εφαρμογής. Τα δεδομένα που αποστέλλονται στη Ford U.S. περιλαμβάνουν τον αριθμό μονάδας VIN και SYNC. Ενδέχεται να ισχύουν τυπικές τιμές. \r \n \r \nΓια να αλλάξετε τις ρυθμίσεις ή να απενεργοποιήσετε αργότερα, επισκεφθείτε το μενού ρυθμίσεων του SYNC Mobile Apps. Ανατρέξτε στο Εγχειρίδιο κατόχου για περισσότερες πληροφορίες. Συμφωνώ και συμφωνώ.",
    ["HU-HU"] = "Engedélyezni szeretné a mobilalkalmazásokat a SYNC-en? \r \n \r \nHa engedélyezi a mobilalkalmazások használatát a mobileszközéről a SYNC-en, akkor egyetért azzal, hogy a SYNC rendszeresen felhasználhatja eszközének adatcsomagját olyan adatok küldésére és fogadására, amelyek folyamatosan frissítik a beállításokat és lehetővé teszik az alkalmazás funkcionalitását. A Ford USA-nak küldött adatok tartalmazzák a VIN és a SYNC modul számát. Általános díjak vonatkozhatnak. \r \n \r \nA beállítások módosításához vagy későbbi kikapcsoláshoz látogasson el a SYNC Mobile Apps beállításai menübe. További információkért lásd a Felhasználói kézikönyvet. Egyetértek és beleegyezek.",
    ["FI-FI"] = "Haluatko ottaa mobiilisovellukset käyttöön SYNC: ssä? \r \n \r \nJos otat mobiilisovellusten käytön käyttöön mobiililaitteellasi SYNC: ssä, hyväksyt, että SYNC voi ajoittain käyttää laitteen tietosuunnitelmaa lähettämään ja vastaanottamaan tietoja, jotka pitävät asetuksesi ajan tasalla ja mahdollistavat sovelluksen toiminnot. Ford USA: lle lähetetyt tiedot sisältävät VIN- ja SYNC-moduulinumerosi. Voidaan soveltaa vakiohintoja. \r \n \r \nJos haluat muuttaa asetuksia tai sammuttaa sen myöhemmin, siirry SYNC-mobiilisovellusten asetusvalikkoon. Katso lisätietoja Omistajan käsikirjasta. Hyväksyn ja suostun.",
    ["SK-SK"] = "Prajete si povoliť mobilné aplikácie v sieti SYNC? \r \n \r \nAk povolíte používanie mobilných aplikácií z mobilného zariadenia v sieti SYNC, súhlasíte s tým, že spoločnosť SYNC môže pravidelne používať dátový plán vášho zariadenia na odosielanie a prijímanie údajov, ktoré udržia vaše nastavenia aktuálne a umožnia funkčnosť aplikácií. Údaje odoslané spoločnosti Ford U.S. zahŕňajú vaše číslo VIN a SYNC modulu. Môžu sa účtovať štandardné ceny. \r \n \r \nAk chcete zmeniť nastavenia alebo ich vypnúť neskôr, navštívte ponuku nastavení mobilných aplikácií SYNC. Ďalšie informácie nájdete v používateľskej príručke. Súhlasím a súhlasím.",
    ["EN-IN"] = "Would you like to enable Mobile Apps on SYNC? \r\n\r\nIf you enable the use of Mobile Apps from your mobile device on SYNC, you agree that SYNC can periodically use your device\\u2019s data plan to send and receive data that keeps your settings current and enables app functionality. Data sent to Ford U.S. includes your VIN and SYNC module number. Standard rates may apply. \r\n\r\nTo change settings or turn off later, visit the SYNC Mobile Apps settings menu. See Owner's Manual for more information. I agree and consent.",
    ["TH-TH"] = "คุณต้องการเปิดใช้งานแอพมือถือบน SYNC หรือไม่? \r \n \r \n หากคุณเปิดใช้งานแอพมือถือจากอุปกรณ์มือถือของคุณบน SYNC คุณยอมรับว่า SYNC สามารถใช้แผนข้อมูลของอุปกรณ์ของคุณเป็นระยะเพื่อส่งและรับข้อมูลที่ทำให้การตั้งค่าของคุณเป็นปัจจุบันและเปิดใช้งานการทำงานของแอพ ข้อมูลที่ส่งไปยัง Ford U.S. รวมถึงหมายเลขโมดูล VIN และ SYNC ของคุณ อาจใช้อัตรามาตรฐาน \r \n \r \n หากต้องการเปลี่ยนการตั้งค่าหรือปิดในภายหลังให้ไปที่เมนูการตั้งค่า SYNC Mobile Apps ดูคู่มือการใช้งานสำหรับข้อมูลเพิ่มเติม ฉันยอมรับและยินยอม"
  }

  for _, messageCode in pairs(messageCodes) do
    for language, message in pairs(additionalLanguages) do
      pTbl.policy_table.consumer_friendly_messages.messages[messageCode].languages[language:lower()] = {}
      pTbl.policy_table.consumer_friendly_messages.messages[messageCode].languages[language:lower()].textBody = message
    end
  end

  commonDefect.friendlyMessage = pTbl.policy_table.consumer_friendly_messages
end

function commonDefect.getCustomMessages()
  return utils.jsonFileToTable("files/jsons/friendly_messages.json")
end

function commonDefect.getUserFriendlyMessage(pLanguage, pMessageCode)
  local requestId = commonDefect.getHMIConnection():SendRequest("SDL.GetUserFriendlyMessage",
    { messageCodes = { pMessageCode}, language = pLanguage })
  local fmExpectation = getFriendlyMessageTexts(pLanguage, pMessageCode)
  fmExpectation.messageCode = pMessageCode
  if fmExpectation.tts then
    fmExpectation.ttsString = fmExpectation.tts
    fmExpectation.tts = nil
  end
  commonDefect.getHMIConnection():ExpectResponse(requestId, { result = { messages = { fmExpectation }}})
end

return commonDefect
