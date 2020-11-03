module Template.FeedbackInfo.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Json.Encode as JE
import Template.FeedbackInfo.Common as Common


view : Common.Config c -> Element msg
view config =
    El.column
        (El.spacing 10
            :: Common.containerAttrs
        )
        [ field "Topic: " config.topic
        , field "Event: " config.event
        , field "Payload: " (JE.encode 2 config.payload)
        , maybe "Join Ref: " config.joinRef
        , maybe "Ref: " config.ref
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


maybe : String -> Maybe String -> Element msg
maybe label maybeValue =
    case maybeValue of
        Just value ->
            field label value

        Nothing ->
            El.none
