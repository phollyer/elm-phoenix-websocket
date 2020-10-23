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
    = Config { body : Element msg }


init : Config msg
init =
    Config
        { body = El.none }


body : Element msg -> Config msg -> Config msg
body body_ (Config config) =
    Config { config | body = body_ }


view : Device -> Config msg -> Html msg
view { class } (Config config) =
    case class of
        Phone ->
            Phone.view config

        Tablet ->
            Tablet.view config

        _ ->
            Desktop.view config
