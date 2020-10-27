module Template.ChannelMessage.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Json.Encode as JE exposing (Value)


type alias Config c =
    { c
        | topic : String
        , event : String
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
    }


view : Config c -> Element msg
view config =
    El.column
        [ El.spacing 10
        , El.width El.fill
        , El.alignLeft
        ]
        [ container "Topic: " config.topic
        , container "Event: " config.event
        , container "Payload: " (JE.encode 2 config.payload)
        , container "Join Ref: " (Maybe.withDefault "Nothing" config.joinRef)
        , container "Ref: " (Maybe.withDefault "Nothing" config.ref)
        ]


container : String -> String -> Element msg
container label topic_ =
    El.wrappedRow
        [ El.width El.fill
        , El.spacing 5
        ]
        [ El.el
            [ Font.color Color.darkslateblue
            , El.alignTop
            ]
            (El.text label)
        , El.el
            [ El.width El.fill ]
            (El.text topic_)
        ]
