module Template.ExamplePage.PhonePortrait exposing (view)

import Element as El exposing (Element, paragraph)
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


introduction : List (List (Element msg)) -> Element msg
introduction intro =
    case intro of
        [] ->
            El.none

        _ ->
            El.column
                (List.append
                    [ Font.size 14
                    , El.spacing 16
                    ]
                    Common.introductionAttrs
                )
            <|
                List.map
                    (\paragraph ->
                        El.paragraph
                            [ El.width El.fill ]
                            paragraph
                    )
                    intro



{- Menu -}


menu : Element msg -> Element msg
menu element =
    if element == El.none then
        El.none

    else
        El.el
            (Font.size 14
                :: Common.menuAttrs
            )
            element



{- Example -}


example : Element msg -> Element msg
example content =
    El.el
        (Font.size 14
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
                (Font.size 14
                    :: Common.idAttrs
                )
                [ El.el Common.idLabelAttrs (El.text "Example ID: ")
                , El.el Common.idValueAttrs (El.text id)
                ]
