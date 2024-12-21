## Building the Asterisk Dashboard

```sh
mkdir asterisk
cd asterisk
jb init
jb install https://github.com/grafana/jsonnet-libs/asterisk-mixin
jsonnet --jpath=vendor asterisk-metrics.jsonnet > generated.json
```

Note:
jsonnet --jpath vendor asterisk-metrics.jsonnet > generated.json
Something went wrong during jsonnet_evaluate_snippet, please report this: [json.exception.parse_error.101] parse error at line 2, column 0: syntax error while parsing value - invalid string: control character U+000A (LF) must be escaped to \u000A or \n; last read: '"Asterisk instance restarted in the last minute<U+000A>'
zsh: abort (core dumped)  jsonnet --jpath vendor asterisk-metrics.jsonnet > generated.json

Needed to replace \n with 2x\n