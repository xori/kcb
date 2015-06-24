/***
* Description:
*   Remembers the milk for you
*
* Dependencies:
*   chrono-node
*
* Commands:
*   hubot remind <user> to do <something> - chef: Runs chef-client on node
*
* Examples:
*   hubot remind Eric to gets chips for the party on Friday.
*   hubot remind me to annoy Jimmy next week.
* Author:
*   xori
*/

var chrono = require('chrono-node');
var brain = require('../src/brain');
//TODO Figure out a way to use robot.brain
var timeouts = []

module.exports = function (robot) {
  function checkReminders() {
    var now = new Date()
    brain.reminders = brain.reminders.filter(function(reminder) {
      if(reminder.Day < now) {
        robot.send(reminder.Envelope,
          reminder.User + ', ' + reminder.Reminder);
        return false; // remove it.
      }
      return true;
    })
    brain.save();
  }

  function addReminder(reminder, robot) {
    if(!brain.reminders) brain.reminders = [];
    brain.reminders.push(reminder);
    brain.save();

    var now = new Date();
    timeouts.push(setTimeout(checkReminders, reminder.Day - now + 3000))
  }

  // parse on startup.
  if(!brain.reminders) brain.reminders = [];
  brain.reminders.forEach(function(reminder) {
    var now = new Date();
    if(typeof(reminder.Day) === 'string') {
      reminder.Day = new Date(reminder.Day);
    }
  })
  setInterval(checkReminders, 1000 * 60 * 5);

  robot.hear(/^remind (\w+)(?: to| that)?(?: s?he| I)? (.+)?/i, function (res) {
    var user = res.match[1];
    var statement = res.match[2];
    var today = new Date();
    var result = {}
    var parsed = chrono.parse(statement)
    if(parsed.length === 0) {
      // resonable defaults
      parsed = {
        someday: true,
        index: statement.length,
        text: ' (someday)'
      };
      (parsed.startDate = new Date())
        .setDate(parsed.startDate.getDate() + Math.random() * 7 + 1);
    } else {
      parsed = parsed[0];
      parsed.start.hour = today.getHours();
      parsed.start.minute = today.getMinutes();
    }

    if (user.match(/me/i)) user = res.message.user.name;
    result.User = user;
    result.Day = parsed.startDate || parsed.start.date();
    var tmp = statement;
    var tmpds = parsed.someday ? parsed.text : parsed.start.date().toDateString();
    tmp = [tmp.slice(0, parsed.index), tmpds, tmp.slice(parsed.index + parsed.text.length)].join('');
    result.Reminder = tmp;
    result.Envelope = res.envelope;

    res.send("I'll remind " + user + ", " + result.Reminder);
    addReminder(result);
  });
}

// remind me to get the dog food
// > get the dog food (someday)
// remind eric to answer the question by Tuesday
// > Eric, answer the question (Jun 25, 2015)
// remind Evan that he needs to get the Chips for next Friday
// > Evan, needs to get the Chips for (Jun 25, 2015)
