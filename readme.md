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

The client userscript controls the ChatGPT webpage, it connects with backend,
the lib via Websocket and wait the prompts. Once that userscript receives, it
prompts to AI manipulating DOM and send to backend the answered MD.

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
