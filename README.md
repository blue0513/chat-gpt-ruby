# chat-gpt-ruby

[![CI](https://github.com/blue0513/chat-gpt-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/blue0513/chat-gpt-ruby/actions/workflows/ci.yml)

<img src="https://user-images.githubusercontent.com/8979468/228260595-3d887fbf-4c7d-4b66-b50c-fb94b6688c39.gif" width="600">

This program allows for quick communication with ChatGPT, a customizable chatbot.   
You can customize the `model_profile` and `history` for a personalized chat experience.   
The `model_profile` is the AI's defined personality, and the `history` is the previous conversation between the user and ChatGPT.

*Technically, the `model_profile` is a prompt with the `role` of `system`

## Preparation

To set up the program, you need to set the `OPENAI_ACCESS_TOKEN` environment variable.  
This can be done by editing the `.envrc` file or by typing `export OPENAI_ACCESS_TOKEN`.

## Quick Start

To start the program quickly, enter the following commands in the console:

```console
$ make install
$ make quick
```

Type your prompt, then hit `Ctrl+D` to send the prompt to ChatGPT.

### Shortcuts

There are several useful shortcuts you can execute:

- `dump`: Save the current conversation history to the file in `history/*.json`
- `undo`: Undo the previous step of the conversation
- `clear`: Erase all conversation history
- `quit`: End the conversation

## Advanced Usage

To access advanced options, run the following command:

```console
$ make run
```

Here, you can select your preferred `model_profile` and `history`.

### Define model profile

You can define the personality of your preferred AI (model profile):

```console
$ cp model_profiles/model.txt.example model_profiles/model.txt

# Edit the file as desired. This text will be used as the `role: system` message.
$ vi model_profiles/model.txt
```

You can add as many model profiles as you wish by adding `model_profiles/*.txt`.



### Define history

To customize the conversation history:

```console
$ cp history/history.json.example history/history.json

# Edit the file as desired. This JSON will be used as the conversation history.
$ vi history/history.json
```

You can add more histories by adding `history/*.json`.
