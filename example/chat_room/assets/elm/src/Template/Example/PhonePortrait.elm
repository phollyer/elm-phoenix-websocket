module Template.Example.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Template.Example.Common as Common


view : Common.Config msg c -> Element msg
view config =
    El.column
        Common.containerAttrs
        [ introduction config.introduction
        , menu config.menu
        , description config.description
        , maybeId config.id
        , controls config.controls
        , remoteControls config.remoteControls
        , config.feedback
        ]



{- Introduction -}


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        (List.append
            [ Font.size 14
            , El.spacing 16
            ]
            Common.introductionAttrs
        )
        intro



{- Menu -}


menu : Element msg -> Element msg
menu menu_ =
    El.el
        (Font.size 14
            :: Common.menuAttrs
        )
        menu_



{- Description -}


description : List (Element msg) -> Element msg
description content =
    El.column
        (Font.size 14
            :: Common.descriptionAttrs
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



{- Remote Controls -}


remoteControls : List (Element msg) -> Element msg
remoteControls cntrls =
    El.column
        (List.append
            [ El.spacing 10
            , Font.size 14
            ]
            Common.remoteControlAttrs
        )
        cntrls
