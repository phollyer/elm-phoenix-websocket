module View.Page exposing
    ( body
    , init
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element)
import Html exposing (Html)
import Template.Page.Desktop as Desktop
import Template.Page.Phone as Phone
import Template.Page.Tablet as Tablet


type Config msg
    = Config (Element msg)


init : Config msg
init =
    Config El.none


view : Device -> Config msg -> Html msg
view { class } (Config config) =
    case class of
        Phone ->
            Phone.view config

        Tablet ->
            Tablet.view config

        _ ->
            Desktop.view config


body : Element msg -> Config msg -> Config msg
body body_ (Config _) =
    Config body_
