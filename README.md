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

$ ./grepfile t.list  q.list
--ignore-line-mathed-by  ^[#@]
--delete-chars-from-column ^>
start read query
start read target
start get query uniq
start get target uniq
db	core_number	uniq_number	core_number_percent	uniq_number_percent	total_number
t.list	1	1	0.5	0.5	2
q.list	1	3	0.25	0.75	4

$ ls myth*
myth.coreid.list  myth.diff.stat.txt  myth.q.column1.uniqid.list  myth.t.column1.uniqid.list

$ cat myth.diff.stat.txt
db	core_number	uniq_number	core_number_percent	uniq_number_percent	total_number
t.list	1	1	0.5	0.5	2
q.list	1	3	0.25	0.75	4

$ cat myth.coreid.list
A1

$ ldd grepfile
	statically linked
```

```
Usage:
/home/sikaiwei/crystal/grepfile/grepfile [flags...] <target> <query> [arg...]

A replace for grep -f(which cost too many memory)

	Flags:
	--column-query (default: 1)
	--column-target (default: 1)
	--delete-chars-from-column (default: "^>")  # delete id first chars, support regex syntax
	--help                                      # Displays help for the current command.
	--ignore-line-mathed-by (default: "^[#@]")  # if id start with # or @, will remove # or @, support regex syntax
	--prefix (default: "myth")                  # prefix of output
	--sep-query (default: "\t")                 # query separator, '\t' or '\s'
	--sep-target (default: "\t")                # target separator, '\t' or '\s'
	--version                                   # Displays the version of the current application.

	Arguments:
	target (required)                           # target file
	query (required)                            # query file

```

