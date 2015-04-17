local MySQL = require("./luvit-mysql/mysql.lua")

Object = require("core").Object

local timer = require( "timer" ) -- luvit built-in

local client = MySQL.createClient( { database="test",user="passtestuser",port=3306,password="hoge", logfunc= print } )

client:ping( function()    print("ping received")  end)


local Module = Object:extend()

function Module:initialize (data)
  self.saved = false
  that = self
  valid, err = self:checkType(data)
  if not valid then
    p('------')
    return error(tostring(err))
  end
  self.data = data
  return self
end

function Module:checkType (data)
  that = self
  if type(data) == "table" then
    for key, value in pairs(data) do
      if type(value) ~= "string" and type(value) ~= "number" and value ~= nil then
        return false, error("attribute in invalid data type " .. key)
      end
      if that.attributes[key].type ~= type(value) then
        if that.attributes[key] == "nil" then
          return false, error("attribute not defined")
        elseif not( that.attributes[key].type == "date" and (type(value) == "string" or type(value) ==  "number") ) then
          return false, error("value type doesn't match")
        end
      end
      if that.attributes[key].required == true and value == nil then
        return false, error("attribute ".. key .." is required")
      end
    end
    return true, "OK"
  else
    return false, error("data must be a key-value pair")
  end
end

function Module:save(fn)
  self.saved = self.saved or false
  that = self
  if self.saved then
    return fn(error("This Module has saved"))
  end
  data = self.data
  keys = ""
  values = ""

  -- INSERT INTO tablename (col_name, col_date) VALUES ('DATE: Manual Date', '2008-7-04')
  for key, value in pairs(data) do
    if that.attributes[key].type == "date" and type(value) == "string" then
      value = os.date("%Y-%m-%d %H:%M:%S",value)
    end
    if type(value) == "string" then
      value = "'".. value .. "'"
    end
    if value ~= nil then
      keys = keys .. " " .. key .. ","
      values = values .. " " .. value .. ","
    end
  end

  -- Generate query string
  queryStr = "INSERT INTO ".. that.name .. " (" .. keys:sub(0, -2) .. ") VALUES (" .. values:sub(0, -2) .. ");"

  -- query action
  client:query( queryStr, function(err,res)
    print(err, res)
    fn(err, data)
    if err == nil then
      that.saved = true
    else
      print(err , "xxx")
    end
  end)
end

function Module:update(attr, updateData, fn)
  queryStr = " WHERE"
  for key, value in pairs(attr) do
    queryStr = queryStr .. " " .. key .. "=" .. value .. ","
  end
  valid, err = self:checkType(updateData)
  if not valid then
    fn(err)
  end
  that = self
  updateStr = " SET"
  for key, value in pairs(updateData) do
    if that.attribute[key].type == "date" and type(value) == "string" then
      value = os.date("%Y-%m-%d %H:%M:%S",value)
    end
    if type(value) == "string" then
      value = "'".. value .. "'"
    end
    if value ~= nil then
      updateStr = updateStr .. " ".. key .. "=" .. value .. ","
    end
  end
  sqlString = "UPDATE " .. self.name .. updateStr:sub(0, -2) .. queryStr:sub(0, -2)
  client:query(queryStr, function(err, res)
    p(err, res)
    fn(err, res)
  end)
end

function Module:find(attr, fn)
  queryStr = "SELECT * from " .. self.name .. " WHERE BINARY "
  that = self
  if attr ~= nil then
    for key, value in pairs(updateData) do
      if that.attribute[key].type == "date" and type(value) == "string" then
        value = os.date("%Y-%m-%d %H:%M:%S",value)
      end
      if type(value) == "string" then
        value = "'".. value .. "'"
      end
      if value ~= nil then
        queryStr = queryStr .. " ".. key .. "=" .. value .. ","
      end
    end
    queryStr = queryStr:sub(0, -2)
  else
    queryStr = "SELECT * from " .. self.name
  end
  client:query(queryStr, function(err, res)
    p(err, res)
    fn(err, res)
  end)
end

function Module:remove(attr, fn)
  -- DELETE FROM tutorials_tbl WHERE tutorial_id=3;
  queryStr = "DELETE FROM " .. self.name .. " WHERE "

  for key, value in pairs(updateData) do
    if that.attribute[key].type == "date" and type(value) == "string" then
      value = os.date("%Y-%m-%d %H:%M:%S",value)
    end
    if type(value) == "string" then
      value = "'".. value .. "'"
    end
    if value ~= nil then
      queryStr = queryStr .. " ".. key .. "=" .. value .. ","
    end
  end
  queryStr = queryStr:sub(0, -2)

  client:query(queryStr, function(err, res)
    p(err, res)
    fn(err, res)
  end)

end

function Module:setup(fn)
  that = self

  queryStr = "CREATE TABLE " .. self.name .. " (id INT(11) AUTO_INCREMENT, "
  for key, value in pairs(self.attributes) do
    fieldType = ""
    if value.type == "string" then
      fieldType = "VARCHAR(255)"
    elseif value.type == "number" then
      fieldType = "INT(11)"
    elseif value.type == "date" then
      fieldType = "DATETIME"
    end
    queryStr = queryStr .. key .." ".. fieldType .. ","
  end
  queryStr = queryStr .. " PRIMARY KEY (id) );"

  client:query( queryStr,function(err,res,fields)
      print("CREATE TABLE DONE")
      assert( not err )
      fn(err, res, fields)
  end)
end


local Table = {}

function Table:create(name, attributes, fn)
  TableModule = Module:extend()
  TableModule.name = name
  TableModule.attributes = attributes
  return TableModule
end

--[[

Person = Table:create("person", {
  name = {type= "string", required = true},
  age = {type = "number", required = false},
  title = {type = "string", required = false},
  birthday = {type = "date", rquired = false}
})

Person:setup(function(err, res, fields)
  poter = Person:new({
    name = "Harry Potter",
    age = 20,
    title = "student",
    birthday = os.time()
  })
  poter:save()
end)

--]]
