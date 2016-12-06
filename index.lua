require("./libs/Response")
local http = require("http")
local https = require("https")
local path = require("path")
local fs = require('fs')
local mime = require('./libs/mime')
local helpers = require('./libs/helpers')
local querystring = require('querystring')
local JSON = require("json")
local Cookie = require("./libs/cookie")
require("./libs/ansicolors")

d((" Hello "):bluebg(), (" World "):redbg(), (" from MoonCake "):yellowbg(), (" ! "):greenbg())

local Emitter = require("core").Emitter

local _routes = {}

local getQueryFromUrl = function(url)
  local params = string.match(url, "?(.*)") or ""
  return querystring.parse(params)
end

local MoonCake = Emitter:extend()

function MoonCake:initialize(options)
    options = options or {}
    self.options = options
    self.notAuthorizedRequest = function(req, res, next)
        res:status(403):render("./libs/template/403.html")
    end
    self.indexDirectory = function(filePath, routePath, req, res)
        local fileList = fs.readdirSync(filePath)
        local parentPathList = helpers.split2(routePath, "/")
        if routePath:sub(#routePath) == "/" then
            table.remove(parentPathList)
        end
        table.remove(parentPathList)
        local parentPath = table.concat(parentPathList, "/")
        if parentPath == "" then parentPath = "/" end
        local data = {parentPath = parentPath, currentPath = routePath, files = {}}
        for idx, v in pairs(fileList) do
            local fstat = fs.statSync(path.join(filePath, v))
            local vfilePath = path.join(routePath, v)
            if fstat.type ~= "file" then
                vfilePath = vfilePath .. "/"
            end
            local lastModifiedTime = os.date("%c", fstat.mtime.sec)
            data.files[idx] = {
                name = v,
                path = vfilePath,
                lastModified = lastModifiedTime,
                type = fstat.type,
                size = fstat.size
            }
        end
        res:render(path.resolve(module.dir, "./libs/template/directory.html"), data)
    end
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

function MoonCake:start (port, host)
    host = host or "127.0.0.1"
    if port == nil then
        port = 8080
    end
    local fn = function(req, res)
        self:handleRequest(req, res)
    end
    if self.isHttps == true then
        local keyConfig = {
            key = fs:readFileSync(path.join(self.keyPath, "key.pem")),
            cert = fs:readFileSync(path.join(self.keyPath, "cert.pem"))
        }
        self.server = https.createServer(keyConfig, fn):listen(port, host)
    else
        --- Export server instance
        self.server = http.createServer(fn):listen(port, host)
    end
    d(("Moon"):redbg(),("Cake"):yellowbg()," Server Listening at http".. (self.isHttps and "s" or "") .."://".. host .. ":" .. tostring(port) .. "/")
end

function MoonCake:handleRequest(req, res)
    local url = req.url
    local method = string.lower(req.method)
    res.req = req
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
        local fileData = ""
        req:on("data", function(chunk)
            if req.headers['Content-Type'] then
                if string.find(req.headers['Content-Type'], "multipart/form-data", 1, true) then
                    fileData = fileData..chunk
                else
                    body = body..chunk
                end
            else
                body = body..chunk
                if #body > 0 then
                    res:status(400):json({
                        status = "failed",
                        success = false,
                        code = 400,
                        message = "Request is not valid, 'Content-Type' should be specified in header if request body exist."
                    })
                end
            end
        end)
        req:on("end", function()

            local contentType = req.headers['Content-Type']
            if contentType and string.find(contentType, "multipart/form-data", 1, true) then
                local boundary = string.match(fileData, "^([^\r?\n?]+)\n?\r?")
                local fileArray = helpers.split2(fileData,boundary)
                table.remove(fileArray)
                table.remove(fileArray, 1)
                req.files = {}
                req.body = {}
                for _, fileString in pairs(fileArray) do
                    local header, headers = string.match(fileString, "^\r?\n(.-\r?\n\r?\n)"), {}
                    local content = ""
                    string.gsub(fileString, "^\r?\n(.-\r?\n\r?\n)(.*)", function(_,b)
                        if b:sub(#b-1):find("\r?\n") then
                            local _, n = b:sub(#b-1):find("\r?\n")
                            content = b:sub(0,#b-n)
                        end
                    end)
                    string.gsub(header, '%s?([^%:?%=?]+)%:?%s?%=?%"?([^%"?%;?%c?]+)%"?%;?%c?', function(k,v)
                        headers[k] = v
                    end)
                    if headers["filename"] then
                        local tempname = os.tmpname()
                        fs.writeFileSync(tempname, content)
                        req.files[headers["name"]] = {path = tempname, name = headers["filename"], ["Content-Type"] = headers["Content-Type"] }
                    else
                        req.body[headers["name"]] = content
                    end
                end
            else
                local bodyObj
                if contentType then
                    if req.headers["Content-Type"]:sub(1,16) == 'application/json' then
                        -- is this request JSON?
                      bodyObj = JSON.parse(body)
                    elseif req.headers["Content-Type"]:sub(1, 33) == "application/x-www-form-urlencoded" then
                        -- normal form
                        bodyObj = querystring.parse(body)
                    else
                        -- content-type: text/xml
                        bodyObj = body
                    end
                else
                    if #body > 0 then
                        res:status(400):json({
                            status = "failed",
                            success = false,
                            code = 400,
                            message = "Bad Request, 'Content-Type' in request headers should be specified if request body exist."
                        })
                    end
                end
                req.body = bodyObj or {}
                if req.body._method then
                    req._method = req.body._method:lower()
                end
            end

            req.body = req.body or {}
            req.files = req.files or {}

            self:execute(req, res)
        end)
    else
        req.body = {}
        self:execute(req, res)
    end
end

function MoonCake.notFound(req, res, err)
    if(err) then
        MoonCake.serverError(req, res, err)
    else
        p("404 - Not Found!")
        res:status(404):render("./libs/template/404.html")
    end
end

function MoonCake.serverError (req, res, err)
    d(("MoonCake: Server Error"):redbg():white())
    p(err)
    res:status(500):render("./libs/template/500.html")
end

function MoonCake:execute(req, res)
    function go (i, error, req, res)
        local success, err = pcall(function ()
            i = i or 1
            local next = function(error)
                if(error)then
                    MoonCake.serverError(req, res, error)
                else
                    if i < #_routes then
                        return go(i + 1, error, req, res)
                    else
                        MoonCake.notFound(req, res)
                    end
                end
            end

            return _routes[i](req, res, next)
        end)
        if not success then
            p(err)
            MoonCake.serverError(req, res, err)
        end
    end
    go(1, nil, req, res);
end

function MoonCake:use(fn)
    table.insert(_routes, fn)
    return self
end

function MoonCake:clear()
    _routes = {}
end

local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'

local function escape(str)
    return str:gsub(quotepattern, "%%%1")
end

local function compileRoute(route)
  local parts = {"^"}
  local names = {}
  for a, b, c, d in route:gmatch("([^:]*):([_%a][_%w]*)(:?)([^:]*)") do
    if #a > 0 then
      parts[#parts + 1] = escape(a)
    end
    if #c > 0 then
      parts[#parts + 1] = "(.*)"
    else
      parts[#parts + 1] = "([^/]*)"
    end
    names[#names + 1] = b
    if #d > 0 then
      parts[#parts + 1] = escape(d)
    end
  end
  if #parts == 1 then
    return function (string)
      if string == route then
           return {}
       else
          if route == string:gsub("%/$", "") then
              return {}
          else
              if route:gsub("%/$", "") == string then
                  return {}
              end
          end
      end
    end
  end

  if #parts > 1 and not(parts[#parts]:match("%*%)")) then
      local lastComp = parts[#parts]
      if lastComp:sub(#lastComp) == "/" then
          lastComp = lastComp:sub(1, #lastComp - 1)
      end
      parts[#parts] = lastComp .. "%/?"
  end

  parts[#parts + 1] = "$"
  local pattern = table.concat(parts)
  return function (string)
    local matches = {string:match(pattern)}
    if #matches > 0 then
      local results = {}
      for i = 1, #matches do
        results[i] = matches[i]
        results[names[i]] = matches[i]
      end
      return results
    end
  end
end

function MoonCake:route(method, path, fn)
    local _path = path and compileRoute(path)
    self:use(function (req, res, next)
        if method:lower() ~= (req.method):lower() and method:lower() ~= "all" and method:lower() ~= (req._method or ""):lower() then
            return next()
        end
        if req._method and method:lower() ~= (req._method or ""):lower() then
            return next()
        end
        local params
        if _path then
            local pathname, query = req.url:match("^([^?]*)%??(.*)");
            params = _path(pathname)
            if not params then return next() end
        end
        req.params = params or {}
        return fn(req, res, next)
    end)
    return self
end

function MoonCake:get(path, fn)
    self:route("get", path, fn)
end
function MoonCake:post(path, fn)
    self:route("post", path, fn)
end
function MoonCake:put(path, fn)
    self:route("put", path, fn)
end
function MoonCake:delete(path, fn)
    self:route("delete", path, fn)
end
function MoonCake:patch(path, fn)
    self:route("patch", path, fn)
end
function MoonCake:all(path, fn)
    self:route("all", path, fn)
end

function MoonCake:static (fileDir, options)
    if type(options) == "string" then
        options = {
            root = options
        }
    end

    if type(options) == "number" then
        options = {
            maxAge = options
        }
    end
    options = options or {}
    options.root = options.root or "/"
    options.index = options.index or false
    print("Serving Directory:" .. fileDir)
    local headers = {}
    local maxAge = options.maxAge or options.age or 15552000 -- half a year
    headers["Cache-Control"] = "public, max-age=" .. tostring(maxAge)
    local routePath = path.join(options.root, ":file:")
    self:get(routePath, function(req, res, next)
        local trimdPath = req.params.file:match("([^?]*)(?*)(.*)")
        local filePath = path.resolve(fileDir, trimdPath)
        local trimedRoutePath = path.resolve(options.root, trimdPath)
        if fs.existsSync(filePath) then
            if fs.statSync(filePath).type == "file" then
                res:sendFile(filePath, headers)
            else
                if options.index then
                    self.indexDirectory(filePath, trimedRoutePath, req, res)
                else
                    self.notAuthorizedRequest(req, res, next)
                end

            end
        else
            next()
        end
    end)
    return self
end

return MoonCake
