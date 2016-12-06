local ServerResponse = require("http").ServerResponse
ServerResponse.flashData = {}
local template = require("./resty-template")
local etlua = require("./etlua")
local path = require("path")
local env = require("env")
local fs = require("fs")
local JSON = require("json")
local Cookie = require("./cookie")
local mime = require('./mime')
local helpers = require('./helpers')

local extend = function(obj, with_obj)
  for k, v in pairs(with_obj) do
    obj[k] = v
  end
  return obj
end

local function copy(a, b)
  a = a or {}
  b = b or {}
  local obj = {}
  for key, value in pairs(b) do
    obj[key] = value
  end
  for key, value in pairs(a) do
    obj[key] = value
  end
  return obj
end

function ServerResponse:send (data, code, header)
  if self._headerSent then
    return true
  end
  self:sendHead(code, header, data)
  if data then
    self:write(data)
  end
  self:finish()
  collectgarbage()
end

function ServerResponse:sendHead(code, header, data)
    if self._headerSent then
      p("------------------------------")
      p("Error", "Header Has Been Sent.")
      p("------------------------------")
      return true
    end
    self._headerSent = true
    code = code or self.statusCode or 200
    self:status(code)
    header = copy(copy(header, self.headers), {
      ["Connection"] = "keep-alive",
      ["Content-Type"] = "text/html; charset=utf-8",
      ["X-Served-By"] = "MoonCake",
      ["Content-Length"] = data and #data or 0
    })
    self:writeHead(self.statusCode, header)
end

function ServerResponse:setCookie(name, value, options)
  options = options or {}
  if type(options.httpOnly) == "nil" then
    options.httpOnly = true
  end
  local cookieStr = Cookie:serialize (name, value, options)
  self:setHeader("Set-Cookie", cookieStr)
  return self
end

function ServerResponse:deleteCookie(name)
  local options = {
    expires = 0,
    path = "/"
  }
  self:setCookie(name, "" , options)
  return self
end

ServerResponse.removeCookie = ServerResponse.deleteCookie

function ServerResponse:render(tpl, data)
  local callerSource = debug.getinfo(2).source

  if callerSource:sub(1,1) == "@" then
    callerSource =  callerSource:sub(2)
  elseif callerSource:sub(1, 7) == "bundle:" then
    callerSource = callerSource
  end

  local filePath = path.resolve(path.dirname(callerSource), tpl)
  local viewEngine = env.get("viewEngine")
  local renderer =  viewEngine == "etlua" and etlua or template
  local key = "no-cache"
  if env.get("PROD") == "TRUE" then
    key = nil
  end
  local localData = self._local or {}

  local flashData = { flash = nil}
  if self.req.session and self.req.session.sid then
    local sid = self.req.session.sid
    flashData =  {flash = ServerResponse.flashData[sid] or {} }
    ServerResponse.flashData[sid] = nil
  end
  local renderData = extend(extend(localData, data or {}), flashData)
  if viewEngine == "etlua" or path.extname(filePath) == ".etlua" then
    local templateString = fs.readFileSync(filePath)
    local include = function(fpath, data)
      local fpath = path.resolve(path.dirname(filePath), fpath)
      local tplString = fs.readFileSync(fpath)
      if not tplString then
        p("[Error]: File " .. fpath .. " Not Found.")
        return "<pre><code>File: `".. fpath .. "` not found.</code></pre>"
      end
      local renderData = extend(extend(localData or {}, {currentPath = fpath, include = include }),data or {})
      local tplResult, err = etlua.render(tplString, renderData)
      if tplResult then
        return tplResult
      else
        p("[Error Rendering HTML](:include) ", err)
        return "<h1>Internal Error</h1> <p style='color: red'>Error while render template :(</p>"
      end
    end
    renderData = extend(localData, {
      currentPath = filePath,
      include = include
    })
    if not templateString then
      templateString = tpl
    end
    local result, error = etlua.render(templateString, renderData)
    if not result then
      p("[Error Rendering HTML] ", error)
      self:status(500):render("./template/500.html")
    else
      self:send(result)
    end
  else
    local status, result = pcall(function() return template.render(filePath, renderData, key) end)
    if status then
      self:send(result)
    else
      p("[Error Rendering HTML] ",result)
      self:fail("Internal Error")
    end
  end
end

function ServerResponse:renderToFile(tpl, data, file, continueOnError)
    local callerSource = debug.getinfo(2).source

    if callerSource:sub(1,1) == "@" then
      callerSource =  callerSource:sub(2)
    elseif callerSource:sub(1, 7) == "bundle:" then
      callerSource = callerSource
    end

    local filePath = path.resolve(path.dirname(callerSource), tpl)
    local viewEngine = env.get("viewEngine")
    local renderer =  viewEngine == "etlua" and etlua or template
    local key = "no-cache"
    if env.get("PROD") == "TRUE" then
      key = nil
    end
    local localData = self._local or {}

    local flashData = { flash = nil}
    if self.req.session and self.req.session.sid then
      local sid = self.req.session.sid
      flashData =  {flash = ServerResponse.flashData[sid] or {} }
      ServerResponse.flashData[sid] = nil
    end
    local renderData = extend(extend(localData, data or {}), flashData)

    local status, result = pcall(function() return template.render(filePath, renderData, key) end)
    if status then
      fs.writeFileSync(file, result)
    else
      p("[Error Rendering HTML] ",result)
      if (continueOnError) then
        fs.writeFileSync(file, result)
      end
    end
end

function ServerResponse:status (statusCode)
  self.statusCode = statusCode
  return self
end

function ServerResponse:sendFile(filePath, headers)
  headers = headers or {}
  local callerSource = debug.getinfo(2).source

  if callerSource:sub(1,1) == "@" then
    callerSource =  callerSource:sub(2)
  elseif callerSource:sub(1, 7) == "bundle:" then
    callerSource = callerSource
  end

  filePath = path.resolve(path.dirname(callerSource), filePath)
  local stat = fs.statSync(filePath)
  if not(stat) then
    return self:send("<p>Can't get "..filePath .. "</p>", 404)
  end
  local fileType = mime.guess(filePath) or "application/octet-stream: charset=utf8"
  local etag = helpers.calcEtag(stat)
  local lastModified = os.date("%a, %d %b %Y %H:%M:%S GMT", stat.mtime.sec)
  local header = extend({
    ["Content-Type"] = fileType,
    ["Content-Length"] = stat.size,
    ['ETag'] = etag,
    ['Last-Modified'] = lastModified
  }, headers or {})
  local statusCode = 200
  local content = fs.readFileSync(filePath)
  if self.req.headers["if-none-match"] == etag or self.req.headers["if-modified-since"] == lastModified then
    statusCode = 304
    content = nil
  end
  if self._headerSent then
    return true
  end
  self:sendHead(statusCode, header, nil)
  fs.createReadStream(filePath):pipe(self)
end

function ServerResponse:redirect(url, code)
  code = code or 302
  self:status(code):setHeader("Location", url)
  self:send()
  return self
end

function ServerResponse:json(obj, code, headers)
  headers = copy(headers, {
    ["Content-Type"] = "application/json"
  })
  self:send(JSON.stringify(obj), code, headers)
end

function ServerResponse:flash(type, flash)
  local sid
  if self.req.session and self.req.session.sid then
    sid = self.req.session.sid
    ServerResponse.flashData[sid] = ServerResponse.flashData[sid] or {}
    ServerResponse.flashData[sid][type] = flash
  end
end

function ServerResponse:locals(data)
  local localData = self._local or {}
  self._local = extend(localData, data)
end

function ServerResponse:fail(reason)
  self:status(500):send(reason)
end

function ServerResponse:not_modified(header)
  self:send(nil, 304, header)
end
