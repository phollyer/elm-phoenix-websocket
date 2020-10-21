module Page.Blank exposing (view)

import Html exposing (Html)
import View.Layout as Layout


view : { title : String, content : Html msg }
view =
    { title = ""
    , content =
        Layout.init
            |> Layout.render Layout.Blank
    }
