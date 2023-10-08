when not defined js:
  {.fatal: "JS only module".}

import std/asyncjs
from std/dom import setInterval, clearInterval, dispatchEvent, KeyboardEvent,
                    Element
import std/dom
from std/jsffi import JsObject, isNull
from std/json import `$`, `%*`, `%`, JsonNode
from std/sugar import `->`, `=>`

proc newPromise*[T](handler: proc(resolve, reject: proc(response: T))): Future[T] {.importjs: "(new Promise(#))".}

proc waitEl*(
  baseEl: Element or Document,
  selector: string,
  limit = 30,
  check: (el: Element) -> bool = (el: Element) => not el.isNull,
  checkInterval = 1000
): Future[Element] {.async.} =
  ## Waits for an element that matches the given selector to appear within the base element.
  ##
  ## This procedure returns a Future that resolves with the found element or rejects if the element
  ## is not found within the specified limit and conditions.
  ##
  ## - `baseEl`: The base element within which to search for the target element.
  ## - `selector`: The CSS selector used to identify the target element.
  ## - `limit`: The maximum number of attempts to find the element (default is 30).
  ## - `check`: A procedure that takes an Element and returns true if it meets the desired condition.
  ##   The default condition checks if the element is not null.
  ## - `checkInterval`: The interval in milliseconds between attempts (default is 1000ms).
  ##
  ## Translated by ChatGPT from https://git.ozzuu.com/thisago/wppGroupMembers/src/commit/e902dfe5268119f8ded6597f53dd388b0f175135/src/main.user.js#L191
  var
    interval: Interval
    limit = limit

  newPromise[Element]() do (resolve, reject: (Element) -> void):
    interval = setInterval(proc() =
      if limit == 0:
        clearInterval interval
        reject nil # Or handle the case when limit is reached
      else:
        let el = baseEl.querySelector cstring selector
        if check el:
          clearInterval interval
          resolve el # Or handle the case when element is found
        else:
          dec limit
    , checkInterval)

proc sleep*(ms: int): Future[void] =
  newPromise() do (resolve: () -> void):
    discard setTimeout(resolve, ms)

proc jsonToJsObj(json: cstring): JsObject {.importjs: "JSON.parse(@)".}
  ## Converts a JSON-formatted string to a JavaScript object.
  ##
  ## This procedure takes a JSON string as input and returns a JavaScript object
  ## representation. The returned object can be used in JavaScript code.
  ##
  ## - `json`: The JSON-formatted string to convert.
  ##
  ## Example usage:
  ##
  ## ```nim
  ## let jsonString = "{\"key\": \"value\"}"
  ## let jsObj = jsonToJsObj(jsonString)
  ## ```
  ## 
  ## Doc generated by by ChatGPT


proc newKeyboardEvent(kind: cstring; config: JsObject): KeyboardEvent {.importjs: "(new KeyboardEvent(@))".}
  ## Creates a new KeyboardEvent object.
  ##
  ## - `kind`: The kind of keyboard event, e.g., "keydown", "keyup", etc.
  ## - `config`: A JsObject containing the event configuration.
  
proc setInputValue*(input: Element; value: cstring) =
  ## Sets the value of an input element and triggers an "input" event.
  ##
  ## This procedure sets the `value` property of the input element to the specified `value`,
  ## and then it dispatches a new "input" event on the element to indicate that its value has changed.
  ##
  ## - `input`: The input element to update.
  ## - `value`: The new value to set for the input element.
  ##
  ## Example usage:
  ##
  ## ```nim
  ## let inputElement = document.getElementById("myInput")
  ## setInputValue(inputElement, "new value")
  ## ```
  ##
  ## Doc generated by by ChatGPT
  focus input
  input.value = value
  input.dispatchEvent newKeyboardEvent("input", jsonToJsObj """{"bubbles": true}""")
  blur input