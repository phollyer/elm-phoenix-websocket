module Template.Example.PhoneLandscape exposing (render)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


render :
    { c
        | applicableFunctions : List String
        , controls : Element msg
        , description : List (Element msg)
        , id : Maybe String
        , info : List (Element msg)
        , introduction : List (Element msg)
        , menu : Element msg
        , remoteControls : List ( String, Element msg )
        , usefulFunctions : List ( String, String )
        , userId : Maybe String
    }
    -> Element msg
render config =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        ]
        [ El.column
            [ El.width El.fill
            , El.spacing 20
            ]
            [ introduction config.introduction
            , config.menu
            , description config.description
            , case config.id of
                Nothing ->
                    El.none

                Just exampleId ->
                    El.el
                        [ Font.color Color.lavender
                        , Font.family
                            [ Font.typeface "Varela Round" ]
                        ]
                        (El.text ("Example ID: " ++ exampleId))
            , case config.userId of
                Nothing ->
                    El.none

                Just userId_ ->
                    El.el
                        [ Font.color Color.lavender
                        , Font.family
                            [ Font.typeface "Varela Round" ]
                        ]
                        (El.text ("User ID: " ++ userId_))
            , config.controls
            , El.column
                [ El.width El.fill
                , El.spacing 10
                ]
              <|
                List.map
                    (\( userId_, buttons ) ->
                        El.column
                            [ El.width El.fill ]
                            [ El.el
                                [ Font.color Color.lavender
                                , Font.family
                                    [ Font.typeface "Varela Round" ]
                                ]
                                (El.text ("User ID: " ++ userId_))
                            , buttons
                            ]
                    )
                    config.remoteControls
            ]
        , El.row
            [ El.spacing 10
            , El.centerX
            ]
            [ El.el [ El.alignTop ] <| applicableFunctions config.applicableFunctions
            , El.el [ El.alignTop ] <| usefulFunctions config.usefulFunctions
            , El.el [ El.alignTop, El.width El.fill ] <| info config.info
            ]
        ]


applicableFunctions : List String -> Element msg
applicableFunctions functions =
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


description : List (Element msg) -> Element msg
description content =
    El.column
        [ El.spacing 12
        , Font.color Color.darkslateblue
        , Font.justify
        , Font.size 30
        , Font.family
            [ Font.typeface "Varela Round" ]
        ]
        content


info : List (Element msg) -> Element msg
info content =
    El.column
        [ Background.color Color.white
        , Border.width 1
        , Border.color Color.black
        , El.paddingEach
            { left = 10
            , top = 10
            , right = 10
            , bottom = 0
            }
        , El.spacing 10
        , El.centerX
        ]
        [ El.el
            [ El.centerX
            , Font.bold
            , Font.underline
            , Font.color Color.darkslateblue
            ]
            (El.text "Information")
        , El.column
            [ El.height <|
                El.maximum 300 El.shrink
            , El.clip
            , El.scrollbars
            , El.spacing 16
            ]
            content
        ]


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        [ Font.color Color.darkslateblue
        , Font.size 24
        , Font.justify
        , El.spacing 30
        , Font.family
            [ Font.typeface "Piedra" ]
        ]
        intro


usefulFunctions : List ( String, String ) -> Element msg
usefulFunctions functions =
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
