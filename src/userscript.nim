when not defined js:
  {.fatal: "JS only module".}
when not isMainModule:
  {.fatal: "This userscript cannot be imported".}

import std/asyncjs
import std/sugar
import std/jsconsole

from std/dom import document, Interval, click, setInterval, clearInterval,
                    Element, querySelectorAll, Interval, clearInterval,
                    setTimeout, clearTimeout, Timeout
from std/json import parseJson, to, `$`, `%*`, `%`

import pkg/jswebsockets
from pkg/gm_api import Gm, registerMenuCommand

import dirtyGpt/jsutils
import dirtyGpt/turndown
import dirtyGpt/common

proc getPromptResponse: string =
  let responses = document.querySelectorAll ".markdown"
  result = turndown responses[^1].innerHtml

proc sclose(ws: Websocket) =
  # Silent close a socket (disable onClose)
  ws.onClose = proc (e: CloseEvent) = discard
  close ws
func available(ws: Websocket): bool {.inline.} =
  # check if ws is open
  not ws.isNil and ws.readyState == Open

proc main {.async.} =
  let
    promptField = await document.waitEl "#prompt-textarea"
    promptButton = await document.waitEl "#prompt-textarea + button"
  var
    ws: WebSocket
    wsId = 0

  proc clickButton(wid: int; button: Element) {.async.} =
    var
      interval: Interval
      delay = 500

    await newPromise() do (resolve: () -> void):
      interval = setInterval(proc() =
        if wsId != wid or not ws.available:
          clearInterval interval
        if not promptButton.disabled:
          click button
          clearInterval interval
          resolve()
      , delay)

  proc prompt(wid: int; text: cstring): Future[string] {.async.} =
    var
      interval: Interval
      limit = 500
      delay = 500

    promptField.setInputValue text
    await wid.clickButton promptButton
    await sleep 500

    return newPromise[string]() do (resolve: (string) -> void):
      interval = setInterval(proc() =
        if limit == 0 or wsId != wid or not ws.available:
          clearInterval interval
          resolve ""
        else:
          if promptButton.innerText.len == 0:
            clearInterval interval
            resolve getPromptResponse()
        dec limit
      , delay)

  proc startWs =
    if ws.isNil or ws.readyState == Closed:
      var
        available = true
        loopInterval: Interval
      ws = newWebSocket("ws://localhost:" & $dirtyGptPort)

      proc getPromptLoop =
        loopInterval = setInterval(proc =
          if available:
            ws.send wsMsgGetPrompt
            available = false
          else:
            ws.send wsMsgPing
        , clientLoopTime)

      ws.onOpen = proc (e: Event) =
        getPromptLoop()

      ws.onMessage = proc (e: MessageEvent) =
        let wid = wsId
        discard (proc {.async.} =
          var prompt = parseJson($e.data).to DirtyGptPrompt
          if not prompt.isNil:
            prompt.response = await wid.prompt prompt.text
            available = true
            if wsId == wid and ws.available:
              ws.send($ %*prompt)
        )()

      ws.onClose = proc (e: CloseEvent) =
        inc wsId
        clearInterval loopInterval
        ws = nil
        startWs()
    else:
      echo "Why open another WS?"

  startWs()

when isMainModule:
  discard main()
