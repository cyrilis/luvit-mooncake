# Mooncake
----------------------------------------------

**A web framework powered by luvit.**



Mooncake is a web framework powered by [luvit](https://luvit.io/). inspired by [expressjs](http://expressjs.com/) of nodejs.

## Install

```bash
npm install mooncake
```

## Usage

```lua
local MoonCake = require("./node_modules/mooncake/index")
local server = MoonCake()

-- route your application
server:get("/", function(req, res)
  local content = "<p>Hello world from MoonCake</p>"
  res:send(content, 200)
end)

server:start(8080)

```

or you can add your route in this way
 
```lua
server:route({
  ["get"] = {
    ["/users/:id"] = function(q, s)
      s:send("List User in Databases => " .. q.params.id)
    end
  }
})

```

avaialble method for route: "get", "post", "put", "delete"

```lua
server:all("/hello", function(q, s)
  s:send("HELLO!")
end)
```

extra method for response: "send", "redirect", "render"

You can get more about render template syntax at: https://github.com/bungle/lua-resty-template/

```lua
server:get("/admin", function(q, s)
  -- if user not login then
  s:redirect("/login")
end)

server:get("/posts", function(q,s)
  -- get post list, render template.
  s:render("./view/post-list.html", {posts = DB.find("posts")})
end)
```

You can get post data via req.body, get query data(such as "/users?page=1") via req.query

```lua
server:post("/posts/new", function(req,res)
  if req.body.title and req.body.content then
    print("new post")
    -- Save to DB:
    -- DB.save("post", {title = req.body.title, content = req.body.content})
    res.redirect("/posts")
  end
end)
```

One more thing, static server for static files! 

`root` option means mount path,
eg: "/static/" means url path will be "http://example.com/static/file.ext"

``` lua
server:static("./public/", {
  root = "/static/",
  maxAge = 31536000 -- one year
})
```

Start your server:

```
server:start(8080)
```

## Licence

(The MIT License)

Copyright (c) 2015 Cyril Hou &lt;houshoushuai@gmail.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
