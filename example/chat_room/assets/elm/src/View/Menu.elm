module View.Menu exposing
    ( Config, init
    , render
    , options, selected
    )

{-| This module is intended to enable building up a menu with pipelines and
then passing off the menu config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, render

@docs options, selected

-}

import Element exposing (Element)
import Template.Menu.Default as Default


{-| -}
type Config msg
    = Config
        { options : List ( String, msg )
        , selected : String
        }


{-| -}
init : Config msg
init =
    Config
        { options = []
        , selected = ""
        }


{-| -}
render : Config msg -> Element msg
render (Config config) =
    Default.render config


{-| -}
options : List ( String, msg ) -> Config msg -> Config msg
options options_ (Config config) =
    Config { config | options = options_ }


{-| -}
selected : String -> Config msg -> Config msg
selected selected_ (Config config) =
    Config { config | selected = selected_ }
