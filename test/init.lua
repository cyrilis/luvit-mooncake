local MoonCake = require("../")
local server = MoonCake()

server:match("get", "/", function(req, res)
  res:render("./views/index.html", {
    title= "Hello world from MoonCake!",
    message = "You are welcome!",
    names = {"Tom", "Jerry", "Wof"},
    jquery  = '<script src="js/jquery.min.js"></script>'
  })
end)

server:route({
  ["get"] = {
    ["/users/:id"] = function(q, s)
      s:send("List User in Databases => " .. q.params.id)
    end
  }
})

server:all("/hello", function(q, s)
  s:send("HELLO!")
end)

server:get("/WTF", function(q, s)
  s:redirect("/hello")
end)

server:get("/posts", function(q,s)
  s:send("Post list: ...")
end)

server:post("/posts/new", function(q,s)
  if q.body.title and q.body.content then
    print("new post")
    -- Save to DB:
    -- DB.save("post", {title = q.body.title, content = q.body.content})
    s:redirect("/posts")
  end
end)

server:static("./libs/", {
  root = "/static/",
  maxAge = 31536000 -- one year
})

server:start(8080)
