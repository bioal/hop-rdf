#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM
";

my %OPT;
getopts('', \%OPT);

!@ARGV && -t and die $USAGE;
while (<>) {
    chomp;
    s/\r$//;
    if (/^No/) {
	next;
    }

    my @f = split("\t", $_);

    my $group_no = $f[0];

    my $time = "";
    if (defined $f[4]) {
	$time = $f[4];
    }

    print $group_no, "\t", $time, "\n";
}
