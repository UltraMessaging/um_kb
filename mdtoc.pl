#!/usr/bin/env perl
# mdtoc.pl
#
# This code and its documentation is Copyright 2023-2023 Steven Ford
# and licensed "public domain" style under Creative Commons "CC0":
#   http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/mdtoc

use strict;
use warnings;
use Getopt::Std;
use File::Basename;
use Carp;
use File::Copy 'copy';

# globals
my $tool = basename($0);

# process options.
use vars qw($opt_h $opt_b);
$opt_b = ".bak";  # default.

getopts('hb:') || mycroak("getopts failure");
my $backup_suffix = $opt_b;

if (defined($opt_h)) {
  help();
}

my $cmd_line = join(" ", $0, @ARGV);

my @pre_lines;
my @post_lines;
my @toc_lines;
my $state = "pre";
my $in_code = 0;
my %targets;

# Main loop; read each line in each file.
while (<>) {
  if ($in_code && /^\s*````/) {
    $in_code = 0;
  }
  elsif ((! $in_code) && /^\s*````/) {
    $in_code = 1;
  }

  if ($state eq "pre") {
    # Only process toc if outside code block.
    if (! $in_code) {
      get_toc_line($_);
    }
    push(@pre_lines, $_);
    if (/<!-- mdtoc-start -->/) {
      $state = "mid";
    }
  }
  elsif ($state eq "mid") {
    # Ignore existing TOC lines till get to end.
    if (/<!-- mdtoc-end -->/) {
      push(@post_lines, "<!-- TOC created by '$cmd_line' (see https://github.com/fordsfords/mdtoc) -->\n");
      push(@post_lines, $_);
      $state = "post";
    }
  }
  elsif ($state eq "post") {
    # Only process toc if outside code block.
    if (! $in_code) {
      get_toc_line($_);
    }
    push(@post_lines, $_);
  }
  else { mycroak("Invalid state '$state'"); }

} continue {
  if (eof) {  # This continue clause makes "$." give line number within file.
    my $filename = $ARGV;  # filename
    close ARGV;

    if ($state eq "pre") { mycroak("Could not find '<!-- mdtoc-start -->' in $filename"); }
    if ($state eq "mid") { mycroak("Could not find '<!-- mdtoc-end -->' in $filename"); }

    my $fh;
    # File name '-' means STDIN to STDOUT.
    if ($filename eq "-") {
      $fh = *STDOUT
    } else {
      if (length($backup_suffix) > 0) {
        copy($filename, "$filename$backup_suffix") or mycroak("failed copy '$filename' '$filename$backup_suffix'");
      }
      open($fh, ">", $filename) or mycroak("open for write: '$filename'");
    }

    print $fh @pre_lines;
    print $fh @toc_lines;
    print $fh @post_lines;

    if ($filename ne "-") {
      close($fh) or mycroak("close: '$filename'");
    }

    # Prepare for the next file (if any).
    $state = "pre";
    @pre_lines = ();
    @post_lines = ();
    @toc_lines = ();
    $in_code = 0;
  }
}

# All done.
exit(0);


# End of main program, start subroutines.


sub mk_id {
  my ($hdr_text) = @_;

  my $id = lc($hdr_text);
  $id =~ s/ /-/g;
  $id =~ s/[^a-z0-9_-]//g;

  return $id;
}  # mk_id


sub get_toc_line {
  my ($iline) = @_;

  if ($iline =~ /^(#+)\s*([^\s#].*)$/) {
    my ($hashes, $title) = ($1, $2);

    while ($title =~ s/\[([^]]+)\]\([^)]+\)/$1/) { }

    $hashes =~ s/^.//;    # get rid of one hash
    $hashes =~ s/#/&nbsp;&nbsp;&nbsp;&nbsp;/g;  # convert rest of hashes to four spaces.
    # The two trailing spaces force a linebreak. Gotta love md.
    my $title_id = mk_id($title);
    if (defined($targets{$title_id})) {
      if ($targets{$title_id} == 1) {
        print STDERR "Warning, title_id '$title_id' appears multiple times\n";
      }
      $targets{$title_id}++;
    } else {  # First time title_id appears.
      $targets{$title_id} = 1;
    }
    push (@toc_lines, "$hashes&bull; [$title](#" . mk_id($title) . ")  \n");
  }
}  # get_toc_line


sub mycroak {
  my ($msg) = @_;

  if (defined($ARGV)) {
    # Print input file name and line number.
    croak("Error (use -h for help): input_file:line=$ARGV:$., $msg");
  } else {
    croak("Error (use -h for help): $msg");
  }
}  # mycroak


sub assrt {
  my ($assertion, $msg) = @_;

  if (! ($assertion)) {
    if (defined($msg)) {
      mycroak("Assertion failed, $msg");
    } else {
      mycroak("Assertion failed");
    }
  }
}  # assrt


sub help {
  my($err_str) = @_;

  if (defined $err_str) {
    print "$tool: $err_str\n\n";
  }
  print <<__EOF__;
Usage: $tool [-h] [-b backup_suffix] [file ...]
    -h - help
    -b backup_suffix - File name suffix for backup file.
       Use '-b ""' for no backup. Defaults to '-b ".bak"'.
    file ... - one or more input files.  If omitted, inputs from stdin.

__EOF__

  exit(0);
}  # help
