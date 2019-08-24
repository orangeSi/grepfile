# grepfile
```
Usage:
  /home/sikaiwei/crystal/grepfile/grepfile [flags...] <target> <query> [arg...]

A replace for grep -f(which cost too many memory)

Flags:
  --delete-header (default: "")             # delete id first chars
  --help                                    # Displays help for the current command.
  --ignore-line-start-with (default: "#@")
  --prefix (default: "grepfile.out")        # prefix of output
  --query-column (default: 1)
  --sep-query (default: "\t")               # query separator, '\t' or '\s'
  --sep-target (default: "\t")              # target separator, '\t' or '\s'
  --target-column (default: 1)
  --version                                 # Displays the version of the current application.

Arguments:
  target (required)                         # target file
  query (required)                          # query file
  ```
