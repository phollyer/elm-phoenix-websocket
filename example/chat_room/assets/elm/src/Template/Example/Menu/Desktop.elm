module Template.Example.Menu.Desktop exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Template.Example.Menu.Common as Common


view : Common.Config msg c -> Element msg
view config =
    El.wrappedRow
        (List.append
            [ El.paddingEach
                { left = 5
                , top = 10
                , right = 5
                , bottom = 0
                }
            , El.spacing 20
            , Font.size 20
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
