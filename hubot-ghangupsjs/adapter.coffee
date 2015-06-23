{Robot, User, Adapter, EnterMessage, LeaveMessage, TextMessage} = require('hubot')

Client = require 'hangupsjs'
Q      = require 'q'

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
    strings.forEach (message) ->
      message = message.split('\n')
      body = new Client.MessageBuilder()
      message.forEach (m) ->
        body = body.text(m).linebreak()
      self.client.sendchatmessage envelope.user.id, body.toSegments()

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"
    @send envelope, strings

  isMe: (id) ->
    id == @myself.id

  run: ->
    self = @
    @robot.logger.info "Run"

    self.client.on 'connect_failed', ->
      Q.Promise (rs) ->
        setTimeout rs, 3000 # back off for 3 seconds
      .then ->
        self.client.connect(self.creds)
      .then ->
        self.emit "connected"

    self.client.on 'chat_message', (res) ->
      if res.chat_message?.message_content?
        return if self.isMe(res.sender_id.chat_id)

        body = ""
        res.chat_message.message_content.segment
          .forEach (i) ->
            body += i.text
        user = new User res.conversation_id.id, chat_id: res.sender_id.chat_id
        message = new TextMessage user, body, res.event_id
        self.robot.receive message
        console.log(res.conversation_id.id, res.sender_id.chat_id, body)
      else
        console.log("unknown message type", res);
    return

exports.use = (robot) ->
  new GHangups robot
