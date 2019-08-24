#/bin/sh
if [ "$2" == "" ];
then
	echo "sh <crystal binary path> <prefix of outname>"
	exit
fi

base=`dirname $(readlink -f $0)`
path=`readlink -f $1`
out=$2


bits=`file /bin/ls|awk  -F ',' '{print $2}'|sed 's/\s*//'`
out="$out.wrap.$bits"

if [ -f "$out" ];
then
	echo "$out exists, should delete it or give a new name"
	exit
fi

bn=`basename $path`

echo "
#/bin/sh
source $base/env.sh
base=\`dirname \$(readlink -f \$0)\`
bin_name=$bn
binary=$path

if [ ! -f \"\$binary\" ]
then

	if [ ! -f \"\$base/\$bin_name\" ];
	then
		echo \"error, \$binary or \$base/\$bin_name both not exists\"
		exit
	else
		binary=\$base/\$bin_name
	fi
fi


if [ \"\$1\" == \"\" ];
then
	\$binary --help
	exit
fi
time \$binary \$@ &&
echo done
" >$out
chmod 755 $out
echo get $out 
