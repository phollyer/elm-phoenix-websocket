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
        , user : Maybe (Element msg)
        , members : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.width El.fill
        , El.spacing 15
        ]
    <|
        case config.user of
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

            Just user ->
                [ El.el
                    [ Border.rounded 10
                    , Background.color Color.steelblue
                    , El.padding 20
                    , El.spacing 10
                    , El.width El.fill
                    , Font.color Color.skyblue
                    ]
                    user
                , El.column
                    [ Border.rounded 10
                    , Background.color Color.steelblue
                    , El.paddingEach
                        { left = 20
                        , top = 20
                        , right = 20
                        , bottom = 0
                        }
                    , El.spacing 10
                    , El.width El.fill
                    , El.height <|
                        El.maximum 300 El.fill
                    , Font.color Color.skyblue
                    ]
                    [ El.el
                        [ El.centerX ]
                        (El.text "Members")
                    , config.members
                    ]
                ]
