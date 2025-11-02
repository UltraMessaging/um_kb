#!/usr/bin/env perl
# title2f.pl

# This work is dedicated to the public domain under CC0 1.0 Universal:
# http://creativecommons.org/publicdomain/zero/1.0/
# 
# To the extent possible under law, Steven Ford has waived all copyright
# and related or neighboring rights to this work. In other words, you can 
# use this code for any purpose without any restrictions.
# This work is published from: United States.
# Project home: https://github.com/fordsfords/kb_thingie

use strict;
use warnings;
use Getopt::Std;
use File::Basename;
use Carp;

my $in_code = 0;

# Main loop; read each line in each file.
while (<>) {
  chomp;

  if ($in_code && /^\s*````/) {
    $in_code = 0;
  }
  elsif ((! $in_code) && /^\s*````/) {
    $in_code = 1;
  }

  if (! $in_code) {
    if (/^# (.*\S)\s*$/) {
      my $title_tag = mk_id($1);
      my $my_root = basename($ARGV, ".md");
      if ($my_root ne $title_tag) { die "file root '$my_root' not match title tag '$title_tag' in $ARGV:$."; }
      print "$1\n";
      exit(0);
    }
  }
}

# All done.
die "No title found\n";


# End of main program, start subroutines.


sub mk_id {
  my ($hdr_text) = @_;

  my $id = lc($hdr_text);
  $id =~ s/ /-/g;
  $id =~ s/[^a-z0-9_-]//g;

  return $id;
}  # mk_id
