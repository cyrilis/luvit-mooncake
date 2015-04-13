require("./libs/Response")
local http = require("http")
local https = require("https")
local pathJoin = require('luvi').path.join
local fs = require('fs')
local fse = require("./libs/fse")
local Router = require('./libs/router')
local mime = require('./libs/mime')
local helpers = require('./libs/helpers')
local querystring = require('querystring')
local Cookie = require("./libs/cookie")
require("./libs/ansicolors")
print((" Hello "):bluebg(), (" World "):redbg(), (" from MoonCake "):yellowbg(), (" ! "):greenbg())
local getQueryFromUrl
getQueryFromUrl = function(url)
  local params = string.match(url, "?(.*)") or ""
  return querystring.parse(params)
end
local MoonCake
do
  local _base_0 = {
    listen = function(self, port)
      return self:start(port)
    end,
    start = function(self, port)
      if port == nil then
        port = 8080
      end
      self:genRoute()
      local fn = self.fn
      if self.isHttps == true then
        local keyConfig = {
          key = fs:readFileSync(pathJoin(self.keyPath, "key.pem")),
          cert = fs:readFileSync(pathJoin(self.keyPath, "cert.pem"))
        }
        https:createServer(keyConfig, fn):listen(port)
      else
        http.createServer(fn):listen(port)
      end
      return print("Server listenning at http://localhost:" .. tostring(port) .. "/ ")
    end,
    genRoute = function(self)
      local that = self
      self.fn = function(req, res)
        local url = req.url
        local method = string.lower(req.method)
        res.req = req
        local params = {
          req,
          res
        }
        local querys = getQueryFromUrl(url)
        req.query = querys
        if method ~= "get" then
          local body = ""
          req:on("data", function(chunk)
            body = chunk .. body
          end)
          return req:on("end", function()
            local bodyObj = querystring.parse(body)
            req.body = bodyObj or { }
            local result, err = that.router:execute(method, url, params)
            if not result then
              print(err)
              return that:notFound(req, res)
            end
          end)
        else
          local result, err = that.router:execute(method, url, params)
          if not result then
            print(err)
            return that:notFound(req, res)
          end
        end
      end
    end,
    match = function(self, method, path, fn)
      local routeFunc
      routeFunc = function(params)
        local req, res
        req, res = params[1], params[2]
        req.params = params
        if req.headers.cookie then
          local cookie = Cookie:parse(req.headers.cookie)
          req.cookie = cookie
        else
          req.cookie = { }
        end
        res:on('finish', function()
          return helpers.log(req, res)
        end)
        return fn(req, res, params)
      end
      return self.router:match(method, path, routeFunc)
    end,
    get = function(self, path, fn)
      return self:match("get", path, fn)
    end,
    post = function(self, path, fn)
      return self:match("post", path, fn)
    end,
    put = function(self, path, fn)
      return self:match("put", path, fn)
    end,
    delete = function(self, path, fn)
      return self:match("delete", path, fn)
    end,
    all = function(self, path, fn)
      for _, method in pairs({
        "get",
        "post",
        "delete",
        "put"
      }) do
        self:match(method, path, fn)
      end
    end,
    route = function(self, routes)
      for method, route in pairs(routes) do
        for path, fn in pairs(route) do
          self:match(method, path, fn)
        end
      end
    end,
    notFound = function(self, req, res)
      local fn = self.notFoundFunc
      return fn(req, res)
    end,
    static = function(self, fileDir, options)
      if options == nil then
        options = { }
      end
      options.root = options.root or "/"
      print("Serving Directory: " .. fileDir)
      local dirFiles = fse.readDirFile(fileDir)
      local maxAge = options.maxAge or 15552000
      for key, _ in pairs(dirFiles) do
        local mountPath = pathJoin(options.root, key)
        local filePath = pathJoin(fileDir, key)
        local fileType = mime.guess(filePath) or "text/plain; charset=utf-8"
        self:get(mountPath, function(req, res)
          local stat = fs.statSync(filePath)
          local etag = helpers.calcEtag(stat)
          local lastModified = os.date("%a, %d %b %Y %H:%M:%S GMT", stat.mtime.sec)
          local header = {
            ["Content-Type"] = fileType,
            ["Content-Length"] = stat.size,
            ['ETag'] = etag,
            ['Last-Modified'] = lastModified,
            ["Cache-Control"] = "public, max-age=" .. tostring(maxAge)
          }
          local statusCode = 200
          local content = fs.readFileSync(filePath)
          if req.headers['if-none-match'] == lastModified or req.headers['if-modified-since'] == lastModified then
            statusCode = 304
            content = nil
          end
          return res:send(content, statusCode, header)
        end)
      end
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, options)
      if options == nil then
        options = { }
      end
      self.options = options
      self.defaultFn = function(q, s)
        print(q.method, q.url)
        local content = "<h1 style='text-align: center; display: block; position: absolute; top: 32%; width: 400px; left: 50%; margin-left: -200px; font-weight: 200; font-family: 'Helvetica''>Page Not Found</h1>"
        return s:send(content, 404)
      end
      self.notFoundFunc = self.defaultFn
      self.router = Router.new()
      self.isHttps = false
      if self.options.isHttps == true then
        self.isHttps = true
        self.keyPath = self.options.keyPath
      end
      return self
    end,
    __base = _base_0,
    __name = "MoonCake"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  MoonCake = _class_0
end
return MoonCake
