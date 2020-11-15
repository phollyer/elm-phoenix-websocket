module View.ChatRoom exposing
    ( init
    , introduction
    , membersTyping
    , messageForm
    , messages
    , user
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as Attr
import Types exposing (Message, User, initUser)
import View.Messages as Messages



{- Model -}


type Config msg
    = Config
        { user : User
        , messageForm : Element msg
        , membersTyping : List String
        , messages : List Message
        }


init : Config msg
init =
    Config
        { user = initUser
        , messageForm = El.none
        , membersTyping = []
        , messages = []
        }


user : User -> Config msg -> Config msg
user user_ (Config config) =
    Config { config | user = user_ }


messageForm : Element msg -> Config msg -> Config msg
messageForm element (Config config) =
    Config { config | messageForm = element }


membersTyping : List String -> Config msg -> Config msg
membersTyping members (Config config) =
    Config { config | membersTyping = members }


messages : List Message -> Config msg -> Config msg
messages messages_ (Config config) =
    Config { config | messages = messages_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ El.spacing 10
        , El.height El.fill
        , El.width El.fill
        ]
    <|
        introduction config.user
            :: [ El.column
                    (contentAttrs device)
                    [ messagesView device config.user config.messages
                    , membersTypingView config.membersTyping
                    , form config.messageForm
                    ]
               ]


introduction : User -> Element msg
introduction currentUser =
    El.paragraph
        [ El.width El.fill ]
        [ El.text "Welcome to "
        , El.text currentUser.username
        , El.text "'s room."
        ]


membersTypingView : List String -> Element msg
membersTypingView members =
    if members == [] then
        El.none

    else
        El.paragraph
            [ El.width El.fill
            , El.height El.shrink
            , Font.alignLeft
            ]
            [ El.el
                [ Font.bold ]
                (El.text "Members Typing: ")
            , List.intersperse ", " members
                |> String.concat
                |> El.text
            ]


form : Element msg -> Element msg
form element =
    El.el
        [ El.height El.shrink
        , El.width El.fill
        ]
        element



{- Messages -}


messagesView : Device -> User -> List Message -> Element msg
messagesView device currentUser messages_ =
    El.el
        [ Background.color Color.white
        , Border.rounded 10
        , El.htmlAttribute <|
            Attr.id "message-list"
        , El.height El.fill
        , El.width El.fill
        , El.clipY
        , El.scrollbarY
        ]
        (Messages.init
            |> Messages.user currentUser
            |> Messages.messages messages_
            |> Messages.view device
        )



{- Attributes -}


contentAttrs : Device -> List (Attribute msg)
contentAttrs device =
    [ El.alignBottom
    , El.spacing 10
    , El.width El.fill
    , El.height <|
        El.maximum (maxHeight device) El.fill
    ]


maxHeight : Device -> Int
maxHeight { class, orientation, height } =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            height - 120

        ( Phone, Landscape ) ->
            height - 150

        _ ->
            height - 200
