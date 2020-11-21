module View.MultiRoomChat.Room.Messages exposing
    ( init
    , messages
    , user
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Color, Device, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Types exposing (Message, User, initUser)



{- Model -}


type Config
    = Config
        { user : User
        , messages : List Message
        }


init : Config
init =
    Config
        { user = initUser
        , messages = []
        }


user : User -> Config -> Config
user user_ (Config config) =
    Config { config | user = user_ }


messages : List Message -> Config -> Config
messages list (Config config) =
    Config { config | messages = list }



{- View -}


view : Device -> Config -> Element msg
view _ (Config config) =
    El.column
        [ El.spacing 10
        , El.padding 10
        , El.height El.fill
        , El.width El.fill
        , Font.alignLeft
        ]
    <|
        List.map (toMessage config.user) config.messages


toMessage : User -> Message -> Element msg
toMessage currentUser message =
    if currentUser.id == message.owner.id then
        userMessage message

    else
        othersMessage message


userMessage : Message -> Element msg
userMessage { owner, text } =
    row
        [ emptySpace
        , column
            [ username El.alignRight owner.username
            , messageContent El.alignRight
                { backgroundColor = Color.darkslateblue
                , fontColor = Color.skyblue
                }
                text
            ]
        ]


othersMessage : Message -> Element msg
othersMessage { owner, text } =
    row
        [ column
            [ username El.alignLeft owner.username
            , messageContent El.alignLeft
                { backgroundColor = Color.darkseagreen
                , fontColor = Color.darkolivegreen
                }
                text
            ]
        , emptySpace
        ]


row : List (Element msg) -> Element msg
row =
    El.row
        [ El.width El.fill ]


column : List (Element msg) -> Element msg
column =
    El.column
        [ El.spacing 5
        , El.width <| El.fillPortion 5
        ]


emptySpace : Element msg
emptySpace =
    El.el
        [ El.width <| El.fillPortion 1 ]
        El.none


username : Attribute msg -> String -> Element msg
username alignment name =
    El.el
        [ alignment
        , Font.color Color.darkslateblue
        ]
        (El.text name)


messageContent : Attribute msg -> { backgroundColor : Color, fontColor : Color } -> String -> Element msg
messageContent alignment { backgroundColor, fontColor } text =
    El.column
        [ alignment
        , Background.color backgroundColor
        , Border.rounded 10
        , El.padding 5
        , El.spacing 10
        , Font.color fontColor
        ]
        (toParagraphs text)


toParagraphs : String -> List (Element msg)
toParagraphs text =
    String.split "\n" text
        |> List.map toParagraph


toParagraph : String -> Element msg
toParagraph text =
    El.paragraph
        [ El.width El.fill ]
        [ El.text text ]
