module View.Example exposing
    ( Config, init
    , view
    , id, introduction, menu, description, controls, remoteControls, feedback, info
    )

{-| This module is intended to enable building up an example with pipelines and
then passing off the example config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, view

@docs id, introduction, menu, description, controls, remoteControls, feedback, info

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Example.PhoneLandscape as PhoneLandscape
import Template.Example.PhonePortrait as PhonePortrait
import Template.Example.Tablet as Tablet


{-| -}
type alias Config msg =
    { id : Maybe String
    , introduction : List (Element msg)
    , menu : Element msg
    , description : List (Element msg)
    , controls : Element msg
    , remoteControls : List (Element msg)
    , feedback : Element msg
    , info : List (Element msg)
    }


{-| -}
init : Config msg
init =
    { id = Nothing
    , introduction = []
    , menu = El.none
    , description = []
    , controls = El.none
    , remoteControls = []
    , feedback = El.none
    , info = []
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
feedback : Element msg -> Config msg -> Config msg
feedback feedback_ config =
    { config
        | feedback = feedback_
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
