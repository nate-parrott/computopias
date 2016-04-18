//
//  RandomContentCardItemView.swift
//  Computopias
//
//  Created by Nate Parrott on 3/29/16.
//  Copyright © 2016 Nate Parrott. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class RandomContentCardItemView: CardItemView {
    static let Types = ["dice", "number", "word", "emoji", "answer"]
    var type: String = RandomContentCardItemView.Types.randomChoice() {
        didSet {
            setNeedsDisplay()
        }
    }
    var valueString: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var _randomShuffleCountdown = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func setup() {
        super.setup()
        opaque = false
        needsDisplayOnBoundsChange = true
    }
    
    override func importJson(json: [String : AnyObject]) {
        super.importJson(json)
        type = json["randomType"] as? String ?? type
        valueString = json["valueString"] as? String
    }
    override func toJson() -> [String : AnyObject] {
        var j = super.toJson()
        j["type"] = "random"
        j["randomType"] = type
        if let v = valueString {
            j["valueString"] = v
        } else if let t = TypeClass.fromType(type) {
            j["valueString"] = t.randomValue()
        }
        return j
    }
    
    override func detachFromTemplate() {
        super.detachFromTemplate()
        valueString = nil
    }
    
    override func prepareToPresent() {
        super.prepareToPresent()
        _randomShuffleCountdown = 7
        for i in 0..<7 {
            delay(NSTimeInterval(i) * 0.1, closure: {
                self._randomShuffleCountdown -= 1
            })
        }
    }
    
    override func tapped() -> Bool {
        if editMode {
            let sheet = UIAlertController(title: "Random", message: nil, preferredStyle: .ActionSheet)
            for type in RandomContentCardItemView.Types {
                let typeName = type
                if let t = TypeClass.fromType(type) {
                    let item = UIAlertAction(title: t.name(), style: .Default, handler: { (_) in
                        self.type = typeName
                    })
                    sheet.addAction(item)
                }
            }
            sheet.addAction(UIAlertAction(title: "Never mind", style: .Cancel, handler: nil))
            NPSoftModalPresentationController.getViewControllerForPresentation().presentViewController(sheet, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    override var defaultSize: GridSize {
        get {
            return CGSizeMake(3, 1)
        }
    }
    
    override func constrainedSizeForProposedSize(size: GridSize) -> GridSize {
        return size
    }
    
    // MARK: Rendering
    override func drawParametersForAsyncLayer(layer: _ASDisplayLayer) -> NSObjectProtocol? {
        var attributes = [String: AnyObject]()
        attributes[NSForegroundColorAttributeName] = UIColor.blackColor()
        attributes[NSFontAttributeName] = TextCardItemView.font.fontWithSize(generousFontSize)
        attributes[NSParagraphStyleAttributeName] = NSAttributedString.paragraphStyleWithTextAlignment(alignment.x.textAlignment)
        
        var text = ""
        if let t = TypeClass.fromType(type) {
            if let v = valueString {
                if _randomShuffleCountdown > 0 {
                    text = t.randomValue()
                } else {
                    text = v
                }
            } else {
                text = t.emptyValue()
            }
            if let image = t.imageForValue(text) {
                return image
            } else {
                return NSAttributedString(string: text, attributes: attributes)
            }
        }
        return NSAttributedString(string: "", attributes: attributes)
    }
    
    override var needsNoView: Bool {
        get {
            return true
        }
    }
    
    override class func drawRect(bounds: CGRect, withParameters: NSObjectProtocol?, isCancelled: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {
        let string = withParameters as! NSAttributedString
        string.drawFillingRect(CardItemView.textInsetBoundsForBounds(bounds))
    }
    
    class TypeClass: NSObject {
        class func fromType(string: String) -> TypeClass? {
            switch string {
                case "dice": return DiceTypeClass()
                case "number": return NumberTypeClass()
                case "word": return WordTypeClass()
                case "emoji": return EmojiTypeClass()
                case "answer": return AnswerTypeClass()
            default: return nil
            }
        }
        func randomValue() -> String {
            return ""
        }
        func emptyValue() -> String {
            return name()
        }
        func imageForValue(value: String) -> UIImage? {
            return nil
        }
        func name() -> String {
            return ""
        }
    }
    
    class DiceTypeClass: TypeClass {
        override func emptyValue() -> String {
            return "🎲 ?"
        }
        override func randomValue() -> String {
            let i = (rand() % 6) + 1
            return "🎲 \(i)"
        }
        override func name() -> String {
            return "Dice"
        }
    }
    
    class NumberTypeClass: TypeClass {
        override func emptyValue() -> String {
            return "#??"
        }
        override func randomValue() -> String {
            let n = rand() % 100 + 1
            return "#\(n)"
        }
        override func name() -> String {
            return "Random number 1–100"
        }
    }
    
    class WordTypeClass: TypeClass {
        static var nouns: [String] = {
            let text: String = try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("Nouns", ofType: "txt")!)
            return text.componentsSeparatedByString("\n")
        }()
        override func randomValue() -> String {
            return WordTypeClass.nouns.randomChoice()
        }
        override func name() -> String {
            return "Random noun"
        }
    }
    
    class EmojiTypeClass: TypeClass {
        static let emoji = "😄😃😀😊☺️😉😍😘😚😗😙😜😝😛😳😁😔😌😒😞😣😢😂😭😪😥😰😅😓😩😫😨😱😠😡😤😖😆😋😷😎😴😵😲😟😦😧😈👿😮😬😐😕😯😶😇😏😑👲👳👮👷💂👶👦👧👨👩👴👵👱👼👸😺😸😻😽😼🙀😿😹😾👹👺🙈🙉🙊💀👽💩🔥✨🌟💫💥💢💦💧💤💨👂👀👃👅👄👍👎👌👊✊✌️👋✋👐👆👇👉👈🙌🙏☝️👏💪🚶🏃💃👫👪👬👭💏💑👯🙆🙅💁🙋💆💇💅👰🙎🙍🙇🎩👑👒👟👞👡👠👢👕👔👚👗🎽👖👘👙💼👜👝👛👓🎀🌂💄💛💙💜💚❤️💔💗💓💕💖💞💘💌💋💍💎👤👥💬👣💭🐶🐺🐱🐭🐹🐰🐸🐯🐨🐻🐷🐽🐮🐗🐵🐒🐴🐑🐘🐼🐧🐦🐤🐥🐣🐔🐍🐢🐛🐝🐜🐞🐌🐙🐚🐠🐟🐬🐳🐋🐄🐏🐀🐃🐅🐇🐉🐎🐐🐓🐕🐖🐁🐂🐲🐡🐊🐫🐪🐆🐈🐩🐾💐🌸🌷🍀🌹🌻🌺🍁🍃🍂🌿🌾🍄🌵🌴🌲🌳🌰🌱🌼🌐🌞🌝🌚🌑🌒🌓🌔🌕🌖🌗🌘🌜🌛🌙🌍🌎🌏🌋🌌🌠⭐☀️⛅☁️⚡☔❄️⛄🌀🌁🌈🌊🎍💝🎎🎒🎓🎏🎆🎇🎐🎑🎃👻🎅🎄🎁🎋🎉🎊🎈🎌🔮🎥📷📹📼💿📀💽💾💻📱☎️📞📟📠📡📺📻🔊🔉🔈🔇🔔🔕📢📣⏳⌛⏰⌚🔓🔒🔏🔐🔑🔎💡🔦🔆🔅🔌🔋🔍🛁🛀🚿🚽🔧🔩🔨🚪🚬💣🔫🔪💊💉💰💴💵💷💶💳💸📲📧📥📤✉️📩📨📯📫📪📬📭📮📦📝📄📃📑📊📈📉📜📋📅📆📇📁📂✂️📌📎✒️✏️📏📐📕📗📘📙📓📔📒📚📖🔖📛🔬🔭📰🎨🎬🎤🎧🎼🎵🎶🎹🎻🎺🎷🎸👾🎮🃏🎴🀄🎲🎯🏈🏀⚽⚾️🎾🎱🏉🎳⛳🚵🚴🏁🏇🏆🎿🏂🏊🏄🎣☕🍵🍶🍼🍺🍻🍸🍹🍷🍴🍕🍔🍟🍗🍖🍝🍛🍤🍱🍣🍥🍙🍘🍚🍜🍲🍢🍡🍳🍞🍩🍮🍦🍨🍧🎂🍰🍪🍫🍬🍭🍯🍎🍏🍊🍋🍒🍇🍉🍓🍑🍈🍌🍐🍍🍠🍆🍅🌽🏠🏡🏫🏢🏣🏥🏦🏪🏩🏨💒⛪🏬🏤🌇🌆🏯🏰⛺🏭🗼🗾🗻🌄🌅🌃🗽🌉🎠🎡⛲🎢🚢⛵🚤🚣⚓🚀✈️💺🚁🚂🚊🚉🚞🚆🚄🚅🚈🚇🚝🚋🚃🚎🚌🚍🚙🚘🚗🚕🚖🚛🚚🚨🚓🚔🚒🚑🚐🚲🚡🚟🚠🚜💈🚏🎫🚦🚥⚠️🚧🔰⛽🏮🎰♨️🗿🎪🎭📍🚩🇯🇵🇰🇷🇩🇪🇨🇳🇺🇸🇫🇷🇪🇸🇮🇹🇷🇺🇬🇧1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣0️⃣🔟🔢#️⃣🔣⬆️⬇️⬅️➡️🔠🔡🔤↗️↖️↘️↙️↔️↕️🔄◀️▶️🔼🔽↩️↪️ℹ️⏪⏩⏫⏬⤵️⤴️🆗🔀🔁🔂🆕🆙🆒🆓🆖📶🎦🈁🈯🈳🈵🈴🈲🉐🈹🈺🈶🈚🚻🚹🚺🚼🚾🚰🚮🅿️♿🚭🈷️🈸🈂️Ⓜ️🛂🛄🛅🛃🉑㊙️㊗️🆑🆘🆔🚫🔞📵🚯🚱🚳🚷🚸⛔✳️❇️❎✅✴️💟🆚📳📴🅰️🅱️🆎🅾️💠➿♻️♈♉♊♋♌♍♎♏♐♑♒♓⛎🔯🏧💹💲💱©️®️™️❌‼️⁉️❗❓❕❔⭕🔝🔚🔙🔛🔜🔃🕛🕧🕐🕜🕑🕝🕒🕞🕓🕟🕔🕠🕕🕖🕗🕘🕙🕚🕡🕢🕣🕤🕥🕦✖️➕➖➗♠️♥️♣️♦️💮💯✔️☑️🔘🔗➰〰️〽️🔱◼️◻️◾◽▪️▫️🔺🔲🔳⚫⚪🔴🔵🔻⬜⬛🔶🔷🔸🔹"
        static var _emojiList: [String] = {
            var emojiByIndex = [String]()
            let emoji = EmojiTypeClass.emoji
            emoji.enumerateSubstringsInRange(emoji.startIndex..<emoji.endIndex, options: NSStringEnumerationOptions.ByComposedCharacterSequences) {(charOpt: String?, _, _, _) in
                if let c = charOpt {emojiByIndex.append(c)}
                
            }
            return emojiByIndex
        }()
        override func name() -> String {
            return "Random emoji"
        }
        override func randomValue() -> String {
            return EmojiTypeClass._emojiList.randomChoice()
        }
    }
    
    class AnswerTypeClass: TypeClass {
        override func name() -> String {
            return "Random answer"
        }
        static let answers = ["yes", "no", "definitely not", "probably not", "never", "nah", "quite possible", "who knows", "unclear", "odds in your favor", "never ever", "nope", "yes", "yes!", "soon!", "not now"]
        override func randomValue() -> String {
            return AnswerTypeClass.answers.randomChoice()
        }
    }
}
