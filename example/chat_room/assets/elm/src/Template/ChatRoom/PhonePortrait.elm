module Template.ChatRoom.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


type alias Config msg c =
    { c
        | introduction : List (List (Element msg))
        , messageForm : Element msg
        , membersTyping : List String
        , messages : Element msg
    }


view : Device -> Config msg c -> Element msg
view { height } config =
    El.column
        [ El.spacing 10
        , El.height El.fill
        , El.width El.fill
        ]
    <|
        List.append
            (introduction config.introduction)
            [ El.column
                [ El.alignBottom
                , El.spacing 10
                , El.width El.fill
                , El.height <|
                    El.maximum (height - 120) El.fill
                ]
                [ messages height config.messages
                , membersTypingView config.membersTyping
                , form config.messageForm
                ]
            ]


introduction : List (List (Element msg)) -> List (Element msg)
introduction intro =
    List.map
        (El.paragraph
            [ El.width El.fill
            , El.height El.shrink
            ]
        )
        intro


messages : Int -> Element msg -> Element msg
messages height element =
    El.el
        [ El.height El.fill
        , El.width El.fill
        , El.clipY
        , El.scrollbarY
        ]
        element


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
