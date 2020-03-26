# grepfile
usage:
```
$ cat t.list
@ddd
>B1
A1

$ cat q.list
#xx
>A1
>ddd
A2
>B

$ ./grepfile t.list  q.list  # by default: --ignore-line-mathed-by  ^[#@] --delete-chars-from-column "^>"
A1


$ ldd grepfile
	not a dynamic executable
```


```
Contact: ilikeorangeapple@gmail.com or go to https://github.com/orangeSi/grepfile/issues
Usage:
  grepfile [flags...] <target> <query> [arg...]

A replace for grep -f(which cost too many memory)

Flags:
  --column-query (default: 1)
  --column-target (default: 1)
  --delete-chars-from-column (default: "^>")  # delete id first chars, support regex syntax
  --help                                      # Displays help for the current command.
  --ignore-line-mathed-by (default: "^[#@]")  # if id start with # or @, will remove # or @, support regex syntax
  --invert-match (default: 0)                 # Invert the sense of matching, to select non-matching lines
  --sep-query (default: "\t")                 # query separator, '\t' or '\s'
  --sep-target (default: "\t")                # target separator, '\t' or '\s'
  --version                                   # Displays the version of the current application.

Arguments:
  target (required)                           # target file
  query (required)                            # query file

```

