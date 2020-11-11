module Template.Example.PhonePortrait exposing (view)

import Element as El exposing (Element, paragraph)
import Element.Font as Font
import Template.Example.Common as Common


view : Common.Config msg c -> Element msg
view config =
    El.column
        Common.containerAttrs
        [ description config.description
        , maybeId config.id
        , controls config.controls
        , config.feedback
        ]



{- Description -}


description : List (List (Element msg)) -> Element msg
description content =
    El.column
        (Font.size 14
            :: Common.descriptionAttrs
        )
    <|
        List.map
            (\paragraph ->
                El.paragraph
                    [ El.width El.fill ]
                    paragraph
            )
            content



{- Example ID -}


maybeId : Maybe String -> Element msg
maybeId maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id ->
            El.paragraph
                (Font.size 14
                    :: Common.idAttrs
                )
                [ El.el Common.idLabelAttrs (El.text "Example ID: ")
                , El.el Common.idValueAttrs (El.text id)
                ]



{- Controls -}


controls : Element msg -> Element msg
controls controls_ =
    El.el
        (Font.size 14
            :: Common.controlsAttrs
        )
        controls_
