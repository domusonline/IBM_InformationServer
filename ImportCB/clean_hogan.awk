function cleanup_fields()
{
	r=gensub(/(^.......){0,1}( *)([0-9][0-9]*)(  *)(..*)/,"\\1\\2\\3\\4", "g",$0)
	s=gensub(/(^.......){0,1}( *)([0-9][0-9]*)(  *)(..*)/,"\\5", "g",$0)
	gsub(/:-/,"-",s);
	gsub(/^ *:/,"",s);
	gsub(/ :/," ",s);
	gsub(/:/,"-",s);
	print r s
}
BEGIN {
	IGNORECASE=1
	VALID_FIEDLS=0
}

/(^.......){0,1} *[0-9][0-9]*  *[A-Za-z0-9;:,-][A-Za-z0-9;:,-]*  *PIC/ {
	if ( VALID_FIELDS == 0)
	{
		if ( $0 ~ /(ACTION|RESULT).*  *PIC  *X(X|\(2\)|\(02\))/ )
		{
			next
		}
		else
		{
			VALID_FIELDS=1
			cleanup_fields()
			next
		}
	}
	else
	{
		cleanup_fields()
		next
	}
}

/(^.......){0,1} *[0-9][0-9]*  *[A-Za-z0-9;:,-][A-Za-z0-9;:,-]*/ {
	cleanup_fields()
	next
}

{
	print $0
}

END {
	print
}
