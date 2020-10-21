module View.Menu exposing
    ( Template(..)
    , init
    , options
    , render
    , selected
    )

import Element exposing (Element)
import Template.Menu.Default as Default


type Template
    = Default


type alias Config msg =
    { options : List ( String, msg )
    , selected : String
    }


init : Config msg
init =
    { options = []
    , selected = ""
    }


render : Template -> Config msg -> Element msg
render template config =
    case template of
        Default ->
            Default.render config


options : List ( String, msg ) -> Config msg -> Config msg
options options_ config =
    { config | options = options_ }


selected : String -> Config msg -> Config msg
selected selected_ config =
    { config | selected = selected_ }
