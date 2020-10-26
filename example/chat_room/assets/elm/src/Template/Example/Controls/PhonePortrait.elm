module Template.Example.Controls.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Template.Example.Common exposing (layoutTypeFor, toRows)
import Template.Example.Controls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case layoutTypeFor Phone Portrait config.layouts of
        Nothing ->
            El.column attrs
                (El.el [] (Common.maybeId "User" config.userId)
                    :: List.map control config.elements
                )

        Just rows ->
            El.column attrs
                (El.el [] (Common.maybeId "User" config.userId)
                    :: toRows control
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
        Common.containerAttrs


control : Element msg -> Element msg
control item =
    El.el [ El.width El.fill ]
        item
