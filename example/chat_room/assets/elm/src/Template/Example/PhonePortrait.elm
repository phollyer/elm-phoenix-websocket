module Template.Example.PhonePortrait exposing (render)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Template.Example.Common as Common


render :
    { c
        | applicableFunctions : List String
        , controls : List (Element msg)
        , description : List (Element msg)
        , id : Maybe String
        , info : List (Element msg)
        , introduction : List (Element msg)
        , menu : Element msg
        , remoteControls : List ( String, List (Element msg) )
        , usefulFunctions : List ( String, String )
        , userId : Maybe String
    }
    -> Element msg
render config =
    El.column
        Common.containerAttrs
        [ introduction config.introduction
        , config.menu
        , description config.description
        , maybeId "Example" config.id
        , maybeId "User" config.userId
        , controls config.controls
        , remoteControls config.remoteControls
        , info config.info
        , applicableFunctions config.applicableFunctions
        , usefulFunctions config.usefulFunctions
        ]



{- Introduction -}


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        (List.append
            [ Font.size 18
            , El.spacing 20
            ]
            Common.introductionAttrs
        )
        intro



{- Description -}


description : List (Element msg) -> Element msg
description content =
    El.column
        (Font.size 16
            :: Common.descriptionAttrs
        )
        content



{- Example & User ID -}


maybeId : String -> Maybe String -> Element msg
maybeId type_ maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id ->
            El.paragraph
                (List.append
                    [ Font.center
                    , Font.size 16
                    ]
                    Common.exampleIdAttrs
                )
                [ El.el [ Font.color Color.lavender ] (El.text (type_ ++ " ID: "))
                , El.el [ Font.color Color.powderblue ] (El.text id)
                ]



{- Controls -}


controls : List (Element msg) -> Element msg
controls cntrls =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
    <|
        List.map
            (El.el
                [ El.centerX
                , El.height <| El.px 60
                ]
            )
            cntrls



{- Remote Controls -}


remoteControls : List ( String, List (Element msg) ) -> Element msg
remoteControls cntrls =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
    <|
        List.map remoteControl cntrls


remoteControl : ( String, List (Element msg) ) -> Element msg
remoteControl ( userId_, cntrls ) =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        [ maybeId "User" (Just userId_)
        , controls cntrls
        ]



{- Info -}


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
        , Font.size 18
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



{- Applicable Functions -}


applicableFunctions : List String -> Element msg
applicableFunctions functions =
    El.column
        [ Background.color Color.white
        , Border.width 1
        , Border.color Color.black
        , El.width El.fill
        , El.spacing 10
        , El.padding 10
        , Font.size 16
        ]
    <|
        El.el
            [ Font.bold
            , Font.underline
            , Font.color Color.darkslateblue
            , El.width El.fill
            ]
            (El.el [ El.centerX ] (El.text "Applicable Functions"))
            :: List.map
                (\function ->
                    El.row
                        [ El.width El.fill
                        , El.scrollbars
                        ]
                        [ El.newTabLink
                            [ Font.family [ Font.typeface "Roboto Mono" ] ]
                            { url = toPackageUrl function
                            , label =
                                El.paragraph
                                    []
                                    (format function)
                            }
                        ]
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



{- Useful Functions -}


usefulFunctions : List ( String, String ) -> Element msg
usefulFunctions functions =
    El.column
        [ Background.color Color.white
        , Border.width 1
        , Border.color Color.black
        , El.width El.fill
        , El.spacing 10
        , El.padding 10
        , Font.size 16
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
                        , El.spacing 10
                        ]
                        [ El.row
                            [ El.width El.fill
                            , El.scrollbars
                            ]
                            [ El.newTabLink
                                [ Font.family [ Font.typeface "Roboto Mono" ] ]
                                { url = toPackageUrl function
                                , label =
                                    El.paragraph
                                        []
                                        (format function)
                                }
                            ]
                        , El.row
                            []
                            [ El.text value ]
                        ]
                )
                functions
            )
        ]
