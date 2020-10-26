module View.Controls exposing
    ( Config
    , elements
    , init
    , layouts
    , order
    , userId
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Controls.PhoneLandscape as PhoneLandscape
import Template.Controls.PhonePortrait as PhonePortrait
import View.Utils as Utils


type Config msg
    = Config
        { userId : Maybe String
        , elements : List (Element msg)
        , layout : Maybe (List Int)
        , layouts : List ( DeviceClass, Orientation, List Int )
        , order : List ( DeviceClass, Orientation, List Int )
        }


init : Config msg
init =
    Config
        { userId = Nothing
        , elements = []
        , layout = Nothing
        , layouts = []
        , order = []
        }


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            Utils.orderElementsForDevice device config
                |> Utils.layoutForDevice device
                |> PhonePortrait.view

        _ ->
            Utils.orderElementsForDevice device config
                |> Utils.layoutForDevice device
                |> PhoneLandscape.view


{-| -}
userId : Maybe String -> Config msg -> Config msg
userId maybeId (Config config) =
    Config { config | userId = maybeId }


elements : List (Element msg) -> Config msg -> Config msg
elements list (Config config) =
    Config { config | elements = list }


layouts : List ( DeviceClass, Orientation, List Int ) -> Config msg -> Config msg
layouts list (Config config) =
    Config { config | layouts = list }


order : List ( DeviceClass, Orientation, List Int ) -> Config msg -> Config msg
order list (Config config) =
    Config { config | order = list }
