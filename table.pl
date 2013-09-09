#!/usr/bin/perl

use strict;
use warnings;
use Table;
use Getopt::Long;
use File::Find;
use File::Spec::Functions qw(abs2rel);
use Data::Dumper;

my $CONFIG = {
	tablepath	=> "$ENV{HOME}/Code/tables/data",
	count		=> 1000,
};

GetOptions($CONFIG, qw(tablepath=s count=i list))
	or die "usage: $0 [--tablepath=/tables/directory] [--count=N] [--list] table_name\n";

chdir $CONFIG->{tablepath}
	or die "can't chdir to data directory" . $CONFIG->{tablepath} . ": $!\n";

if ($CONFIG->{list}) {
	my @tables;
	finddepth {
		no_chdir => 1,
		wanted => sub {
			my $x = $File::Find::name;
			if (-f $x && $x =~ /\.table$/) {
				push @tables, abs2rel($File::Find::name);
			}
		}
	}, '.';
	print join("\n", sort @tables), "\n";
	exit 0;
}

my $file = shift(@ARGV) || "mundane.table";
my $table = Table->new({tablepath => $CONFIG->{tablepath}});
$table->add_from_file($file);

sub format_value {
	my $x = shift;
	if (my $v = $x->value) {
		return sprintf("%dgp", $v);
	}
	return "";
}

my @things = map { $table->random } 1 .. $CONFIG->{count};
my %things;
map { $things{$_}++ } map { format_value($_) . " " . $_->get_what; } sort { $a->get_what cmp $b->get_what } @things;
print join("\n", map { "$things{$_}x $_" } sort keys %things), "\n";
