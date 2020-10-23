module Template.Menu.PhoneLandscape exposing (render)

import Element as El exposing (Element)
import Element.Font as Font
import Template.Menu.Common as Common


type alias Config msg =
    { options : List ( String, msg )
    , selected : String
    }


render : Config msg -> Element msg
render config =
    El.wrappedRow
        (List.append
            [ El.paddingEach
                { left = 5
                , top = 10
                , right = 5
                , bottom = 0
                }
            , El.spacing 10
            , Font.size 18
            ]
            Common.containerAttrs
        )
        (List.map (menuItem config.selected) config.options)


menuItem : String -> ( String, msg ) -> Element msg
menuItem selected ( item, msg ) =
    let
        ( attrs, highlight ) =
            if selected == item then
                ( El.spacing 5
                    :: Common.selectedAttrs
                , El.el
                    Common.selectedHighlightAttrs
                    El.none
                )

            else
                ( Common.unselectedAttrs msg
                , El.none
                )
    in
    El.row
        [ El.width El.fill ]
        [ El.column
            attrs
            [ El.text item
            , highlight
            ]
        ]
