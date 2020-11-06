module Template.ExamplePage.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Template.ExamplePage.Common as Common


view : Common.Config msg c -> Element msg
view config =
    El.column
        Common.containerAttrs
        [ introduction config.introduction
        , menu config.menu
        , example config.example
        , maybeId config.id
        ]



{- Introduction -}


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        (List.append
            [ Font.size 16
            , El.spacing 18
            ]
            Common.introductionAttrs
        )
        intro



{- Menu -}


menu : Element msg -> Element msg
menu menu_ =
    El.el
        (Font.size 16
            :: Common.menuAttrs
        )
        menu_



{- Example -}


example : Element msg -> Element msg
example content =
    El.el
        (Font.size 16
            :: Common.exampleAttrs
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
                (Font.size 16
                    :: Common.idAttrs
                )
                [ El.el Common.idLabelAttrs (El.text "Example ID: ")
                , El.el Common.idValueAttrs (El.text id)
                ]
