Client = require 'hangupsjs'
Q = require 'q'
fs = require 'fs-extra'
http = require 'http'

# callback to get promise for creds using stdin. this in turn
# means the user must fire up their browser and get the
# requested token.
creds = -> auth:Client.authStdin

client = new Client()

# set more verbose logging
client.loglevel 'warn'

# receive chat message events
client.on 'chat_message', (ev) ->
  console.log ev

# connect and post a message.
# the id is a conversation id.
client.connect(creds).then ->
  console.log("begin.")
  Q.Promise (rs) ->
    fs.ensureFileSync "./data/uploads/file.jpg"
    file = fs.createWriteStream "./data/uploads/file.jpg"
    http.get "http://www.animalshirts.net/wolfshirts/10_3451.jpg", (response) ->
      response.pipe(file)
      file.on 'finish', ->
        file.close rs
    .on 'error', (err) -> console.error "image error" err
  .then ->
    client.uploadimage('./data/uploads/file.jpg')
    .then (id) ->
      console.log(id)
      client.sendchatmessage 'Ugz0H3qeJXcrc_pSPJF4AaABAQ', [], id
    , (err) ->
      console.error(err)
    # client.getentitybyid(['107485400031369455948']).then (data) ->
    #   console.log(data.entities[0].properties);
.done()
