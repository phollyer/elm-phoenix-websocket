module Template.Menu.PhoneLandscape exposing (view)

import Element as El exposing (Attribute, Element)
import List.Extra as List
import Template.Menu.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.wrappedRow attrs <|
                menuItems config

        Just layout ->
            El.column attrs <|
                (List.groupsOfVarying layout config.options
                    |> List.map
                        (\options ->
                            El.row
                                [ El.width El.fill ]
                            <|
                                menuItems config
                        )
                )


attrs : List (Attribute msg)
attrs =
    List.append
        [ El.paddingEach
            { left = 5
            , top = 16
            , right = 5
            , bottom = 8
            }
        , El.spacing 10
        ]
        Common.containerAttrs


menuItems : Common.Config msg c -> List (Element msg)
menuItems { selected, options, onClick } =
    List.map (menuItem selected onClick) options


menuItem : String -> Maybe (String -> msg) -> String -> Element msg
menuItem selected onClick item =
    let
        ( attrs_, highlight ) =
            if selected == item then
                ( Common.selectedAttrs
                , El.el
                    Common.selectedHighlightAttrs
                    El.none
                )

            else
                ( Common.unselectedAttrs onClick item
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
