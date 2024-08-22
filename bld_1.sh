#!/bin/sh
# bld_1.sh

FILE="$1"
F=`basename "$FILE" .md`

if [ ! -r "$FILE" ]; then echo "Error bld_1.sh: cannot read file '$FILE'" >&2; exit 1; fi

TITLE=`./title2f.pl $FILE`;  if [ "$?" -ne 0 ]; then exit 1; fi

if egrep "<!-- mdtoc-start -->" $FILE >/dev/null; then :
  # Update doc table of contents (see https://github.com/fordsfords/mdtoc).
  ./mdtoc.pl -b "" $FILE;
fi

cat >"html/$F.html" <<__HEADER__
<html><head><title>$TITLE</title>
<link href="../doxygen_manual.css" rel="stylesheet" type="text/css" />
</head>
<body bgcolor="#ffffff">
<div id="doc-content">
<div class="contents">
<div class="textblock">
<a href="https://informatica.com"><img src="../infa_logo.png" width="200" height="69" alt="Informatica"/></a>
<br/>
<p><b>Ultra Messaging Knowledge Base</b></p>
<hr>
__HEADER__

./kblink.pl <"$FILE" | ./pmarkdown -m github >>"html/$F.html"

cat >>"html/$F.html" <<__FOOTER__
<hr>
<p>KB <a href="home.html">Home</a> | <a href="index.html">Index</a></p>
<p>UM <a href="https://ultramessaging.github.io/">Home</a></p>
<p>See <a href="https://ultramessaging.github.io/#notices">Notices</a> for important information.
</div></div></div>
</body></html>
__FOOTER__
