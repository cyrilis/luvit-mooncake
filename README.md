# Mooncake
---------

**A web framework powered by luvit.**



Mooncake is a web framework powered by [luvit](https://luvit.io/). inspired by [expressjs](http://expressjs.com/) of nodejs.

## Install

```bash
npm install mooncake
```

## Usage

```lua
local MoonCake = require("mooncake")
local server = MoonCake()

-- route your application
server:get("/", function(req, res)
  local content = "<p>Hello world from MoonCake</p>"
  res:send(content, 200)
end)

-- or you can route in this way
server:route({
  ["get"] = {
    ["/users/:id"] = function(q, s)
      s:send("List User in Databases => " .. q.params.id)
    end
  }
})

-- avaialble method for route: "get", "post", "put", "delete"
server:all("/hello", function(q, s)
  s:send("HELLO!")
end)

-- extra method for response: "send", "redirect"
server:get("/WTF", function(q, s)
  s:redirect("/hello")
end)

server:get("/posts", function(q,s)
  s.send("Post list: ...")
end)

-- get post data via req.body, get query data(such as "/users?page=1") via req.query
server:post("/posts/new", function(req,res)
  if req.body.title and req.body.content then
    print("new post")
    -- Save to DB:
    -- DB.save("post", {title = req.body.title, content = req.body.content})
    res.redirect("/posts")
  end
end)

-- static server for static files! `root` option means mount path, 
-- eg: "/static/" means url path will be "http://example.com/static/file.ext"
server:static("./public/", {
  root = "/static/",
  maxAge = 31536000 -- one year
})

-- server start  port
server:start(8080)

```

## Licence

(The MIT License)

Copyright (c) 2015 Cyril Hou &lt;houshoushuai@gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
