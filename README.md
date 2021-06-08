# grepfile
a alternative for $grep -f A.list B.list which cost too many memory and time
### usage:
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

$ ./grepfile t.list  q.list 
A1

$cat t.list|./grepfile - q.list 
A1

$cat q.list|./grepfile t.list -
A1

$./grepfile t.list  q.list --exact-match 0
>B1
A1

$ ldd grepfile
	not a dynamic executable
```

### Install:
```
directyly use grepfile binary executable file in Linux or complie grepfile.cr with crystal lang(v1.0.0)
```

### document
```
Contact: https://github.com/orangeSi/grepfile/issues
Usage:
  ./grepfile [flags...] <target> <query> [arg...]

A replace for $ grep -f (which cost too many memory and time) in Linux

Flags:
  --column-query (default: 1)                 # choose which column to compare
  --column-target (default: 1)                # choose which column to compare
  --delete-chars-from-column (default: "^>")  # delete > from content of column, support regex syntax
  --exact-match (default: 1)                  # if >=1, mean equal totally else mean macth
  --help                                      # Displays help for the current command.
  --ignore-line-mathed-by (default: "^[#@]")  # if content of column start with # or @, will skip this line, support regex syntax
  --invert-match (default: 0)                 # if >=1, mean invert the sense of matching, to select non-matching lines
  --sep-query (default: "\t")                 # query separator, '\t' or '\s' or other string
  --sep-target (default: "\t")                # target separator, '\t' or '\s' or other string
  --version                                   # Displays the version of the current application.

Arguments:
  target (required)                           # target file, support flat or .gz file or stdin(by -)
  query (required)                            # query file,  support flat or .gz file or stdin(by -)

```

