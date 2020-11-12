module Configs exposing
    ( joinConfig
    , pushConfig
    )

import Json.Encode as JE
import Phoenix


joinConfig : Phoenix.JoinConfig
joinConfig =
    { topic = ""
    , events = []
    , payload = JE.null
    , timeout = Nothing
    }


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , retryStrategy = Phoenix.Drop
    , timeout = Nothing
    , ref = Nothing
    }
