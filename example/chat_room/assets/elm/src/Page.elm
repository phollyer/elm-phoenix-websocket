module Page exposing
    ( Button
    , Page(..)
    , backButton
    , button
    , code
    , container
    , controls
    , example
    , header
    , init
    , initMenu
    , introduction
    , menu
    , menuOptions
    , paragraph
    , render
    , selectedOption
    , titleText
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Phoenix


type Page
    = Home
    | Other
    | ControlTheSocketConnection
    | HandleSocketMessages


type alias Config msg =
    { backButton : Element msg
    , title : String
    , introduction : List (Element msg)
    , menu : Menu msg
    , example : Element msg
    }


type alias Menu msg =
    { options : List ( String, msg )
    , selected : String
    }


init : Config msg
init =
    { backButton = El.none
    , title = ""
    , introduction = []
    , menu = initMenu
    , example = El.none
    }


backButton : Element msg -> Config msg -> Config msg
backButton btn config =
    { config | backButton = btn }


titleText : String -> Config msg -> Config msg
titleText text config =
    { config | title = text }


introduction : List (Element msg) -> Config msg -> Config msg
introduction list config =
    { config | introduction = list }


example : Element msg -> Config msg -> Config msg
example example_ config =
    { config | example = example_ }


menu : Menu msg -> Config msg -> Config msg
menu menu_ config =
    { config | menu = menu_ }


initMenu : Menu msg
initMenu =
    { options = []
    , selected = ""
    }


menuOptions : List ( String, msg ) -> Menu msg -> Menu msg
menuOptions options menu_ =
    { menu_ | options = options }


selectedOption : String -> Menu msg -> Menu msg
selectedOption selected menu_ =
    { menu_ | selected = selected }


view : Phoenix.Model -> Page -> { title : String, content : Element msg } -> Document msg
view phoenix page { title, content } =
    { title = title ++ " - Elm Phoenix Websocket Example"
    , body =
        [ El.layout
            [ Background.color Color.aliceblue
            , El.height El.fill
            , El.width El.fill
            , El.padding 40
            ]
            (El.el
                [ Background.color Color.skyblue
                , Border.rounded 20
                , Border.shadow
                    { size = 3
                    , blur = 10
                    , color = Color.lightblue
                    , offset = ( 0, 0 )
                    }
                , El.height El.fill
                , El.width El.fill
                , El.paddingXY 20 0
                ]
                content
            )
        ]
    }


container : List (Element msg) -> Element msg
container content =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        , El.clip
        , El.scrollbars
        ]
        content


render : Config msg -> Element msg
render config =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        , El.clip
        , El.scrollbars
        , El.inFront
            (El.el
                [ El.alignLeft
                , El.paddingXY 0 10
                ]
                config.backButton
            )
        ]
        [ header config.title
        , introductionView config.introduction
        , menuView config.menu
        , config.example
        ]


header : String -> Element msg
header title =
    El.el
        [ El.centerX
        , El.paddingEach
            { left = 0
            , top = 20
            , right = 0
            , bottom = 0
            }
        , Font.bold
        , Font.underline
        , Font.color Color.darkslateblue
        , Font.size 40
        , Font.family
            [ Font.typeface "Oswald" ]
        ]
        (El.text title)


introductionView : List (Element msg) -> Element msg
introductionView intro =
    El.column
        [ Font.color Color.darkslateblue
        , Font.size 24
        , Font.justify
        , El.spacing 30
        , Font.family
            [ Font.typeface "Piedra" ]
        ]
        intro


controls : List (Element msg) -> Element msg
controls cntrls =
    El.wrappedRow
        [ El.centerX
        , El.spacing 20
        ]
        cntrls


paragraph : List (Element msg) -> Element msg
paragraph content =
    El.paragraph
        [ El.spacing 10 ]
        content


code : String -> Element msg
code text =
    El.el
        [ Font.family [ Font.typeface "Roboto Mono" ]
        , Background.color Color.lightgrey
        , El.padding 2
        , Border.width 1
        , Border.color Color.black
        , Font.size 16
        , Font.color Color.black
        ]
        (El.text text)


menuView : Menu msg -> Element msg
menuView menu_ =
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
            (List.map (menuItem menu_.selected) menu_.options)
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


type alias Button a msg =
    { enabled : Bool
    , label : String
    , example : a
    , onPress : a -> msg
    }


button : Button a msg -> Element msg
button btn =
    let
        attrs =
            if btn.enabled then
                [ Background.color Color.darkseagreen
                , El.mouseOver <|
                    [ Border.shadow
                        { size = 1
                        , blur = 2
                        , color = Color.seagreen
                        , offset = ( 0, 0 )
                        }
                    , Font.size 31
                    ]
                , Font.color Color.darkolivegreen
                ]

            else
                [ Background.color Color.grey
                , Font.color Color.darkgrey
                ]
    in
    Input.button
        (List.append
            attrs
            [ Border.rounded 10
            , El.padding 10
            , Font.size 30
            ]
        )
        { label = El.text btn.label
        , onPress =
            if btn.enabled then
                Just (btn.onPress btn.example)

            else
                Nothing
        }
