////////////////////////////////////////////////////////
//
// presences.js
// JavaScript module code for channel.js
// Copyright (c) 2019 Paul Hollyer <paul@hollyer.me.uk>
// Some rights reserved.
// Distributed under the MIT License
// See LICENSE
//
////////////////////////////////////////////////////////


import Port from "./port"
import {Presence} from "phoenix"

var presences = {}

let Presences = {


    /*     onDiff/2

            Called when a user presence joins or leaves.

            Parameters:
                topic <string> - The channel topic.
                diff <object> - The diff received from Phoenix Presence.

    */
    onDiff(topic, diff) {
        let self = this

        presences = Presence.syncDiff(
            presences,
            diff,
            (id, current, newPres) => self.send(topic, "Join", (this.packageForElm(id, newPres))),
            (id, current, leftPres) => self.send(topic, "Leave", (this.packageForElm(id, leftPres)))
        )

        this.send(topic, "Diff", {leaves: this.toList(diff.leaves), joins: this.toList(diff.joins)})
        this.send(topic, "State",{list: Presence.list(presences, (id, metas) => (this.packageForElm(id, metas)))})
    },


    /*     onState/2

            Called when a user presence joins or leaves.

            Parameters:
                topic <string> - The channel topic.
                state <object> - The state received from Phoenix Presence.

    */
    onState(topic, state) {
        let self = this

        presences = Presence.syncState(
            presences,
            state,
            (id, current, newPres) => self.send(topic, "Join", (this.packageForElm(id, newPres))),
            (id, current, leftPres) => self.send(topic, "Leave", (this.packageForElm(id, leftPres)))
        )

        this.send(topic, "State",{list: Presence.list(presences, (id, metas) => (this.packageForElm(id, metas)))})
    },


    /* toList/1

            List the presences in a consistent form that is easier to handle in Elm.

            Parameters:
                presences_ <object> - The raw presences data received from the server. // {"id1": metas, "id2": metas, ... }

            Returns:
                [{id: "id1", metas: metas}, {id: "id2", metas: metas}, ... ]
    */
    toList(presences_) {
        let list = []

        for(var id in presences_) {
            list.push(this.packageForElm(id, presences_[id]))
        }

        return list
    },


    /* packageForElm/2

            Package the presence into a consistent form that is easier to handle in Elm.

            Parameters:
                id <string> - The user id.
                presence <object> - The raw presence data received from the server. // {"id1": metas}

            Returns:
                {id: "id1", metas: metas}
    */
    packageForElm(id, presence) { return {id: id, metas: presence.metas} },

    /* send/3

            Send to Presences.elm

            Parameters:
                topic <string> - The channel topic.
                event <string> - The EventIn stringified that is received i Elm.
                payload <object> - The data from the server.

    */
    send(topic, event, payload) {
        Port.sendToPresence(topic, event, payload)
    }
}

export default Presences