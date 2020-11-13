module Template.Messages.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Types exposing (Message, User)


type alias Config c =
    { c
        | user : User
        , messages : List Message
    }


view : Config c -> Element msg
view config =
    El.column
        [ El.spacing 10
        , El.height El.fill
        , El.width El.fill
        , Font.alignLeft
        ]
    <|
        List.map (toMessage config.user) config.messages


toMessage : User -> Message -> Element msg
toMessage user message =
    if user.id == message.owner.id then
        userMessage message

    else
        othersMessage message


userMessage : Message -> Element msg
userMessage message =
    El.row
        [ El.width El.fill ]
        [ El.el
            [ El.width <| El.fillPortion 1 ]
            El.none
        , El.column
            [ El.spacing 5
            , El.width <| El.fillPortion 5
            ]
            [ El.el
                [ El.alignRight
                , Font.color Color.darkslateblue
                ]
                (El.text message.owner.username)
            , El.column
                [ Background.color Color.darkslateblue
                , Border.rounded 10
                , El.alignRight
                , El.padding 5
                , El.spacing 10
                , Font.color Color.skyblue
                ]
                (toParagraphs message.text)
            ]
        ]


othersMessage : Message -> Element msg
othersMessage message =
    El.row
        [ El.width El.fill
        ]
        [ El.column
            [ El.spacing 5
            , El.width <| El.fillPortion 5
            ]
            [ El.el
                [ Font.color Color.darkolivegreen ]
                (El.text message.owner.username)
            , El.column
                [ Background.color Color.darkseagreen
                , Border.rounded 10
                , El.padding 5
                , El.spacing 10
                , Font.color Color.darkolivegreen
                ]
                (toParagraphs message.text)
            ]
        , El.el
            [ El.width <| El.fillPortion 1 ]
            El.none
        ]


toParagraphs : String -> List (Element msg)
toParagraphs text =
    String.split "\n" text
        |> List.map toParagraph


toParagraph : String -> Element msg
toParagraph text =
    El.paragraph
        [ El.width El.fill ]
        [ El.text text ]
