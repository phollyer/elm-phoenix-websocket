module Template.Menu.Default exposing (render)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font


type alias Config msg =
    { options : List ( String, msg )
    , selected : String
    }


render : Config msg -> Element msg
render config =
    El.el
        [ Border.widthEach
            { left = 0
            , top = 1
            , right = 0
            , bottom = 1
            }
        , Border.color Color.aliceblue
        , El.paddingEach
            { left = 5
            , top = 10
            , right = 5
            , bottom = 0
            }
        , El.width El.fill
        , Font.family
            [ Font.typeface "Varela Round" ]
        ]
        (El.wrappedRow
            [ El.centerX
            , El.spacing 20
            ]
            (List.map (menuItem config.selected) config.options)
        )


menuItem : String -> ( String, msg ) -> Element msg
menuItem selected ( item, msg ) =
    let
        ( attrs, highlight ) =
            if selected == item then
                ( [ Font.color Color.darkslateblue
                  , El.spacing 5
                  ]
                , El.el
                    [ Border.width 2
                    , Border.color Color.aliceblue
                    , El.width El.fill
                    ]
                    El.none
                )

            else
                ( [ Font.color Color.darkslateblue
                  , El.paddingEach
                        { left = 0
                        , top = 0
                        , right = 0
                        , bottom = 5
                        }
                  , Border.widthEach
                        { left = 0
                        , top = 0
                        , right = 0
                        , bottom = 4
                        }
                  , Border.color Color.skyblue
                  , El.pointer
                  , Event.onClick msg
                  , El.mouseOver
                        [ Border.color Color.lavender ]
                  ]
                , El.none
                )
    in
    El.column
        attrs
        [ El.text item
        , highlight
        ]
