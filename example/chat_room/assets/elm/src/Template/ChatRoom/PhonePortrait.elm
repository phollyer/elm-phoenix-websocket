module Template.ChatRoom.PhonePortrait exposing (view)

import Colors.Opaque as Color
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


view : Config msg c -> Element msg
view config =
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
                ]
                [ config.messages
                , membersTypingView config.membersTyping
                , config.messageForm
                ]
            ]


introduction : List (List (Element msg)) -> List (Element msg)
introduction intro =
    List.map
        (El.paragraph
            [ El.width El.fill ]
        )
        intro


membersTypingView : List String -> Element msg
membersTypingView members =
    if members == [] then
        El.none

    else
        El.paragraph
            [ El.width El.fill
            , Font.alignLeft
            ]
            [ El.el
                [ Font.bold ]
                (El.text "Members Typing: ")
            , List.intersperse ", " members
                |> String.concat
                |> El.text
            ]
