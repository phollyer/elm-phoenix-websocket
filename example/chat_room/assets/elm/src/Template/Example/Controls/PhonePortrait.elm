module Template.Example.Controls.PhonePortrait exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Template.Example.Common as Common
import Template.Example.Controls.Common as Common exposing (Config, containerAttrs)


view : Config msg c -> Element msg
view config =
    layoutFor Phone Portrait config


layoutFor : DeviceClass -> Orientation -> Config msg c -> Element msg
layoutFor class orientation config =
    case Common.layoutTypeFor class orientation config.layouts of
        Nothing ->
            El.wrappedRow attrs
                (List.map control config.elements)

        Just rows ->
            El.column attrs
                (Common.rows control
                    config.elements
                    (El.wrappedRow
                        [ El.spacing 10
                        , El.centerX
                        ]
                    )
                    rows
                )


attrs : List (Attribute msg)
attrs =
    List.append
        [ El.spacing 10
        , El.paddingXY 0 10
        , Border.widthEach
            { left = 0
            , top = 1
            , right = 0
            , bottom = 1
            }
        ]
        containerAttrs


control : Element msg -> Element msg
control item =
    El.el [ El.width El.fill ]
        item
