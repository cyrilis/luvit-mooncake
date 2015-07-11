require("./libs/Response")
local http = require("http")
local https = require("https")
local path = require("path")
local fs = require('fs')
local fse = require("./libs/fse")
local Router = require('./libs/router')
local mime = require('./libs/mime')
local helpers = require('./libs/helpers')
local querystring = require('querystring')
local Cookie = require("./libs/cookie")
require("./libs/ansicolors")
print((" Hello "):bluebg(), (" World "):redbg(), (" from MoonCake "):yellowbg(), (" ! "):greenbg())

local Emitter = require("core").Emitter

local getQueryFromUrl = function(url)
  local params = string.match(url, "?(.*)") or ""
  return querystring.parse(params)
end

local MoonCake = Emitter:extend()

function MoonCake:initialize(options)
    options = options or {}
    self.options = options
    self.notFoundFunc = function(req, res)
        print(req.method, req.url)
        local content = "<h1 style='text-align: center; display: block; position: absolute; top: 32%; width: 400px; left: 50%; margin-left: -200px; font-weight: 200; font-family: 'Helvetica''>Page Not Found</h1>"
        res:send(content, 404)
    end
    self.router = Router.new()
    self.isHttps = false
    if self.options.isHttps == true then
        self.isHttps = true
        self.keyPath = self.options.keyPath
    end
    return self
end

function MoonCake:listen (port)
    return self:start(port)
end

function MoonCake:start (port)
    if port == nil then
        port = 8080
    end
    self:genRoute()
    local fn = self.fn
    if self.isHttps == true then
        local keyConfig = {
            key = fs:readFileSync(path.join(self.keyPath, "key.pem")),
            cert = fs:readFileSync(path.join(self.keyPath, "cert.pem"))
        }
        http.createServer(keyConfig, fn):listen(port)
    else
        http.createServer(fn):listen(port)
    end
    print(("Moon"):redbg(),("Cake"):yellowbg()," Server Listening at http://localhost:" .. tostring(port) .. "/")
end

function MoonCake:use(fn)
    self._use = self._use or {}
    table.insert(self._use, fn)
end

function MoonCake:useit(req, res, callback)

    local funcArray = helpers.copy(self._use or {})
    local function _useit(req, res)
        local next = table.remove(funcArray or {})
        if next then
            next(req, res, function()
                _useit(req, res)
            end)
        else
            callback(req, res)
        end
    end
    _useit(req, res)
end

function MoonCake:genRoute ()
    local that = self
    self.fn = function(req, res)
        local url = req.url
        local method = string.lower(req.method)
        res.req = req
        local params = {req, res }
        local querys = getQueryFromUrl(url)
        req.query = querys
        req.start_time = helpers.getTime()
        res:on("finish", function()
            helpers.log(req, res)
        end)
        if req.headers.cookie then
            local cookie = Cookie:parse(req.headers.cookie)
            req.cookie = cookie or {}
        else
            req.cookie = {}
        end
        if method ~= "get" then
            local body = ""
            req:on("data", function(chunk)
                body = body..chunk
            end)
            req:on("end", function()
                local bodyObj = querystring.parse(body)
                req.body = bodyObj or {}
                if req.body._method then
                    method = req.body._method
                end
                that:useit(req, res, function(req, res)
                    local result, err = that.router:execute(method, url, params)
                    if not result then
                        print(err)
                        return that:notFound(req, res)
                    end
                end)
            end)
        else
            req.body = {}
            that:useit(req, res, function(req, res)
                local result, err = that.router:execute(method, url, params)
                if not result then
                    print(err)
                    that:notFound(req, res)
                end
            end)
        end
    end
end

function MoonCake:match (method, path, fn)
    local routeFunc = function(params)
        local req, res = params[1], params[2]
        req.params = params
        fn(req, res, params)
    end
    self.router:match(method, path, routeFunc)
end

function MoonCake:get(path, fn)
    self:match("get", path, fn)
end
function MoonCake:post(path, fn)
    self:match("post", path, fn)
end
function MoonCake:put(path, fn)
    self:match("put", path, fn)
end
function MoonCake:delete(path, fn)
    self:match("delete", path, fn)
end
function MoonCake:all(path, fn)
    for _, method in pairs({"get", "post", "put", "delete"}) do
        self:match(method, path, fn)
    end
end

function MoonCake:route(routes)
    for method, route in pairs(routes) do
        for path, fn in pairs(route) do
            self:match(method, path, fn)
        end
    end
end

function MoonCake:notFound(req, res)
    local fn = self.notFoundFunc
    fn(req, res)
end

function MoonCake:static (fileDir, options)
    options = options or {}
    options.root = options.root or "/"
    print("Serving Directory:" .. fileDir)
    local maxAge = options.maxAge or 15552000 -- half a year
    local routePath = path.join(options.root, ":file")
    local notFoundFunc = self.notFoundFunc
    return self:get(routePath, function(req, res)
        local trimdPath = req.params.file:match("([^?]*)(?*)(.*)")
        local filePath = path.resolve(fileDir, trimdPath)
        local stat = fs.statSync(filePath)
        if not(stat) then
            return notFoundFunc(req, res)
        end
        local fileType = mime.guess(filePath) or "text/plain: charset=utf8"
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
        if req.headers["if-none-match"] == lastModified or req.headers["if-modified-since"] == lastModified then
            statusCode = 304
            content = nil
        end
        return res:send(content, statusCode, header)
    end)
end


module.exports = MoonCake

return MoonCake