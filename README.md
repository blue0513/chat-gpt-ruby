# chat-gpt-ruby

[![CI](https://github.com/blue0513/chat-gpt-ruby/actions/workflows/ci.yml/badge.svg)](https://github.com/blue0513/chat-gpt-ruby/actions/workflows/ci.yml)

## Preparation

1. Set the `OPENAI_ACCESS_TOKEN` environment variable by editing `.envrc` or typing `export OPENAI_ACCESS_TOKEN`.
2. Customize `model profile` and `history` to your liking.

### Define model profile

You can define the personality of your preferred AI (model profile).

```console
$ cp model_profiles/model.txt.example model_profiles/model.txt
# Edit as desired. This text will be used as the `role: system` message.
$ vi model_profiles/model.txt
```

You can add as many model profiles as you wish by adding `model_profiles/*.txt`.

### Define history

```console
$ cp history/history.json.example history/history.json
# Edit as desired. This JSON will be used as the conversation history.
$ vi history/history.json
```

You can add more histories by adding `history/*.json`.

## Usage

Run the following commands:

```console
$ make install
$ make run

# Quick run
$ make quick
```

## Advanced

You can execute the following commands:

- `dump`: Save the current conversation history to the file in `history/*.json`
- `undo`: Undo the previous step of the conversation
- `clear`: Erase all conversation history
- `quit`: End the conversation
