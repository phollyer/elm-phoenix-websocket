module View.Menu exposing
    ( Config, init
    , Template(..), render
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
type alias Config msg =
    { options : List ( String, msg )
    , selected : String
    }


{-| -}
init : Config msg
init =
    { options = []
    , selected = ""
    }


{-| -}
type Template
    = Default


{-| -}
render : Template -> Config msg -> Element msg
render template config =
    case template of
        Default ->
            Default.render config


{-| -}
options : List ( String, msg ) -> Config msg -> Config msg
options options_ config =
    { config | options = options_ }


{-| -}
selected : String -> Config msg -> Config msg
selected selected_ config =
    { config | selected = selected_ }
