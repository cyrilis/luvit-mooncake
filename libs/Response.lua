ServerResponse = require("http").ServerResponse
ServerResponse.flashData = {}
template = require("./resty-template")
path = require("path")
env = require("env")

extend = function(obj, with_obj)
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
    p("------------------------------")
    p("Error", "Header Has Been Sent.")
    p("------------------------------")
    return false
  end
  self._headerSent = true
  code = code or self.statusCode or 200
  self:status(code)
  header = copy(copy(header, self.headers), {
    ["Connection"] = "keep-alive",
    ["Content-Type"] = "text/html; charset=utf-8",
    ["X-Served-By"] = "MoonCake"
  })
  self:writeHead(self.statusCode, header)
  if data then
    self:write(data)
  end
  self:finish()
  collectgarbage()
end

function ServerResponse:render(tpl, data)
  local callerSource = debug.getinfo(2).source
  local filePath = path.resolve(path.dirname(callerSource), tpl)
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
  tpl = template.render(filePath, renderData, key)
  self:send(tpl)
end

function ServerResponse:status (statusCode)
  self.statusCode = statusCode
  return self
end

function ServerResponse:redirect(url, code)
  code = code or 302
  self:status(code):setHeader("Location", url)
  self:send()
  return self
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
  self:send(reason, 500, {
    ['Content-Type'] = 'text/plain; charset=UTF-8',
    ['Content-Length'] = #reason
  })
end

function ServerResponse:not_modified(header)
  self:send(nil, 304, header)
end
