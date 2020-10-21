module Page.Blank exposing (view)

import Element exposing (Element)
import View.Layout as Layout


view : { title : String, content : Element msg }
view =
    { title = ""
    , content =
        Layout.init
            |> Layout.render Layout.Blank
    }
