module Template.ChatRoom.PhoneLandscape exposing (view)

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes as Attr
import Template.ChatRoom.Common as Common exposing (Config)


view : Device -> Config msg c -> Element msg
view { height } config =
    El.column
        Common.containerAttrs
    <|
        List.append
            (introduction config.introduction)
            [ El.column
                (Common.contentAttrs (height - 150))
                [ El.el Common.messagesAttrs config.messages
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
