module Example exposing
    ( Action(..)
    , Config
    , Example(..)
    , applicableFunctions
    , controls
    , description
    , fromString
    , id
    , info
    , init
    , remoteControls
    , toAction
    , toString
    , usefulFunctions
    , userId
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
    { id = Nothing
    , userId = Nothing
    , description = El.none
    , controls = El.none
    , remoteControls = []
    , info = El.none
    , applicableFunctions = El.none
    , usefulFunctions = El.none
    }



{- Model -}


type alias Config msg =
    { id : Maybe String
    , userId : Maybe String
    , description : Element msg
    , controls : Element msg
    , remoteControls : List ( String, Element msg )
    , info : Element msg
    , applicableFunctions : Element msg
    , usefulFunctions : Element msg
    }


type Action
    = Anything
    | Connect
    | Disconnect
    | Join
    | Leave
    | On
    | Off
    | Send


type Example
    = SimpleConnect Action
    | ConnectWithGoodParams Action
    | ConnectWithBadParams Action
    | ManageSocketHeartbeat Action
    | ManageChannelMessages Action
    | ManagePresenceMessages Action


fromString : String -> Example
fromString example =
    case example of
        "SimpleConnect" ->
            SimpleConnect Anything

        "ConnectWithGoodParams" ->
            ConnectWithGoodParams Anything

        "ConnectWithBadParams" ->
            ConnectWithBadParams Anything

        "ManageSocketHeartbeat" ->
            ManageSocketHeartbeat Anything

        "ManageChannelMessages" ->
            ManageChannelMessages Anything

        "ManagePresenceMessages" ->
            ManagePresenceMessages Anything

        _ ->
            SimpleConnect Anything


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
            "Manage the Socket Heartbeat"

        ManageChannelMessages _ ->
            "Manage Channel Messages"

        ManagePresenceMessages _ ->
            "Manage Presence Messages"


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

        ManageChannelMessages action ->
            action

        ManagePresenceMessages action ->
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
            [ El.el [ El.alignTop ] config.applicableFunctions
            , El.el [ El.alignTop ] config.usefulFunctions
            , El.el [ El.alignTop, El.width El.fill ] config.info
            ]
        ]


id : Maybe String -> Config msg -> Config msg
id maybeId config =
    { config
        | id = maybeId
    }


userId : Maybe String -> Config msg -> Config msg
userId maybeId config =
    { config
        | userId = maybeId
    }


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


remoteControls : List ( String, Element msg ) -> Config msg -> Config msg
remoteControls list config =
    { config
        | remoteControls = list
    }


info : List (Element msg) -> Config msg -> Config msg
info content config =
    { config
        | info =
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
