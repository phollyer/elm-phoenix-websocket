module View.MultiRoomChat.Room exposing
    ( init
    , introduction
    , membersTyping
    , messages
    , messagesContainerMaxHeight
    , onChange
    , onFocus
    , onLoseFocus
    , onSubmit
    , room
    , user
    , userText
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as Attr
import Room exposing (Room)
import Types exposing (Message, User, initUser)
import View.MultiRoomChat.Room.Form as MessageForm
import View.MultiRoomChat.Room.Messages as Messages



{- Model -}


type Config msg
    = Config
        { user : User
        , room : Room
        , userText : String
        , membersTyping : List String
        , messages : List Message
        , messagesContainerMaxHeight : Int
        , onChange : Maybe (String -> msg)
        , onFocus : Maybe msg
        , onLoseFocus : Maybe msg
        , onSubmit : Maybe msg
        }


init : Config msg
init =
    Config
        { user = initUser
        , room = Room.init
        , userText = ""
        , membersTyping = []
        , messages = []
        , messagesContainerMaxHeight = 0
        , onChange = Nothing
        , onFocus = Nothing
        , onLoseFocus = Nothing
        , onSubmit = Nothing
        }


user : User -> Config msg -> Config msg
user user_ (Config config) =
    Config { config | user = user_ }


room : Room -> Config msg -> Config msg
room room_ (Config config) =
    Config { config | room = room_ }


userText : String -> Config msg -> Config msg
userText text (Config config) =
    Config { config | userText = text }


membersTyping : List String -> Config msg -> Config msg
membersTyping members (Config config) =
    Config { config | membersTyping = members }


messages : List Message -> Config msg -> Config msg
messages messages_ (Config config) =
    Config { config | messages = messages_ }


messagesContainerMaxHeight : Int -> Config msg -> Config msg
messagesContainerMaxHeight height (Config config) =
    Config { config | messagesContainerMaxHeight = height }


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


onFocus : msg -> Config msg -> Config msg
onFocus toMsg (Config config) =
    Config { config | onFocus = Just toMsg }


onLoseFocus : msg -> Config msg -> Config msg
onLoseFocus toMsg (Config config) =
    Config { config | onLoseFocus = Just toMsg }


onSubmit : msg -> Config msg -> Config msg
onSubmit msg (Config config) =
    Config { config | onSubmit = Just msg }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ El.height El.fill
        , El.width El.fill
        ]
        [ introduction config.user config.room
        , El.column
            [ El.height <|
                El.maximum config.messagesContainerMaxHeight El.fill
            , El.width El.fill
            ]
            [ messagesView device (Config config)
            , membersTypingView config.membersTyping
            , form device (Config config)
            ]
        ]


introduction : User -> Room -> Element msg
introduction currentUser currentRoom =
    let
        paragraphs =
            if currentUser.id == currentRoom.owner.id then
                [ El.paragraph
                    [ El.width El.fill ]
                    [ El.text "Welcome to your room." ]
                , El.paragraph
                    [ El.width El.fill ]
                    [ El.text "When you leave the room it will close and all members will return to the lobby. "
                    , El.text "Messages will be retained until you delete the room or leave the lobby."
                    ]
                ]

            else
                [ El.paragraph
                    [ El.width El.fill ]
                    [ El.text "Welcome to "
                    , El.text currentRoom.owner.username
                    , El.text "'s room."
                    ]
                , El.paragraph
                    [ El.width El.fill ]
                    [ El.text "When "
                    , El.text currentRoom.owner.username
                    , El.text " leaves the room it will close and you will return to the lobby. "
                    , El.text "Messages will be retained until "
                    , El.text currentRoom.owner.username
                    , El.text " deletes the room or leaves the lobby."
                    ]
                ]
    in
    El.column
        [ El.htmlAttribute <|
            Attr.id "introduction"
        , El.width El.fill
        , El.spacing 10
        , El.paddingEach
            { left = 0
            , top = 0
            , right = 0
            , bottom = 10
            }
        ]
        paragraphs


membersTypingView : List String -> Element msg
membersTypingView membersTyping_ =
    if membersTyping_ == [] then
        El.none

    else
        El.paragraph
            [ El.paddingEach
                { left = 0
                , top = 10
                , right = 0
                , bottom = 0
                }
            , El.width El.fill
            , Font.alignLeft
            ]
            [ El.el
                [ Font.bold ]
                (El.text "Members Typing: ")
            , List.intersperse ", " membersTyping_
                |> String.concat
                |> El.text
            ]



{- Messages -}


messagesView : Device -> Config msg -> Element msg
messagesView device (Config config) =
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
            |> Messages.user config.user
            |> Messages.messages config.messages
            |> Messages.view device
        )



{- Form -}


form : Device -> Config msg -> Element msg
form device (Config config) =
    MessageForm.init
        |> MessageForm.text config.userText
        |> MessageForm.onChange config.onChange
        |> MessageForm.onFocus config.onFocus
        |> MessageForm.onLoseFocus config.onLoseFocus
        |> MessageForm.onSubmit config.onSubmit
        |> MessageForm.view device
