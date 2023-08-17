import std/json

const
  dirtyGptPort {.intdefine.} = 5552
  hostname = "https://localhost:" & $dirtyGptPort

const
  promptsApi = "/prompts"

type
  DirtyGptPrompt = ref object
    id: int
    prompt, response: string
  DirtyGptResponse* = ref object
    id: int
    text: string

when defined js:
  # Userscript
  import std/asyncjs
  # from std/dom import setInterval, document, querySelector, alert
  import std/dom 
  import std/jsffi

  from pkg/gm_api import Gm, xmlHttpRequest

  proc jsObjectToJson(obj: JSObject): cstring {.importjs: "JSON.stringify(@)", nodecl.}
  proc newPromise[T](handler: proc (resolve, reject: proc (response: T))): Future[T] {.importc, nodecl.}
  proc sleepAsync(ms: int): Future[bool] {.async.} =
    var promise = newPromise() do (resolve: proc(r: bool)):
      discard setTimeout(proc = resolve(true), ms)
    return promise
    

  proc fetchPrompts: Future[seq[DirtyGptPrompt]] {.async.} =
    var promise = newPromise() do (resolve, reject: proc(response: seq[DirtyGptPrompt])):
      echo "new"
      Gm.xmlHttpRequest(
        hostname & promptsApi,
        "GET",
        onload = proc (jsObj: JsObject) = resolve(jsObj.jsObjectToJson.`$`.parseJson.to seq[DirtyGptPrompt]),
        onerror = proc (jsObj: JsObject) = reject @[]
      )
    return promise

  proc setInterval(action: proc: Future[void]; ms: int) {.importc, nodecl.}

  proc loop {.async.} =
    echo "loop"
    let prompts = await fetchPrompts()
    for prompt in prompts:
      window.alert $prompt[]
    discard await sleepAsync 1000
    await loop()

else:
  # Lib
  import std/asyncdispatch
  import std/asynchttpserver

  # from std/asynchttpserver import Request, newAsyncHttpServer, serve, close,
  #                                 AsyncHttpServer

  type
    DirtyGpt* = ref object
      server: AsyncHttpServer
      prompts: seq[DirtyGptPrompt]

  using
    self: DirtyGpt

  proc newDirtyGpt*: DirtyGpt =
    ## Creates a new DirtyGpt websocket
    new result
    result.server = newAsyncHttpServer()
    let dirtyGpt = result
    asyncCheck result.server.serve(Port dirtyGptPort) do (req: Request) {.async, gcsafe.}:
      case req.url.path:
        of promptsApi:
          await req.respond(Http200, $ %*dirtyGpt.prompts)
        else:
          await req.respond(Http404, "404 Not Found")


  proc prompt*(self; prompt: string): Future[string] {.async.} =
    ## Prompts to ChatGPT by using userscript
    let currPrompt = DirtyGptPrompt(
      id: self.prompts.len,
      prompt: prompt
    )
    self.prompts.add currPrompt
    echo "create: ", currPrompt[]

    while true:
      var resp = self.prompts[currPrompt.id].response
      echo "poll: ", self.prompts[currPrompt.id][]
      if resp.len > 0:
        return resp
      else:
        poll()

  when isMainModule:
    var gpt = newDirtyGpt()
    var resp = waitFor gpt.prompt "Hello"
    echo resp
    echo "end"
