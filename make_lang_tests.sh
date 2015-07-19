#!/bin/sh
whatIsMyName=${PWD}/$0
rm -rf ${PWD}/common_info.es.tmp
if [ ! -f ${PWD}/list_lang.txt ]; then
	echo "you need a file named list_lang.txt to use this script."
	echo "the file should have only one lang code per line and look like:"
	echo "en-us"
	echo "es-us"
	echo "en-in"
else
	echo "var i = 0;" > common_info.es.tmp
	echo "var docs = new Array();" >> common_info.es.tmp
	
	for lang in `cat list_lang.txt`
	do
		fileName="choose_lang_set_$lang.vxml"
		if [ ! -f ${PWD}/$fileName ];
		then
			echo "creating $fileName ..."
			cat choose_lang_set_en-us.vxml | sed -e s/en\-US/$lang/ -e s/\ E/\ ${lang:0:1}/ -e s/\ N/\ ${lang:1:1}/ -e s/\ U/\ ${lang:3:1}/ -e s/\ S/\ ${lang:4:1}/ > ${PWD}/$fileName
		echo "docs[i] = '$fileName'; i++;" >> common_info.es.tmp	
		else
			echo "docs[i] = '$fileName'; i++;" >> common_info.es.tmp
		fi
	done
	echo 'var N= i;' >> common_info.es.tmp
	echo 'function nextDoc(i) {' >> common_info.es.tmp
	echo '	var ii = i * 1;' >> common_info.es.tmp
	echo '	var j = ii % N;' >> common_info.es.tmp
	echo '	return docs[j];' >> common_info.es.tmp
	echo '};' >> common_info.es.tmp
	echo 'function removeSpaces(string) {' >> common_info.es.tmp
	echo ' return string.split(' ').join('');' >> common_info.es.tmp
	echo '}' >> common_info.es.tmp
	echo "all done.  would you like to review common_info.es before you commit?"
	case "$commitResponse" in
		'y')
		cat common_info.es.tmp
		echo "does that okay?"
		case "$do_over" in
			'y')
			mv common_info.es.tmp common_info.es
			;;
			'n')
			exit
			;;
		esac
		;;
		'n')
		mv common_info.es.tmp common_info.es
		;;
	esac

fi 
