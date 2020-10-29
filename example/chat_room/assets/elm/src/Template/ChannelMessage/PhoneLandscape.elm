module Template.ChannelMessage.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Json.Encode as JE
import Template.ChannelMessage.Common as Common


view : Common.Config c -> Element msg
view config =
    El.column
        (El.spacing 10
            :: Common.containerAttrs
        )
        [ field "Topic: " config.topic
        , field "Event: " config.event
        , field "Payload: " (JE.encode 2 config.payload)
        , field "Join Ref: " (Maybe.withDefault "Nothing" config.joinRef)
        , field "Ref: " (Maybe.withDefault "Nothing" config.ref)
        ]


field : String -> String -> Element msg
field label topic_ =
    El.wrappedRow
        (El.spacing 10
            :: Common.fieldAttrs
        )
        [ El.el
            Common.labelAttrs
            (El.text label)
        , El.el
            Common.valueAttrs
            (El.text topic_)
        ]
