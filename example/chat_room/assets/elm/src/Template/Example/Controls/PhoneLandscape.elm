module Template.Example.Controls.PhoneLandscape exposing (..)

import Colors.Opaque as Color
import Element as El exposing (DeviceClass, Element, Orientation)
import Element.Border as Border
import Template.Example.Controls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    El.column [ El.width El.fill ]
        [ El.el [] (Common.maybeId "User" config.userId)
        , El.row
            (List.append
                [ El.spacing 10
                , El.paddingXY 0 10
                , Border.widthEach
                    { left = 0
                    , top = 1
                    , right = 0
                    , bottom = 1
                    }
                ]
                Common.containerAttrs
            )
            [ El.row
                [ El.centerX
                , El.spacing 30
                ]
                config.elements
            ]
        ]
