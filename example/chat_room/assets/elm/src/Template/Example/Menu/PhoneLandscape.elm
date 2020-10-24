module Template.Example.Menu.PhoneLandscape exposing (view)

import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font
import Template.Example.Menu.Common as Common


view : Common.Config msg c -> Element msg
view config =
    layoutFor Phone Landscape config


layoutFor : DeviceClass -> Orientation -> Common.Config msg c -> Element msg
layoutFor class orientation config =
    case Common.layoutTypeFor class orientation config.layouts of
        Nothing ->
            El.wrappedRow attrs <|
                List.map (menuItem config.selected) config.options

        Just rowItems ->
            El.column attrs <|
                Common.rows (menuItem config.selected) config.options rowItems


attrs : List (Attribute msg)
attrs =
    List.append
        [ El.paddingEach
            { left = 5
            , top = 10
            , right = 5
            , bottom = 5
            }
        , El.spacing 10
        , Font.size 18
        ]
        Common.containerAttrs


menuItem : String -> ( String, msg ) -> Element msg
menuItem selected ( item, msg ) =
    let
        ( attrs_, highlight ) =
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
            attrs_
            [ El.text item
            , highlight
            ]
        ]
