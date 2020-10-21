module View.Example exposing
    ( Config, init
    , Template(..), render
    , applicableFunctions, controls, description, id, info, remoteControls, usefulFunctions, userId
    )

{-| This module is intended to enable building up an example with pipelines and
then passing off the example config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, render

@docs applicableFunctions, controls, description, id, info, remoteControls, usefulFunctions, userId

-}

import Element as El exposing (Element)
import Template.Example.Default as Default


{-| -}
type alias Config msg =
    { applicableFunctions : List String
    , controls : Element msg
    , description : List (Element msg)
    , id : Maybe String
    , info : List (Element msg)
    , remoteControls : List ( String, Element msg )
    , usefulFunctions : List ( String, String )
    , userId : Maybe String
    }


{-| -}
init : Config msg
init =
    { id = Nothing
    , userId = Nothing
    , description = []
    , controls = El.none
    , remoteControls = []
    , info = []
    , applicableFunctions = []
    , usefulFunctions = []
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
applicableFunctions : List String -> Config msg -> Config msg
applicableFunctions functions config =
    { config
        | applicableFunctions = functions
    }


{-| -}
controls : Element msg -> Config msg -> Config msg
controls cntrls config =
    { config
        | controls = cntrls
    }


{-| -}
description : List (Element msg) -> Config msg -> Config msg
description desc config =
    { config
        | description = desc
    }


{-| -}
id : Maybe String -> Config msg -> Config msg
id maybeId config =
    { config
        | id = maybeId
    }


{-| -}
info : List (Element msg) -> Config msg -> Config msg
info content config =
    { config
        | info = content
    }


{-| -}
remoteControls : List ( String, Element msg ) -> Config msg -> Config msg
remoteControls list config =
    { config
        | remoteControls = list
    }


{-| -}
usefulFunctions : List ( String, String ) -> Config msg -> Config msg
usefulFunctions functions config =
    { config
        | usefulFunctions = functions
    }


{-| -}
userId : Maybe String -> Config msg -> Config msg
userId maybeId config =
    { config
        | userId = maybeId
    }
