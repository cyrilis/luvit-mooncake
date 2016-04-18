local router = {
  _VERSION     = 'router.lua v1.0.1',
  _DESCRIPTION = 'A simple router for Lua',
  _LICENSE     = [[
    MIT LICENSE

    * Copyright (c) 2013 Enrique García Cota
    * Copyright (c) 2013 Raimon Grau
    * Copyright (c) 2015 Lloyd Zhou
    * Copyright (c) 2015 Cyril Hou

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local COLON_BYTE = string.byte(':', 1)

local function match_one_path(node, method, path, f)
  for token in path:gmatch("[^/]+") do
    node[token] = node[token] or {}
    node = node[token]
  end
  node["LEAF"] = f
end

local function resolve(path, node, params)
  local _, _, current_token, newPath = path:find("/([^/?]+)([^?]*)(?*)")
  if not current_token and node["LEAF"] then return node["LEAF"], params end

  for child_token, child_node in pairs(node) do
    if child_token == current_token then
      local f, bindings = resolve(newPath, child_node, params)
      if f then
        return f, bindings end
    end
  end
  for child_token, child_node in pairs(node) do
    if child_token:byte(1) == COLON_BYTE then -- token begins with ':'
    local param_name = child_token:sub(2)
    local param_value = params[param_name]
    params[param_name] = param_value or current_token -- store the value in params, resolve tail path
    local f, bindings = resolve(newPath, child_node, params)
    if f then
      return f, bindings end
    if child_node["LEAF"] then
      params[param_name] = path:match("/(.*)")
      return child_node["LEAF"], params
    end
    params[param_name] = param_value -- reset the params table.
    elseif child_token:sub(1, 2) == "*" then
      local splat = current_token or path
      params.splat = splat
      return node[child_token]["LEAF"], params
    end
  end
  return false
end

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

------------------------------ INSTANCE METHODS ------------------------------------
local Router = {}

function Router:resolve(method, path, params)
  return resolve(path, self._tree[method] or {} , params or {})
end

function Router:execute(method, path, query_params)
  local f,params = self:resolve(method, path, query_params)
  if not f then return nil, ('Could not resolve %s %s'):format(method, path) end
  return true, f(params)
end

function Router:match(method, path, f)
  if type(method) == 'string' then -- always make the method to table.
    method = {[method] = {[path] = f}}
  end
  for m, routes in pairs(method) do
    for path, f in pairs(routes) do
      if not self._tree[m] then self._tree[m] = {} end
      match_one_path(self._tree[m], method, path, f)
    end
  end
end

for _,http_method in ipairs({'get', 'post', 'put', 'delete', 'trace', 'connect', 'options', 'head'}) do
  Router[http_method] = function(self, path, f) -- Router.get = function(self, path, f)
    return self:match(http_method, path, f)     --   return self:match('get', path, f)
  end                                           -- end
end

local router_mt = { __index = Router }

------------------------------ PUBLIC INTERFACE ------------------------------------
router.new = function()
  return setmetatable({ _tree = {} }, router_mt)
end

return router
