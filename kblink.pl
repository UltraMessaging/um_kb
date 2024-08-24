#!/usr/bin/env perl
# kblink.pl
#
# This code and its documentation is Copyright 2024 Steven Ford
# and licensed "public domain" style under Creative Commons "CC0":
#   http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/kb_kbthingie

use strict;
use warnings;
use Getopt::Std;
use File::Basename;
use Carp;

my $in_code = 0;

while (<>) {
  chomp;  # remove trailing \n

  if ($in_code && /^\s*````/) {
    $in_code = 0;
  }
  elsif ((! $in_code) && /^\s*````/) {
    $in_code = 1;
  }

  if (! $in_code) {
    if (/^#+\s*([^#\s].*\S)\s*$/) {
      my $title = $1;
      my $id = title2id($title);
      print "<a id=\"$id\"></a>\n";
    }
    else {
      # Convert each '[[title]]' to '[title](url)'.
      while (s/\[\[([^]]+)\]\]/kblink($1)/e) { }
    }
  }

  print "$_\n";
} continue {  # This continue clause makes "$." give line number within file.
  close ARGV if eof;
}

exit 0;

# End of main program, start subroutines.


sub title2id {
  my ($hdr_text) = @_;

  my $id = lc($hdr_text);
  $id =~ s/ /-/g;
  $id =~ s/[^a-z0-9_-]//g;

  return $id;
}  # title2id


sub kblink {
  my ($hdr_text) = @_;

  my $id = lc($hdr_text);
  $id =~ s/ /-/g;
  $id =~ s/[^a-z0-9_-]//g;

  return "[$hdr_text]($id.html)";
}  # kblink
