{Robot, User, Adapter, EnterMessage, LeaveMessage, TextMessage} = require('hubot')

Client = require 'hangupsjs'
Q      = require 'q'

class GHangups extends Adapter

  constructor: ->
    super
    self = @
    @creds = -> auth:Client.authStdin
    @bld = new Client.MessageBuilder()
    @client = new Client()
    @client.loglevel 'info'
    @client.connect(@creds).then =>
      self.emit "connected"
      self.client.sendchatmessage 'UgxL8S7vM8LtAuFJZcl4AaABAQ',
        [[0, "Hello"]]

  send: (envelope, strings...) ->
    @robot.logger.info "Send", envelope, strings
    strings.forEach (message) ->
      client.sendchatmessage envelope.user.id, message

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply", envelope, strings
    @send envelope, strings

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
        body = ""
        res.chat_message.message_content.segment
          .forEach (i) ->
            body += i.text
        user = new User res.conversation_id.id, chat_id: res.sender_id.chat_id
        message = new TextMessage user, body, res.event_id
        self.robot.receive message
        console.log(body, message, !!self.robot.receive)
      else
        console.log("unknown message type", res);
    return

exports.use = (robot) ->
  new GHangups robot
