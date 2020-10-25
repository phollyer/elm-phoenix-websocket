module View.Example exposing
    ( Config, init
    , view
    , applicableFunctions, controls, description, id, info, introduction, menu, remoteControls, usefulFunctions
    )

{-| This module is intended to enable building up an example with pipelines and
then passing off the example config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, view

@docs applicableFunctions, controls, description, id, info, introduction, menu, remoteControls, usefulFunctions, userId

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Example.PhoneLandscape as PhoneLandscape
import Template.Example.PhonePortrait as PhonePortrait
import Template.Example.Tablet as Tablet


{-| -}
type alias Config msg =
    { applicableFunctions : List String
    , controls : Element msg
    , description : List (Element msg)
    , id : Maybe String
    , info : List (Element msg)
    , introduction : List (Element msg)
    , menu : Element msg
    , remoteControls : List (Element msg)
    , usefulFunctions : List ( String, String )
    }


{-| -}
init : Config msg
init =
    { introduction = []
    , menu = El.none
    , id = Nothing
    , description = []
    , controls = El.none
    , remoteControls = []
    , info = []
    , applicableFunctions = []
    , usefulFunctions = []
    }


{-| -}
view : Device -> Config msg -> Element msg
view { class, orientation } config =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        _ ->
            Tablet.view config


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
introduction : List (Element msg) -> Config msg -> Config msg
introduction list config =
    { config | introduction = list }


{-| -}
menu : Element msg -> Config msg -> Config msg
menu menu_ config =
    { config | menu = menu_ }


{-| -}
remoteControls : List (Element msg) -> Config msg -> Config msg
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
