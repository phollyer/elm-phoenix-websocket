module Template.Controls.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Extra.List as List
import List.Extra as List
import Template.Controls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column attrs
                (userId config.userId
                    :: controls config.elements
                )

        Just layout ->
            El.column attrs
                (userId config.userId
                    :: (List.groupsOfVarying layout config.elements
                            |> List.map
                                (\elements ->
                                    El.wrappedRow
                                        [ El.spacing 10
                                        , El.centerX
                                        ]
                                    <|
                                        controls elements
                                )
                       )
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


userId : Maybe String -> Element msg
userId maybeId =
    El.el [] (Common.maybeId "User" maybeId)


controls : List (Element msg) -> List (Element msg)
controls elements =
    List.map control elements


control : Element msg -> Element msg
control item =
    El.el [ El.width El.fill ] item
