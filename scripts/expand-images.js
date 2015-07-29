module.exports = function (robot) {

  // Really this is like never a good idea.
  robot.hear(/^(http[^\s]+\.(?:jpg|gif|png))/i, function (res) {
    res.send(res.match[1]);
  });

}
