# Mooncake

[![Join the chat at https://gitter.im/cyrilis/luvit-mooncake](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/cyrilis/luvit-mooncake?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

**A web framework powered by luvit.**

Mooncake is a web framework powered by [luvit](https://luvit.io/). inspired by [expressjs](http://expressjs.com/) for nodejs.

## Install

Install with [lit](https://luvit.io/lit.html)

```bash
lit install cyrilis/mooncake
```

## Usage

### Getting start

```lua
local MoonCake = require("mooncake")
local server = MoonCake:new()

-- route your application
server:get("/", function(req, res)
  local content = "<p>Hello world from MoonCake</p>"
  res:send(content, 200)
end)

server:start(8080)
```

### Server

- #### create server

  - create a http server:

    ```lua
    Mooncake = require("mooncake")
    local sever = Mooncake:new()
    ```

  - or create a https server:

    ```lua
    Mooncake = require("mooncake")
    local server = Mooncake:new({
        isHttps = true
        keyPath = "/path/to/key"
    })
    -- will read ssl key and cert file at "/path/to/key/key.pem" and "path/to/key/cert.pem"
    ```

- #### server:use(func)

  Use the given middleware function,

  Example:

  ```lua
  server:use(function(req, res, next)
      res:locals({first = true})
      next()
  end)
  ```

- #### server:static(fileDir, options)

  - fileDir: string, directory path, **required**, eg: "public/files"

  - options:

    - root: string, mount path, eg: `"/static"`

    - maxAge: number, cache option for maxAge, default is `15552000` (half a year).

      eg:

  ```lua
  server:static(path.resolve(module.dir, "../public/"), {
      root = "/static/",
      maxAge = 31536000 -- one year
  })
  ```

- #### server:start(port [, address])

  - port: number, optional, default to 8080
  - address: string, optional, default to "127.0.0.1"

  Start your server:

  ```lua
  server:start(8080)
  ```

### Route

#### You can route your app easily with below methods:

`:get` `:post` `:put` `:delete` `:all`

Example:

```lua
-- :all
server:all("/hello", function(req, res, next)
    res:send("HELLO!")
end)

-- :get
server:get("/admin/:page", function(req, res,next)
    --- ...
    -- login check func
    if isLogin then
      next()
    else
      res:status(403):redirect("/login")
    end
end)

server:get("/admin/dashboard", function(req, res, next)
    --- ...
    res:render("../views/dashbaord", data)
end)

-- :post
server:post("/posts", function(req, res)
   p(req.body) -- print post data;
   ... -- create a new post
end)

-- :put
server:put("/posts/:id", function(req, res)
   p(req.params.id) -- print id params in request
   ... -- update post with id = `req.params.id`
end)

-- :delete
server:delete("/posts/:id", function(req, res)
   ... -- delete post with id = "req.params.id"
end)
```

Or you can use `server:route()` to match route if your use custom method:

```lua
server:route("custom-method", "/posts/:id", function(req, res)
    ... -- delete post with id = "req.params.id"
end)
```

### Request

- #### req.params

  This property is an array containing properties mapped to the named route “parameters”. For example if you have the route /user/:name, then the “name” property is available to you as req.params.name. This object defaults to {}.

  eg:

  ```lua
  -- GET "/user/cyrilis"
  server:put("/user/:name", function(req, res)
      p(req.params.name) -- output user name `cyrilis`
  end)
  ```

- #### req.query

  This property is an object containing the parsed query-string, defaulting to {}.

  ```lua
  -- GET /search?q=tobi+ferret
  req.query.q
  -- => "tobi ferret"

  -- GET /shoes?order=desc&shoe[color]=blue&shoe[type]=converse
  req.query.order
  -- => "desc"

  req.query.shoe.color
  -- => "blue"

  req.query.shoe.type
  -- => "converse"
  ```

- #### req.body

  This property is an object containing the parsed request body. This property defaults to {}.

  ```lua
  -- POST user[name]=tobi&user[email]=tobi@learnboost.com
  req.body.user.name
  -- => "tobi"

  req.body.user.email
  -- => "tobi@learnboost.com"

  // POST { "name": "tobi" }
  req.body.name
  -- => "tobi"
  ```

  You can get post data via req.body, then save to db:

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

- #### req.method

  return request method, eg: `"GET"`

- #### req.cookie

  This object return parsed cookies sent by the user-agent. If no cookies are sent, it defaults to {}.

  ```lua
  -- Cookie: name=cyrilis
  req.cookies.name
  -- => "cyrilis"
  ```

- #### req.headers

  return headers of request.

- #### req.url

  return the url of request.

### Response

`ServerResponse` has several extra methods:

- #### res:send (data, code, header)

  This method performs a myriad of useful tasks for simple non-streaming responses such as automatically assigning the Content-Length unless previously defined and providing automatic `HEAD` and `HTTP` cache freshness support.

  - `data`: string, content string to render, **required**, eg: "Hello World!"
  - `code`: number, status code,  eg: 200
  - `header`: table, Custom header, eg: `{['Content-Type'] = 'text/plain', ["Content-Length"] = 1000}`

  Example:

  ```lua
  server:get("/abc", function(req, res)
      res:send("")
  end)
  ```

- #### res:render(tpl, data)

  There are two render engines build in, default is [lua-resty-template](https://github.com/bungle/lua-resty-template/), and the other one is [etlua](https://github.com/leafo/etlua), if you prefer `etlua` as your default render engine, you can add below code in your project:

  ```lua
  local env = require("env")
  env.set("viewEngine", "etlua")
  ```

  — Or just use .elua as template file extension name

  ```lua
  res:render("./views/index.elua", {title = "Hello world!"})
  ```

  Render engine accept the first argument as template file path or template content, the second arguments as render data. you can visit  [lua-resty-template ](https://github.com/bungle/lua-resty-template/) and [etlua](https://github.com/leafo/etlua) project home page for template syntax.

  - `tpl`: string, path to template file, **required**,eg: `"views/post.html"`
  - `data`: table, render data, **required**, eg: `{["status" = "success"]}`

  Example of  [lua-resty-template ](https://github.com/bungle/lua-resty-template/):

  ```lua
  server:get("/posts", function(q,s)
    -- get post list, render template.
    s:render("./view/post-list.html", {posts = DB.find("posts")})
  end)
  ```

  `./view/post-list.html`

  ```html
  <ul>
  {% for _, post in ipairs(posts) do %}
      <li>{{post.title}}</li>
  {% end %}
  </ul>
  ```

  Example of  [etlua](https://github.com/leafo/etlua)

  ```lua
  server:get("/posts", function(q,s)
    -- get post list, render template.
    s:render("./view/post-list.elua", {posts = DB.find("posts")})
  end)
  ```

  `./view/post-list.elua`

  ```ejs
  <ul>
      <% for _, name in ipairs(names) do %>
      <li><%= name %></li>
      <% end %>
  </ul>
  ```

  #### Render Result:

  ```html
  <ul>
      <li>Post 1</li>
      <li>Post 2</li>
      <li>Post 3</li>
  </ul>
  ```


- #### res:redirect(url, code)

  Redirect to the given url with optional status code defaulting to 302 “Found”.

  - `url`: string, url for redirect, **required**, eg: "/404"
  - `code`: number, status code, eg: 200

  Example:

  ```lua
  server:get("/post-not-exist", function(req, res)
    -- if user not login then
    res:redirect("/page-not-found", 302)
  end)
  server:get("/page-not-found", function(req, res)
   res:render("404.html", 404)
  end)
  ```

- #### res:status(statusCode)

  Chainable alias of luvit `res.statusCode=`.

  - `statusCode`: number, required, status code, eg: 403

  Example:

  ```lua
  server:get("/page-not-exist", function(req, res)
    res:status(404):render("404.html")
  end)
  ```

- #### res:sendFile(filePath, headers)

  - `filePath`: string, **required**, send file directly. eg: `res:sendFile("files/preview.pdf")`
  - `headers`: table, Custom header, eg: `{['Content-Type'] = 'text/plain', ["Content-Length"] = 1000}`

  Example:

  ```lua
  server:get("/files/:file", function(req,res)
   res:sendFile("/public/files/".. req.params.file)
  end)
  ```

- #### res:json(obj, code, headers)

  Send a JSON response. When an Table is given mooncake will respond with the JSON representation:

  - `obj`: table, **required**, data for render. eg: `{["status"]="OK"}`
  - `code`: number, status code, eg: 200
  - `headers`: table, Custom header, eg: `{['Content-Type'] = 'text/plain', ["Content-Length"] = 1000}`

  Example:

  ```lua
  server:get("/api.json", function(req, res)
      posts = DB:find("*")
      res:json(posts, 200)
  end)
  ```

- #### res:flash(type, flash)

  `flash` method like in rails.

  - `type`: string, required, flash type: eg: "success"
  - `flash`: string, required, flash content: eg: "You've successfully login, welcome back."

- #### res:locals(data)

  Store data as local data for render.

  Example:

  ```lua
  server:use(function(req, res, next)
   if req.query.page ~= 1 then
        res:locals({isFirstPage = false})
    end
   next()
  end)
  server:get("/post", function()
   render("views/post-list.html")
  end)
  ```

## Contribute

Feel free to open issues and submit pull request :)

## Licence

(The MIT License)

Copyright (c) 2015 Cyril Hou <houshoushuai@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
