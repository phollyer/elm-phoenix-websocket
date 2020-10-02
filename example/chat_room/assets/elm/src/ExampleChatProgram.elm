module ExampleChatProgram exposing
    ( Model, Message, MessageState(..), UserState(..)
    , topic
    , newMsgEvent, isTypingEvent, stoppedTypingEvent
    , connectToSocket, joinChannel, push
    , setupIncomingEvents, subscriptions
    , main
    )

{-| These docs will only discuss using the Elm-Phoenix-Websocket package in the
context of this example to provide an overview. You should read through the
source code of `ExampleChatProgram.elm` to see exactly what is going on.


# Model

@docs Model, Message, MessageState, UserState


# Channel Constants

@docs topic

The following constants are used as the first parameter to the [push](#push)
function.

@docs newMsgEvent, isTypingEvent, stoppedTypingEvent


# Outgoing Events

@docs connectToSocket, joinChannel, push


# Incoming Events

@docs setupIncomingEvents, subscriptions


# Main

@docs main

-}

import Browser
import Browser.Dom as Dom
import Color.Blue as Blue
import Color.Green as Green
import Color.Red as Red
import Element as El exposing (Color, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE
import Phoenix.Channel as Channel exposing (EventIn(..), EventOut(..))
import Phoenix.Presence as Presence exposing (EventIn(..), Presence, PresenceState)
import Phoenix.Socket as Socket exposing (EventIn(..), EventOut(..))
import Ports.Phoenix as Phx
import Task



-- Init


init : () -> ( Model, Cmd Msg )
init _ =
    ( initModel
    , Cmd.none
    )



-- Model


{-| `id` - is created by Phoenix when the user joins the channel. It is
received as the payload with the [Channel.JoinOk](Channel#EventIn) event.

`users` - are the list of users currently active, and are received as the
payload with the [Presence.State](Presence#EventIn) event. The payload is of
the type [PresenceState](Presence#PresenceState), and it is updated
automatically by Phoenix as users come and go; we just need to
[subscribe](#subscriptions) to receive incoming
[Presence events](Presence#EventIn) and update the model with each new list.

`messages` - are the list of individual [Message](#Message)s received by the
[Channel.Message](Channel#EventIn) `new_msg` event.

-}
type alias Model =
    { id : UserId
    , username : String
    , users : PresenceState
    , message : MessageText
    , messages : List Message
    , messageState : MessageState
    , userState : UserState
    , error : Error
    }


type alias Error =
    String


type alias UserId =
    String


type alias MessageText =
    String


initModel : Model
initModel =
    { id = ""
    , username = ""
    , users = []
    , message = ""
    , messages = []
    , messageState = Waiting
    , userState = NotJoined
    , error = ""
    }


{-| A type alias representing a single message that is sent from one client and
received by all connected clients.
-}
type alias Message =
    { id : UserId
    , text : MessageText
    }


{-| The current state of the message that can be sent.

`Waiting` - no text has been entered by the user, or existing text has been
deleted.

`Typing` - the text box has focus and some text has been entered by the user.
When entering this state, a [Channel.Push](Channel#EventOut) `is_typing` event
is **sent** to all clients who then **receive** a
[Channel.Message](Channel#EventIn) `is_typing` event with the users name and
id as the payload in the format `name:id` (Json encoded). This then causes the
users name in the sidebar to turn green. When exiting this state, the same
process happens but with a `stopped_typing` event which causes the users name
in the sidebar to revert to being blue for all connected clients.

`Sending` - we enter this state when the user clicks the send message button
and there is content to send. When this happens, we **send** a
[Channel.Push](Channel#EventOut) `new_msg` event with the [Message](#Message)
as the payload (Json encoded). This is then **received** by all clients as a
[Channel.Message](Channel#EventIn) `new_msg` event with the [Message](#Message)
as the payload (Json encoded).

-}
type MessageState
    = Waiting
    | Typing
    | Sending


{-| The current state of the user.

`NotJoined` - the user has not yet tried to join.

`Joining` - the user has entered their name and clicked the join button. This
causes the [Socket.Connect](Socket#EventOut) event to be **sent**, and, if
successful, then the [Socket.Opened](Socket#EventIn) event is **received**. If
unsuccessful, then a [Socket.Error](Socket#EventIn) event is **received**.

Once the socket has been opened, we can join the channel by **sending** the
[Channel.Join](Channel#EventOut) event. The channel then sends back the
[Channel.JoinOk](Channel#EventIn) event which is **received** with the user
`id` as the payload and we enter the `Joined` state.

In the real world you probably want to also handle the
[Channel.JoinError](Channel#EventIn) and [Channel.JoinTimeout](Channel#EventIn)
events too. There is no need to worry about them for this example as there is
no authentication when joining the channel, and the local connection means
there will be no timeout.

`Joined` - When we enter this state, we prepare to receive the incoming events
by sending the required [Channel.On](Channel.EventOut) events to the channel.
This does not send anything over the wire, but simply sets up the channel JS to
route the events back to Elm as they arrive from Phoenix.

_You will only **receive** [Channel.Message](Channel#EventIn) events for the
[Channel.On](Channel.EventOut) events that are setup and
[Channel.On](Channel.EventOut) events can only be set up **after** a channel
has been joined. _

-}
type UserState
    = NotJoined
    | Joining
    | Joined


{-| The topic for the channel.

Returns `"room:public"`.

-}
topic : String
topic =
    "room:public"


{-| The event that is sent to and from Phoenix to signify a new message.

Returns `"new_msg"`.

-}
newMsgEvent : String
newMsgEvent =
    "new_msg"


{-| The event that is sent to and from Phoenix to signify a user is typing.

Returns `"is_typing"`.

-}
isTypingEvent : String
isTypingEvent =
    "is_typing"


{-| The event that is sent to and from Phoenix to signify a user has stopped
typing.

Returns `"stopped_typing"`.

-}
stoppedTypingEvent : String
stoppedTypingEvent =
    "stopped_typing"



-- Update


type Msg
    = ChangedUsername String
    | ClickedJoin
    | ChangedMessage String
    | SendMessage
    | MsgTextFocusedIn
    | MsgTextFocusedOut
    | SocketMsg Socket.EventIn
    | ChannelMsg Channel.EventIn
    | PresenceMsg Presence.EventIn
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangedUsername name ->
            ( { model
                | username = name
              }
            , Cmd.none
            )

        -- Maybe connect to the socket
        ClickedJoin ->
            if String.trim model.username == "" then
                ( { model
                    | error = "You must enter a username"
                  }
                , Cmd.none
                )

            else
                ( { model
                    | userState = Joining
                  }
                , connectToSocket
                )

        -- Socket couldn't be reached
        SocketMsg (Socket.Error _) ->
            ( { model
                | error = "Application unreachable."
                , userState = NotJoined
              }
            , Cmd.none
            )

        -- Socket was opened successfully
        -- Join the channel
        SocketMsg Opened ->
            ( model
            , model.username
                |> encodeUsername
                |> joinChannel
            )

        -- Channel was joined successfully
        -- Maybe setup incoming events
        ChannelMsg (JoinOk _ payload) ->
            case JD.decodeValue (JD.field "id" JD.string) payload of
                Ok id ->
                    ( { model
                        | id = id
                        , error = ""
                        , userState = Joined
                      }
                    , setupIncomingEvents
                    )

                Err error ->
                    ( { model
                        | userState = NotJoined
                        , error =
                            error
                                |> JD.errorToString
                      }
                    , Cmd.none
                    )

        {- User interactions -}
        --
        --
        -- Maybe send the isTypingEvent to connected clients
        MsgTextFocusedIn ->
            let
                ( messageState, cmd ) =
                    if String.trim model.message == "" then
                        ( Waiting, Cmd.none )

                    else
                        ( Typing
                        , model.id
                            |> encodeId
                            |> push
                                isTypingEvent
                        )
            in
            ( { model
                | messageState = messageState
              }
            , cmd
            )

        -- Send the stoppedTypingEvent to connected clients
        MsgTextFocusedOut ->
            ( { model
                | messageState = Waiting
              }
            , model.id
                |> encodeId
                |> push
                    stoppedTypingEvent
            )

        -- Send either isTypingEvent or stoppedTypingEvent to connected clients
        ChangedMessage message ->
            let
                ( messageState, event ) =
                    if String.trim message == "" then
                        ( Waiting, stoppedTypingEvent )

                    else
                        ( Typing, isTypingEvent )
            in
            ( { model
                | message = message
                , messageState = messageState
              }
            , model.id
                |> encodeId
                |> push
                    event
            )

        -- Send the message to all connected clients
        SendMessage ->
            ( { model
                | messageState = Sending
              }
            , model
                |> encodeMessage
                |> push
                    newMsgEvent
            )

        -- Message was sent successfully
        ChannelMsg (PushOk _ _ _) ->
            ( { model
                | message = ""
                , messageState = Waiting
              }
            , Cmd.none
            )

        {- Incoming events -}
        --
        --
        -- Receive a message from another user
        -- Scroll the viewport so that the message is displayed
        ChannelMsg (Channel.Message _ "new_msg" payload) ->
            ( { model
                | messages =
                    case decodeMessage payload of
                        Ok message ->
                            model.messages
                                ++ [ message ]

                        Err _ ->
                            model.messages
              }
            , Dom.getViewportOf "messages"
                |> Task.andThen
                    (\{ scene } ->
                        Dom.setViewportOf "messages" 0 scene.height
                    )
                |> Task.attempt
                    (\_ -> NoOp)
            )

        -- A user is typing
        -- Tag that user to identify them in the sidebar
        ChannelMsg (Channel.Message _ "is_typing" payload) ->
            ( { model
                | users =
                    model.users
                        |> tagUser
                            payload
              }
            , Cmd.none
            )

        -- A user has stopped typing
        -- Untag them to reset them in the sidebar
        ChannelMsg (Channel.Message _ "stopped_typing" payload) ->
            ( { model
                | users =
                    model.users
                        |> unTagUser
                            payload
              }
            , Cmd.none
            )

        -- Receive the Presence State
        PresenceMsg (State _ users) ->
            ( { model
                | users =
                    users
                        |> List.sortBy .id
              }
            , Cmd.none
            )

        {- Catch Alls -}
        --
        --
        --
        --
        SocketMsg _ ->
            ( model, Cmd.none )

        ChannelMsg _ ->
            ( model, Cmd.none )

        PresenceMsg _ ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )



-- Outgoing Events


{-| Send the [Socket.Connect](Socket#EventOut) event out through the `port`.
-}
connectToSocket : Cmd Msg
connectToSocket =
    Phx.sendMessage
        |> Socket.send
            (Connect Nothing)


{-| Send the [Channel.Join](Channel#EventOut) event out through the `port`.
-}
joinChannel : JE.Value -> Cmd Msg
joinChannel payload =
    Phx.sendMessage
        |> Channel.send
            (Channel.Join
                { topic = topic
                , timeout = Nothing
                , payload = Just payload
                }
            )


{-| Send a [Channel.Push](Channel#EventOut) event out through the `port`.

The first `String` parameter will be one of [newMsgEvent](#newMsgEvent),
[isTypingEvent](#isTypingEvent) or [stoppedTypingEvent](#stoppedTypingEvent).

The second `Value` parameter is the payload.

-}
push : String -> JE.Value -> Cmd Msg
push event payload =
    Phx.sendMessage
        |> Channel.send
            (Push
                { topic = Just topic
                , event = event
                , timeout = Nothing
                , payload = payload
                }
            )



-- Incoming Events


incomingEvents : List String
incomingEvents =
    [ newMsgEvent
    , isTypingEvent
    , stoppedTypingEvent
    ]


{-| Setup all the incoming events that we need to be able to receive from the
channel. This needs to be invoked **after** we receive the
[Channel.JoinOk](Channel#EventIn) event.
-}
setupIncomingEvents : Cmd Msg
setupIncomingEvents =
    Phx.sendMessage
        |> Channel.eventsOn
            (Just topic)
            incomingEvents


{-| This is where we subscribe to incoming Socket, Channel and Presence events.
-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Phx.socketReceiver
            |> Socket.subscriptions
                SocketMsg
        , Phx.channelReceiver
            |> Channel.subscriptions
                ChannelMsg
        , Phx.presenceReceiver
            |> Presence.subscriptions
                PresenceMsg
        ]



-- Decoders


messageDecoder : JD.Decoder Message
messageDecoder =
    JD.succeed
        Message
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "text" JD.string)


decodeMessage : JE.Value -> Result JD.Error Message
decodeMessage payload =
    JD.decodeValue messageDecoder payload


decodeId : JE.Value -> String
decodeId payload =
    payload
        |> JD.decodeValue
            (JD.field "id" JD.string)
        |> Result.toMaybe
        |> Maybe.withDefault ""



-- Encoders


encodeMessage : Model -> JE.Value
encodeMessage model =
    JE.object
        [ ( "msg", model.message |> JE.string )
        , ( "id", model.id |> JE.string )
        ]


encodeId : String -> JE.Value
encodeId id =
    JE.object
        [ ( "id", id |> JE.string ) ]


encodeUsername : String -> JE.Value
encodeUsername username =
    JE.object
        [ ( "username"
          , username
                |> String.trim
                |> JE.string
          )
        ]



-- Remote User Interaction


tagUser : JE.Value -> PresenceState -> PresenceState
tagUser payload users =
    let
        id =
            payload
                |> decodeId
    in
    users
        |> List.map
            (\user ->
                if user.id == id then
                    { user
                        | id = user.id ++ ":*"
                    }

                else
                    user
            )


unTagUser : JE.Value -> PresenceState -> PresenceState
unTagUser payload users =
    let
        id =
            payload
                |> decodeId
    in
    users
        |> List.map
            (\user ->
                if user.id |> String.contains id then
                    { user
                        | id = id
                    }

                else
                    user
            )



-- View


view : Model -> Html Msg
view model =
    El.layout
        [ El.width El.fill
        , El.height El.fill
        ]
        (case model.userState of
            NotJoined ->
                formView
                    model

            Joining ->
                joiningView

            Joined ->
                roomView
                    model
        )



-- Entry View


formView : Model -> Element Msg
formView model =
    El.column
        [ El.centerX
        , El.centerY
        , El.spacing 10
        ]
        [ Input.text
            [ El.width
                (El.fill
                    |> El.maximum 500
                )
            ]
            { label = Input.labelHidden "Username"
            , text = model.username
            , placeholder = Just (Input.placeholder [] (El.text "Username"))
            , onChange = ChangedUsername
            }
        , Input.button
            [ Background.color Blue.blue
            , Border.rounded 10
            , El.padding 10
            , El.width El.fill
            , Font.color Blue.lightblue
            ]
            { label = El.el [ El.centerX ] (El.text "Join")
            , onPress = Just ClickedJoin
            }
        , El.el
            [ Font.color Red.tomato ]
            (El.text model.error)
        ]


joiningView : Element Msg
joiningView =
    El.el
        [ El.centerX
        , El.centerY
        ]
        (El.text "Joining...")



-- Room View


roomView : Model -> Element Msg
roomView model =
    El.row
        [ El.width El.fill
        , El.height El.fill
        ]
        [ El.column
            [ El.height El.fill
            , El.padding 10
            , El.spacing 10
            , Border.widthEach
                { top = 0
                , right = 1
                , bottom = 0
                , left = 0
                }
            ]
            (model.users
                |> viewNames
            )
        , El.column
            [ El.width El.fill
            , El.height El.fill
            , El.padding 10
            , El.spacing 10
            , Background.color Blue.lavender
            ]
            ([ El.el
                [ El.width El.fill
                , El.height El.fill
                , El.clip
                , El.scrollbarY
                , El.htmlAttribute
                    (Attr.id
                        "messages"
                    )
                ]
                (model.messages
                    |> viewMessages
                )
             , Input.multiline
                [ El.width El.fill
                , Event.onLoseFocus MsgTextFocusedOut
                , Event.onFocus MsgTextFocusedIn
                ]
                { text = model.message
                , placeholder =
                    "Enter Your Message"
                        |> El.text
                        |> Input.placeholder
                            [ Font.color Blue.skyblue ]
                        |> Just
                , label = Input.labelHidden "Enter Your Message"
                , spellcheck = True
                , onChange = ChangedMessage
                }
             ]
                ++ messageFormButton model
            )
        ]


messageFormButton : Model -> List (Element Msg)
messageFormButton model =
    let
        hasContent =
            model.message /= ""
    in
    case ( model.messageState, hasContent ) of
        ( Waiting, False ) ->
            [ Input.button
                [ Background.color Blue.lightblue
                , Border.rounded 10
                , El.padding 10
                , El.width El.fill
                , Font.color Blue.blue
                ]
                { label = El.el [ El.centerX ] (El.text "Waiting...")
                , onPress = Nothing
                }
            ]

        ( Sending, _ ) ->
            [ Input.button
                [ Background.color Blue.lightblue
                , Border.rounded 10
                , El.padding 10
                , El.width El.fill
                , Font.color Blue.blue
                ]
                { label = El.el [ El.centerX ] (El.text "Sending Message...")
                , onPress = Nothing
                }
            ]

        _ ->
            [ Input.button
                [ Background.color Blue.blue
                , Border.rounded 10
                , El.padding 10
                , El.width El.fill
                , Font.color Blue.lightblue
                ]
                { label = El.el [ El.centerX ] (El.text "Send Message")
                , onPress = Just SendMessage
                }
            ]



-- Users View


viewNames : PresenceState -> List (Element Msg)
viewNames users =
    users
        |> List.map
            viewName


viewName : Presence -> Element Msg
viewName user =
    El.el
        [ Font.color (selectColor user.id) ]
        (El.text
            (user.id
                |> nameFromId
            )
        )


selectColor : String -> Color
selectColor id =
    if id |> isTyping then
        Green.green

    else
        Blue.blue


nameFromId : String -> String
nameFromId id =
    id
        |> String.split ":"
        |> List.head
        |> Maybe.withDefault ""


isTyping : String -> Bool
isTyping id =
    id
        |> String.endsWith "*"



-- Messages View


viewMessages : List Message -> Element Msg
viewMessages messages =
    El.column
        [ El.alignBottom
        , El.spacing 10
        ]
        (messages
            |> List.map
                viewMessage
        )


viewMessage : Message -> Element Msg
viewMessage message =
    El.column
        [ El.width El.fill
        , El.padding 10
        ]
        [ El.el
            [ Font.color Blue.steelblue ]
            (El.text
                (message.id
                    |> nameFromId
                )
            )
        , El.el
            [ Font.color Blue.cornflowerblue ]
            (El.text
                message.text
            )
        ]


{-| -}
main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
