module Template.FeedbackInfo.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Json.Encode as JE
import Template.FeedbackInfo.Common as Common exposing (maybe)


view : Common.Config c -> Element msg
view config =
    El.column
        (El.spacing 10
            :: Common.containerAttrs
        )
        [ field "Topic: " config.topic
        , maybe field "Event: " config.event
        , field "Payload: " (JE.encode 2 config.payload)
        , maybe field "Join Ref: " config.joinRef
        , maybe field "Ref: " config.ref
        ]


field : String -> String -> Element msg
field label topic_ =
    El.wrappedRow
        (List.append
            [ El.spacing 5
            , Font.size 10
            ]
            Common.fieldAttrs
        )
        [ El.el
            Common.labelAttrs
            (El.text label)
        , El.el
            (El.alignRight
                :: Common.valueAttrs
            )
            (El.text topic_)
        ]
