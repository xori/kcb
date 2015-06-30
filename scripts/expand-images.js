module.exports = function (robot) {

  robot.hear(/^(http[^\s]+\.(?:jpg|gif|png))/i, function (res) {
    res.send(res.match[1]);
  });

}
