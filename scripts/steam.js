module.exports = function (robot) {
  var url = "http://store.steampowered.com/search/suggest?term={{term}}&f=games&cc=CA&l=english&v=1127612"
  var parse = /match_name">([^<]+)<\/div>.*?CDN&#36; (\d+\.\d+)/gi

  robot.respond(/steam (.+)/i, function (res) {
    robot.http(url.replace("{{term}}", res.match[1]))
      .get()(function (err, _, body) {
        if (err) {
          res.send("Encountered an error :(\n" + err);
          return;
        }
        var result = ""
        var results = []
        body.replace(parse, function (str, one, two) {
          results.push({
            title: one,
            price: two
          });
        })
        if (results && results.length > 0) {
          results.forEach(function (i) {
            result += i.title + " - $" + i.price + "\n";
          })
        } else {
          result += "Couldn't find any games called '" + res.match[1] + "'"
        }
        res.send(result.trim());
      })
  })

  robot.respond(/what'?s (on sale|featured)\??/i, function(res) {
    robot.http('http://store.steampowered.com/api/featured/')
    .get()(function(err,_, body) {
      if(err) {
        res.send("Encountered an error :(\n", err);
      }
      var data = JSON.parse(body);
      var result = "";
      data.large_capsules.forEach(function(featured) {
        if(res.match[1] === 'on sale' && featured.discount_percent === 0) return;
        result += featured.name + ' - $' + (featured.final_price / 100.0) + ' (' + featured.discount_percent + '%)\n'
      })
      data.featured_win.forEach(function(featured) {
        if(res.match[1] === 'on sale' && featured.discount_percent === 0) return;
        result += featured.name + ' - $' + (featured.final_price / 100.0) + ' (' + featured.discount_percent + '%)\n'
      })
      res.send(result.trim());
    });
  })

}
