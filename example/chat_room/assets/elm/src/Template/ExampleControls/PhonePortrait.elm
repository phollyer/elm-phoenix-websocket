module Template.ExampleControls.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Extra.List as List
import List.Extra as List
import Template.ExampleControls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column Common.containerAttrs
                (userId config.userId
                    :: controls config.elements
                )

        Just layout ->
            El.column Common.containerAttrs
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


userId : Maybe String -> Element msg
userId maybeId =
    El.el [] (Common.maybeId "User" maybeId)


controls : List (Element msg) -> List (Element msg)
controls elements =
    List.map control elements


control : Element msg -> Element msg
control item =
    El.el [ El.width El.fill ] item
