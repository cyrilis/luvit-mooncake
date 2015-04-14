ServerResponse = require("http").ServerResponse
template = require("./resty-template")
path = require("path")
env = require("env")

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
end

function ServerResponse:render(tpl, data)
  callerSource = debug.getinfo(2).source
  filePath = path.resolve(path.dirname(callerSource), tpl)
  key = "no-cache"
  if env.get("PROD") == "TRUE" then
    key = nil
  end
  tpl = template.render(filePath, data, key)
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

function ServerResponse:fail(reason)
  self:send(reason, 500, {
    ['Content-Type'] = 'text/plain; charset=UTF-8',
    ['Content-Length'] = #reason
  })
end

function ServerResponse:not_modified(header)
  self:send(nil, 304, header)
end
