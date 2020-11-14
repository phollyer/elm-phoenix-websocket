module View.FeedbackPanel exposing
    ( Config
    , init
    , scrollable
    , static
    , title
    , view
    )

import Device exposing (Device)
import Element exposing (DeviceClass(..), Element, Orientation(..))
import Template.FeedbackPanel.PhoneLandscape as PhoneLandscape
import Template.FeedbackPanel.PhonePortrait as PhonePortrait
import Template.FeedbackPanel.TabletLandscape as TabletLandscape
import Template.FeedbackPanel.TabletPortrait as TabletPortrait


type Config msg
    = Config
        { title : String
        , static : List (Element msg)
        , scrollable : List (Element msg)
        }


init : Config msg
init =
    Config
        { title = ""
        , static = []
        , scrollable = []
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        ( Tablet, Portrait ) ->
            TabletPortrait.view config

        _ ->
            TabletLandscape.view config


title : String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


scrollable : List (Element msg) -> Config msg -> Config msg
scrollable scrollable_ (Config config) =
    Config { config | scrollable = scrollable_ }


static : List (Element msg) -> Config msg -> Config msg
static static_ (Config config) =
    Config { config | static = static_ }
