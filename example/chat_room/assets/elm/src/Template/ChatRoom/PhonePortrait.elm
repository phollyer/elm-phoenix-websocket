module Template.ChatRoom.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Types exposing (Message, Room)


type alias Config msg c =
    { c
        | room : Room
        , introduction : List (List (Element msg))
        , messageForm : Element msg
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
            [ config.messageForm ]


introduction : List (List (Element msg)) -> List (Element msg)
introduction intro =
    List.map
        (El.paragraph
            [ El.width El.fill ]
        )
        intro


roomView : Room -> Element msg
roomView room =
    El.column
        [ Background.color Color.aliceblue
        , Border.rounded 5
        , El.width El.fill
        , El.height El.fill
        ]
        (messagesView room.messages)


messagesView : List Message -> List (Element msg)
messagesView messages =
    []
