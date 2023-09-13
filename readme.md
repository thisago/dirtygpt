<div align=center>

<img alt="Google Bard Logo" src="https://user-images.githubusercontent.com/74574275/262172715-048dadaa-3bb1-4f3f-ab5f-561c10830f32.png">

# DirtyGPT

#### A dirty and free way to use ChatGPT in Nim

**[About](#about) - [How it works?](#how-it-works) - [Installation](#installation) - [Usage](#usage)** - [License](#license)

</div>

## About

Prompt in ChatGPT web using Nim!

See this lib working at [cligpt](https://github.com/thisago/cligpt)

## How it works?

When you create a new instance of `DirtyGPT`, a async http web server will start
in asynchronous, it accept multiple websocket connections and when you query the
prompt in lib, the server will add your prompt to the queue, and the connected
userscripts will request a prompt. When the server sends the prompt to a client
(userscript), it saves the client ID in prompt and if for some reason the client
disconnects, the items bound to that client ID will be cleaned and wait to be
asked, in higher priority than others.

The client userscript controls the ChatGPT webpage, when it receives the prompt,
it fills up the input and clicks in the button to send. When AI is answering, the
button changes, when it returns to their original form, the userscript reads the
output HTML, converts it to Markdown and sends back to server (lib). Then it's
available to another prompt, the loop will request the next one.

## Installation

Install the lib with Nimble:

```bash
nimble install dirtygpt
```

And at installation end you'll see something like this:

```text
[...]

Please, don't forget to install the client userscript in your browser: ~/.nimble/pkgs2/dirtygpt-version-hash/userscript.user.js
```

Install the provided Javascript userscript path in a userscript manager in your
browser, like [Violentmonkey][violentmonkey].

## Usage

After installed the library and userscript, make sure that you have an open tab
with [ChatGPT][chatgpt] logged in.

The usage is simple:

[`prompt.nim`](examples/prompt.nim)

```nim
import std/asyncdispatch
import pkg/dirtygpt

let gpt = newDirtyGpt()

echo waitFor gpt.prompt "Hello, are you Google Bard?"

stop gpt
```

stdout

```text
No, I'm not Google Bard. I'm ChatGPT, an AI language model created by OpenAI. While both Google Bard and I are AI language models designed to generate text-based responses, we come from different organizations and have different underlying technologies. How can I assist you today?
```

## TODO

- [x] Add pinging because `connectedClients` is just updated when exceeds timeout

## License

This piece of software is libre, licensed over the MIT license. Feel free to use!

<!-- Refs -->

[violentmonkey]: https://violentmonkey.github.io
[chatgpt]: https://chat.openai.com
