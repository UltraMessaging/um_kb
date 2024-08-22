#!/bin/sh
# bld.sh - construct table of contents for each page

for F in *.md; do :
  if egrep "<!-- mdtoc-start -->" $F >/dev/null; then :
    # Update doc table of contents (see https://github.com/fordsfords/mdtoc).
    ./mdtoc.pl -b "" $F;
  fi
done

rm -rf html
mkdir html

echo "# Index" >x.md

for F in kb/*; do :
  if [ "${F##*.}" = "md" ]; then :
    ./bld_1.sh $F
    echo "* [[`./title2f.pl $F`]]" >>x.md
  else :
    cp $F html/
  fi
done


# Make index page
mv x.md index.md
./bld_1.sh index.md
rm index.md
