local MoonCake = require("../")
local server = MoonCake:new()
local env = require("env")

server:use(function(req, res, next)
    next()
end)

server:route("get", "/", function(req, res)
  res:render("./views/index.html", {
    title= "Hello world from MoonCake!",
    message = "You are welcome!",
    names = {"Tom", "Jerry", "Wof"},
    jquery  = '<script src="js/jquery.min.js"></script>'
  })
end)

server:get("/etlua", function(req, res)
  res:render("./views/index.elua", {
    title= "Hello world from MoonCake!",
    message = "You are welcome!",
    names = {"Tom", "Jerry", "Wof"},
    jquery  = '<script src="js/jquery.min.js"></script>'
  })
end)

server:route("get", "/users/:id", function(q, s)
    s:send("List User in Databases => " .. q.params.id)
end)

server:get("/setCookie", function(req, res)
  res:setCookie("WTF", "Test", {
    path = "/",
    httpOnly = true
  }):send("Set Cookie Test.")
end)

server:get("/removeCookie", function(req, res)
  res:removeCookie("WTF"):send("RemoveCookie")
end)

server:all("/hello.test", function(q, s)
  s:send("HELLO!")
end)

server:all("/hello.hello/*", function(q, s)
  s:send("Splat!")
end)

server:get("/WTF", function(q, s)
  s:redirect("/hello")
end)

server:get("/posts", function(q,s)
  s:send("Post list: ...")
end)

server:post("/posts/new", function(q,s)
  if q.body.title and q.body.content then
    p("new post")
    -- Save to DB:
    -- DB.save("post", {title = q.body.title, content = q.body.content})
    s:redirect("/posts")
  end
end)

server:post("/", function(req, res)
  p(req.files)
  res:json(req.files)
end)

server:static("./libs/", {
  root = "/static/",
  maxAge = 31536000 -- one year
})

-- Test render to file : renderToFile
server:get("/cache", function (req, res, next)
    p("Cache test....")
    res:renderToFile("./views/index.html", {
      title= "Hello world from MoonCake!",
      message = "You are welcome!",
      names = {"Tom", "Jerry", "Wof"},
      jquery  = '<script src="js/jquery.min.js"></script>'
  }, "./cache.html");
    res:sendFile("./cache.html")
end)

server:get("/testError", function (req, res, next)
    next("ERROR: SOMETHING HAPPEND.")
    -- next()
end)

MoonCake.serverError = function (req, res, error)
    res:status(500):json(error)
end

server:start(8081)
