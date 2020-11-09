module Template.Lobby.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element, paragraph)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


type alias Config msg c =
    { c
        | introduction : List (List (Element msg))
        , form : Element msg
        , username : String
        , userId : Maybe String
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 15
        ]
    <|
        case config.userId of
            Nothing ->
                [ El.column
                    [ El.width El.fill
                    , El.spacing 10
                    ]
                  <|
                    List.map
                        (\paragraph ->
                            El.paragraph
                                [ El.width El.fill
                                , El.spacing 2
                                ]
                                paragraph
                        )
                        config.introduction
                , El.el
                    [ Border.rounded 10
                    , Background.color Color.steelblue
                    , El.padding 20
                    , El.width El.fill
                    ]
                    config.form
                ]

            Just id ->
                [ El.column
                    [ Border.rounded 10
                    , Background.color Color.steelblue
                    , El.padding 20
                    , El.spacing 10
                    , El.width El.fill
                    , Font.color Color.skyblue
                    ]
                    [ El.row
                        [ El.centerX
                        , El.spacing 10
                        ]
                        [ El.el
                            [ Font.bold ]
                            (El.text "Username:")
                        , El.el
                            []
                            (El.text config.username)
                        ]
                    , El.row
                        [ El.centerX
                        , El.spacing 10
                        ]
                        [ El.el
                            [ Font.bold ]
                            (El.text "User ID:")
                        , El.el
                            []
                            (El.text id)
                        ]
                    ]
                ]
