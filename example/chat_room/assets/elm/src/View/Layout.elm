module View.Layout exposing
    ( Config, init
    , Template(..), render
    , homeMsg, title, body
    )

{-| This module is intended to enable building up a page with pipelines and
then passing off the page config to the chosen template.

@docs Config, init

@docs Template, render

@docs homeMsg, title, body, home

-}

import Element as El exposing (Element)
import Template.Layout.App as App
import Template.Layout.Blank as Blank
import Template.Layout.NotFound as NotFound


{-| -}
type Config msg
    = Config
        { homeMsg : Maybe msg
        , title : String
        , body : Element msg
        }


{-| -}
init : Config msg
init =
    Config
        { homeMsg = Nothing
        , title = ""
        , body = El.none
        }


{-| -}
type Template
    = Example
    | Home
    | Blank
    | NotFound


{-| -}
render : Template -> Config msg -> Element msg
render template (Config config) =
    case template of
        Home ->
            App.render config

        Example ->
            App.render config

        Blank ->
            Blank.render

        NotFound ->
            NotFound.render


{-| -}
homeMsg : Maybe msg -> Config msg -> Config msg
homeMsg msg (Config config) =
    Config
        { config | homeMsg = msg }


{-| -}
title : String -> Config msg -> Config msg
title text (Config config) =
    Config
        { config | title = text }


{-| -}
body : Element msg -> Config msg -> Config msg
body body_ (Config config) =
    Config
        { config | body = body_ }
