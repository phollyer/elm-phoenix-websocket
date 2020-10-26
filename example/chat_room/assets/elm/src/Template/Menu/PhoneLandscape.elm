module Template.Menu.PhoneLandscape exposing (view)

import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font
import Template.Example.Common exposing (layoutTypeFor, toRows)
import Template.Menu.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case layoutTypeFor Phone Landscape config.layouts of
        Nothing ->
            El.wrappedRow attrs <|
                List.map (menuItem config.selected) config.options

        Just rowItems ->
            El.column attrs <|
                toRows (menuItem config.selected) config.options (El.row [ El.width El.fill ]) rowItems


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
