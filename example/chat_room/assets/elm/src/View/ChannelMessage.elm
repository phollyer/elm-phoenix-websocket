module View.ChannelMessage exposing (..)


type Config msg
    = Config
        { topic : String
        , event : String
        , payload : String
        , joinRef : String
        , ref : String
        }


init : Config msg
init =
    Config
        { topic = ""
        , event = ""
        , payload = ""
        , joinRef = ""
        , ref = ""
        }
