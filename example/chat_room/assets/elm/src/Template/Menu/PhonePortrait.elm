module Template.Menu.PhonePortrait exposing (..)

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
            , top = 16
            , right = 5
            , bottom = 8
            }
        , El.width El.fill
        , Font.size 18
        , Font.family
            [ Font.typeface "Varela Round" ]
        ]
        (El.column
            [ El.spacing 10
            , El.width El.fill
            ]
            (List.map (menuItem config.selected) config.options)
        )


menuItem : String -> ( String, msg ) -> Element msg
menuItem selected ( item, msg ) =
    let
        ( attrs, highlight ) =
            if selected == item then
                ( [ Font.color Color.darkslateblue
                  , El.centerX
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
                  , El.centerX
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
