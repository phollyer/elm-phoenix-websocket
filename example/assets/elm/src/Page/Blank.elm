module Page.Blank exposing (view)

import Element as El exposing (Element)


view : { title : String, content : Element msg }
view =
    { title = ""
    , content = El.none
    }
