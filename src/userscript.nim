when not defined js:
  {.fatal: "JS only module".}
when not isMainModule:
  {.fatal: "This userscript cannot be imported".}

import std/asyncjs
import std/sugar
import std/jsconsole

from std/dom import document, Interval, click, setInterval, clearInterval,
                    Element, querySelectorAll, Interval, clearInterval
from std/json import parseJson, to, `$`, `%*`, `%`

import pkg/jswebsockets

import dirtyGpt/jsutils
import dirtyGpt/turndown
import dirtyGpt/common

proc getPromptResponse: string =
  let responses = document.querySelectorAll ".markdown"
  result = turndown responses[^1].innerHtml

proc main {.async.} =
  let
    promptField = await document.waitEl "#prompt-textarea"
    promptButton = await document.waitEl "#prompt-textarea + button"

  proc clickButton(button: Element) {.async.} =
    var
      interval: Interval
      delay = 500

    await newPromise() do (resolve: () -> void):
      interval = setInterval(proc() =
        if not promptButton.disabled:
          click button
          clearInterval interval
          resolve()
      , delay)


  proc prompt(text: cstring): Future[string] {.async.} =
    var
      interval: Interval
      limit = 500
      delay = 500

    promptField.setInputValue text
    await clickButton promptButton
    await sleep 500

    return newPromise[string]() do (resolve: (string) -> void):
      interval = setInterval(proc() =
        if limit == 0:
          clearInterval interval
          resolve ""
        else:
          if promptButton.innerText.len == 0:
            clearInterval interval
            resolve getPromptResponse()
        dec limit
      , delay)

  proc startWs =
    var
      ws = newWebSocket("ws://localhost:" & $dirtyGptPort)
      available = true
      loopInterval: Interval

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
      discard (proc {.async.} =
        var prompt = parseJson($e.data).to DirtyGptPrompt
        if not prompt.isNil:
          prompt.response = await prompt prompt.text
          available = true
          ws.send($ %*prompt)
      )()
    ws.onClose = proc (e: CloseEvent) =
      echo "closed"
      clearInterval loopInterval
      startWs()
  startWs()
when isMainModule:
  discard main()
