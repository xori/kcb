Client = require 'hangupsjs'
Q      = require 'q'

# callback to get promise for creds using stdin. this in turn
# means the user must fire up their browser and get the
# requested token.
creds = -> auth:Client.authStdin

client = new Client()

# set more verbose logging
client.loglevel 'debug'

# receive chat message events
client.on 'chat_message', (ev) ->
    console.log ev

# connect and post a message.
# the id is a conversation id.
client.connect(creds).then ->
    client.getentitybyid(['107485400031369455948']).then (data) ->
      console.log(data.entities[0].properties);
.done()
