{Robot, User, Adapter, EnterMessage, LeaveMessage, TextMessage} = require('hubot')

Client = require 'hangupsjs'
Q      = require 'q'
FS     = require 'fs-extra'
HTTP   = require 'http'
HTTPS   = require 'https'

class GHangups extends Adapter

  constructor: ->
    super
    self = @
    @robot.logger.info "HUBOT_GHANGUPS_CREDS: " + process.env.HUBOT_GHANGUPS_CREDS
    @creds = -> auth: if process.env.HUBOT_GHANGUPS_CREDS then Q(process.env.HUBOT_GHANGUPS_CREDS) else Client.authStdin
    @phonebook = {}
    @myself = {}

    @client = new Client()
    @client.loglevel 'info'
    @client.connect(@creds).then =>
      self.emit "connected"
      self.client.getselfinfo().then (data) ->
        self.myself.id = data.self_entity.id.chat_id
        self.myself.name = data.self_entity.properties.display_name
        console.log("Got Myself")

  send: (envelope, strings...) ->
    self = @
    @robot.logger.info "Send"
    isLink = /^((https?)?(?:\:\/\/)(?:[\da-z\.-]+)\.(?:[a-z\.]{2,6})(?:[\/\w \.-]*)*\/?(?:\?[\da-z]*=[\S]*)?)$/i
    strings.forEach (message) ->
      # image attachment
      #TODO split this to a new function
      imgAtt = Q.Promise (rs) ->
        imgReg = /^(http[^\s]+\.(?:png|gif|jpg))/i
        match = message.match imgReg
        return rs null unless match
        console.log "found image #{match[1]}"
        filename = "./data/uploads/" + (new Date().getTime()) + ".jpg"
        file = FS.createWriteStream filename
        http = null
        if match[1].indexOf("https") == 0
          http = HTTPS
        else
          http = HTTP
        http.get match[1], (response) ->
          response.pipe(file)
          console.log "downloading image"
          file.on 'finish', ->
            file.close ->
              #TODO should be able to get the image path here.
              console.log "uploading image"
              self.client.uploadimage(filename)
              .then (id) ->
                rs id
                FS.delete filename
        .on 'error', (err) ->
          console.error "image error #{err}"
          rs null
        return
      message = message.toString().split('\n')
      body = new Client.MessageBuilder()
      message.forEach (m) ->
        if m.match(isLink)
          body = body.link(m, m).linebreak()
        else
          body = body.text(m).linebreak()
      imgAtt.then (imgid) ->
        if imgid == null
          self.client.sendchatmessage envelope.user.id, body.toSegments()
        else
          self.client.sendchatmessage envelope.user.id, null, imgid
        console.log "kcb: #{strings.join '\n'}"

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"
    for str in strings
      @send envelope, "#{str}"

  isMe: (id) ->
    id == @myself.id

  run: ->
    self = @
    @robot.logger.info "Run"

    # I think when the connection fails it keeps working?
    # self.client.on 'connect_failed', ->
    #   Q.Promise (rs) ->
    #     setTimeout rs, 3000 # back off for 3 seconds
    #   .then ->
    #     self.client.connect(self.creds)
    #   .then ->
    #     self.emit "connected"

    self.client.on 'chat_message', (res) ->
      if res.chat_message?.message_content?
        return if self.isMe(res.sender_id.chat_id)
        body = ""
        res.chat_message.message_content.segment
          .forEach (i) ->
            body += i.text

        # create user
        Q.Promise (rs) ->
          cached_user = self.phonebook[res.sender_id.chat_id]
          if cached_user
            #TODO always override the room (currently id)
            cached_user.id = res.conversation_id.id
            return rs(cached_user)
          # not in cache need to fetch.
          console.log("user not in phonebook, performing lookup.")
          self.client.getentitybyid([ res.sender_id.chat_id ]).then (data) ->
            u = new User res.conversation_id.id,
              chat_id: data.entities[0].id.chat_id
              display_name: data.entities[0].properties.display_name
              name: data.entities[0].properties.first_name
              photo: data.entities[0].properties.photo_url
            console.log(u)
            self.phonebook[u.chat_id] = u
          , (data) ->
            console.error "couldn't lookup user", data
          .then (user) ->
            rs user
        .then (user) ->
          message = new TextMessage user, body, res.event_id
          self.robot.receive message
          console.log "[#{user.id}] #{user.name}: #{body}"
      else
        console.log("unknown message type", res);
    return

exports.use = (robot) ->
  new GHangups robot
