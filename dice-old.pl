#!/usr/bin/perl

use strict;
use warnings;
use Dice;

while (my $line = <>) {
	chomp $line; $line =~ s/^\s*//; $line =~ s/\s*$//;
	my $dice = Dice->new;
	$dice->parse($line);
	print $dice->roll, "\n" for 1 .. 100;
}

print "\n";
