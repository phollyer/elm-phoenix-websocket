module Template.Example.Tablet exposing (view)

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
        , config.menu
        , description config.description
        , maybeId "Example" config.id
        , config.controls
        , remoteControls config.remoteControls
        , config.feedback
        ]



{- Introduction -}


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        (List.append
            [ Font.size 24
            , El.spacing 30
            ]
            Common.introductionAttrs
        )
        intro



{- Description -}


description : List (Element msg) -> Element msg
description content =
    El.paragraph
        (List.append
            [ Font.size 24
            , El.paddingEach
                { left = 0
                , top = 10
                , right = 0
                , bottom = 0
                }
            ]
            Common.descriptionAttrs
        )
        content



{- Example ID -}


maybeId : String -> Maybe String -> Element msg
maybeId type_ maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id ->
            El.paragraph
                (Font.size 20
                    :: Common.idAttrs
                )
                [ El.el Common.idLabelAttrs (El.text (type_ ++ " ID: "))
                , El.el Common.idValueAttrs (El.text id)
                ]



{- Remote Controls -}


remoteControls : List (Element msg) -> Element msg
remoteControls cntrls =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        cntrls
