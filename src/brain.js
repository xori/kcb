var fs = require('fs-extra');

var brain = null;
var brain_location = process.env.HUBOT_BRAIN_LOCATION || './data/brain.json';
//fs.ensureFileSync(brain_location);
try {
  // fetch from file this should only happen once because after the first time the
  //   require is cached.
  brain = require('.' + brain_location);
  console.log("LOADED BRAIN");
} catch (err) {
  // create the file if it doesn't exist yet.
  brain = {};
  fs.writeJsonSync(brain_location, brain);
}

brain.save = function() {
  fs.writeJson(brain_location, brain, function(e) {
    //TODO handle error
  });
}

module.exports = brain;
