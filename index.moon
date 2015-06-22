require "./libs/Response"
http = require "http"
https = require "https"
path = require("path")
fs = require 'fs'
fse = require "./libs/fse"
Router = require './libs/router'
mime = require './libs/mime'
helpers = require './libs/helpers'
querystring = require 'querystring'
Cookie = require "./libs/cookie"
uv = require "uv"

require("./libs/ansicolors")

print((" Hello ")\bluebg(),(" World ")\redbg(), (" from MoonCake ")\yellowbg(), (" ! ")\greenbg())

getQueryFromUrl = (url)->
  params = string.match(url, "?(.*)") or ""
  return querystring.parse(params)

class MoonCake

  new: (@options = {} )=>
    @defaultFn = (q, s) ->
      print q.method, q.url
      content = "<h1 style='text-align: center; display: block; position: absolute; top: 32%; width: 400px; left: 50%; margin-left: -200px; font-weight: 200; font-family: 'Helvetica''>Page Not Found</h1>"
      s\send content, 404
    @notFoundFunc = @defaultFn
    @router = Router.new()
    @isHttps = false
    if @options.isHttps == true
      @isHttps = true
      @keyPath = @options.keyPath
    @

  listen: (port)=>
    @start(port)

  start: (port = 8080)=>
    @genRoute()
    fn = @fn
    if @isHttps == true
      keyConfig = {
        key: fs\readFileSync(path.join(@keyPath, "key.pem")),
        cert: fs\readFileSync(path.join(@keyPath, "cert.pem"))
      }
      https\createServer(keyConfig, fn)\listen(port)
    else
      http.createServer(fn)\listen(port)
    print "Server listenning at http://localhost:#{port}/ "

  genRoute: ()=>
    that = @
    @fn = (req,res)->
      url = req.url
      method = string.lower req.method
      res.req = req
      params = {req,res}
      querys = getQueryFromUrl(url)
      req.query = querys
      req.start_time = uv.now()
      res\on 'finish', ()->
        helpers.log(req, res)
      if method ~= "get"
        body = ""
        req\on "data", (chunk)->
          body = chunk .. body
        req\on "end", ()->
          bodyObj = querystring.parse(body)
          req.body = bodyObj or {}
          result, err = that.router\execute(method, url, params)
          if not result
            print err
            that\notFound(req,res)
      else
        result, err = that.router\execute(method, url, params)
        if not result
          print err
          that\notFound(req,res)

  match: (method, path, fn)=>
    routeFunc = (params)->
      {req,res} = params
      req.params = params
      if req.headers.cookie
        cookie = Cookie\parse req.headers.cookie
        req.cookie = cookie
      else
        req.cookie = {}
      fn(req, res, params)

    @router\match method, path, routeFunc

  get: (path, fn)=>
    @match "get", path, fn

  post: (path, fn)=>
    @match "post", path, fn

  put: (path, fn)=>
    @match "put", path, fn

  delete: (path, fn)=>
    @match "delete", path, fn

  all: (path, fn)=>
    for _, method in pairs {"get", "post", "delete", "put"}
      @match method, path, fn

  route: (routes)=>
    for method, route in pairs(routes)
      for path, fn in pairs(route)
        self\match(method, path, fn)

  notFound: (req, res)=>
    fn = @notFoundFunc
    fn(req, res)

  static: (fileDir, options = {})=>
    options.root = options.root or "/"
    print "Serving Directory:" .. fileDir
    maxAge = options.maxAge or 15552000
    routePath = path.join(options.root, ":file")
    notFoundFunc = @notFoundFunc
    @get routePath, (req, res)->
      trimdPath = req.params.file\match("([^?]*)(?*)(.*)")
      filePath = path.resolve(fileDir, trimdPath)
      stat = fs.statSync(filePath)
      if not(stat)
        return notFoundFunc(req, res)
      fileType = mime.guess(filePath) or "text/plain; charset=utf-8"
      etag = helpers.calcEtag(stat)
      lastModified = os.date("%a, %d %b %Y %H:%M:%S GMT", stat.mtime.sec)
      header = {
        ["Content-Type"]:   fileType
        ["Content-Length"]: stat.size
        ['ETag']:           etag
        ['Last-Modified']: lastModified
        ["Cache-Control"]: "public, max-age=#{maxAge}"
      }
      statusCode = 200
      content = fs.readFileSync(filePath)
      if req.headers['if-none-match'] == lastModified or req.headers['if-modified-since'] == lastModified
        statusCode = 304
        content = nil
      res\send(content, statusCode, header)


return MoonCake
