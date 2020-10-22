module View.Example exposing
    ( Config, init
    , render
    , applicableFunctions, controls, description, id, info, introduction, menu, remoteControls, usefulFunctions, userId
    )

{-| This module is intended to enable building up an example with pipelines and
then passing off the example config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, render

@docs applicableFunctions, controls, description, id, info, introduction, menu, remoteControls, usefulFunctions, userId

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Example.Desktop as Desktop
import Template.Example.PhoneLandscape as PhoneLandscape
import Template.Example.PhonePortrait as PhonePortrait


{-| -}
type alias Config msg =
    { applicableFunctions : List String
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


{-| -}
init : Config msg
init =
    { introduction = []
    , menu = El.none
    , id = Nothing
    , userId = Nothing
    , description = []
    , controls = []
    , remoteControls = []
    , info = []
    , applicableFunctions = []
    , usefulFunctions = []
    }


{-| -}
render : Device -> Config msg -> Element msg
render { class, orientation } config =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.render config

        ( Phone, Landscape ) ->
            PhoneLandscape.render config

        ( Tablet, _ ) ->
            Desktop.render config

        ( Desktop, _ ) ->
            Desktop.render config

        ( BigDesktop, _ ) ->
            Desktop.render config


{-| -}
applicableFunctions : List String -> Config msg -> Config msg
applicableFunctions functions config =
    { config
        | applicableFunctions = functions
    }


{-| -}
controls : List (Element msg) -> Config msg -> Config msg
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
introduction : List (Element msg) -> Config msg -> Config msg
introduction list config =
    { config | introduction = list }


{-| -}
menu : Element msg -> Config msg -> Config msg
menu menu_ config =
    { config | menu = menu_ }


{-| -}
remoteControls : List ( String, List (Element msg) ) -> Config msg -> Config msg
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
