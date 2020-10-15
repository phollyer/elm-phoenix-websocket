module Example exposing
    ( Action(..)
    , Config
    , Example(..)
    , applicableFunctions
    , controls
    , description
    , init
    , toAction
    , toString
    , usefulFunctions
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Page
import Phoenix



{- Init -}


init : Config msg
init =
    { description = El.none
    , controls = El.none
    , applicableFunctions = El.none
    , usefulFunctions = El.none
    }



{- Model -}


type alias Config msg =
    { description : Element msg
    , controls : Element msg
    , applicableFunctions : Element msg
    , usefulFunctions : Element msg
    }


type Action
    = Anything
    | Connect
    | Disconnect
    | On


type Example
    = SimpleConnect Action
    | ConnectWithGoodParams Action
    | ConnectWithBadParams Action
    | ManageSocketHeartbeat Action


toString : Example -> String
toString example =
    case example of
        SimpleConnect _ ->
            "Simple Connect"

        ConnectWithGoodParams _ ->
            "Connect with Good Params"

        ConnectWithBadParams _ ->
            "Connect with Bad Params"

        ManageSocketHeartbeat _ ->
            "Manage the Socket Hearbeat"


toAction : Example -> Action
toAction example =
    case example of
        SimpleConnect action ->
            action

        ConnectWithGoodParams action ->
            action

        ConnectWithBadParams action ->
            action

        ManageSocketHeartbeat action ->
            action



{- View -}


view : Config msg -> Element msg
view config =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        ]
        [ El.column
            [ El.width El.fill
            , El.spacing 20
            ]
            [ config.description
            , config.controls
            ]
        , El.row
            [ El.width El.fill
            , El.spacing 10
            ]
            [ config.applicableFunctions
            , config.usefulFunctions
            ]
        ]


description : List (Element msg) -> Config msg -> Config msg
description desc config =
    { config
        | description =
            El.column
                [ El.spacing 12
                , Font.color Color.darkslateblue
                , Font.justify
                , Font.size 30
                , Font.family
                    [ Font.typeface "Varela Round" ]
                ]
                desc
    }


controls : Element msg -> Config msg -> Config msg
controls cntrls config =
    { config
        | controls = cntrls
    }


applicableFunctions : List String -> Config msg -> Config msg
applicableFunctions functions config =
    { config
        | applicableFunctions =
            El.column
                [ Background.color Color.white
                , Border.width 1
                , Border.color Color.black
                , El.height El.fill
                , El.padding 10
                , El.spacing 10
                , El.centerX
                ]
            <|
                El.el
                    [ Font.bold
                    , Font.underline
                    , Font.color Color.darkslateblue
                    ]
                    (El.text "Applicable Functions")
                    :: List.map
                        (\function ->
                            El.newTabLink
                                [ Font.family [ Font.typeface "Roboto Mono" ] ]
                                { url = toPackageUrl function
                                , label =
                                    El.paragraph
                                        []
                                        (format function)
                                }
                        )
                        functions
    }


toPackageUrl : String -> String
toPackageUrl function =
    let
        base =
            "https://package.elm-lang.org/packages/phollyer/elm-phoenix-websocket/latest/Phoenix"
    in
    case String.split "." function of
        _ :: func :: [] ->
            base ++ "#" ++ func

        func :: [] ->
            base ++ "#" ++ func

        _ ->
            base


format : String -> List (Element msg)
format function =
    case String.split "." function of
        phoenix :: func :: [] ->
            [ El.el [ Font.color Color.orange ] (El.text phoenix)
            , El.el [ Font.color Color.darkgrey ] (El.text ("." ++ func))
            ]

        func :: [] ->
            [ El.el [ Font.color Color.darkgrey ] (El.text ("." ++ func))
            ]

        _ ->
            []


usefulFunctions : List ( String, String ) -> Config msg -> Config msg
usefulFunctions functions config =
    { config
        | usefulFunctions =
            El.column
                [ Background.color Color.white
                , Border.width 1
                , Border.color Color.black
                , El.height El.fill
                , El.padding 10
                , El.spacing 10
                , El.centerX
                ]
                [ El.el
                    [ El.centerX
                    , Font.bold
                    , Font.underline
                    , Font.color Color.darkslateblue
                    ]
                    (El.text "Useful Functions")
                , El.row
                    [ El.width El.fill ]
                    [ El.el
                        [ El.width El.fill ]
                        (El.el
                            [ Font.bold
                            , Font.color Color.darkslateblue
                            ]
                            (El.text "Function")
                        )
                    , El.el
                        [ El.width El.fill ]
                        (El.el
                            [ El.alignRight
                            , Font.bold
                            , Font.color Color.darkslateblue
                            ]
                            (El.text "Current Value")
                        )
                    ]
                , El.column
                    [ El.width El.fill
                    , El.spacing 10
                    ]
                    (List.map
                        (\( function, value ) ->
                            El.row
                                [ El.width El.fill
                                , El.spacing 20
                                ]
                                [ El.newTabLink
                                    [ Font.family [ Font.typeface "Roboto Mono" ] ]
                                    { url = toPackageUrl function
                                    , label =
                                        El.paragraph
                                            []
                                            (format function)
                                    }
                                , El.el
                                    [ El.alignRight ]
                                    (El.text value)
                                ]
                        )
                        functions
                    )
                ]
    }
