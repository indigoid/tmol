#!/usr/bin/perl

use strict;
use warnings;
use TMOL::Dice::Parser;

my $bag = TMOL::Dice::Parser->generate;

LINE: while (my $line = <>) {
	chomp $line;
	$line =~ s/^\s*//;
	$line =~ s/\s*$//;
	my $dice = $bag->emit($line) or next LINE;
	print "10 rolls: ", join(' ', map { $dice->roll } 1 .. 10), "\n";
}

print "\n";
