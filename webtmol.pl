#!/usr/bin/perl
package main;

use strict;
use warnings;
use TMOL::HTTPD;
use TMOL::Platform;
use Getopt::Long;

my $CONFIG = {
	listenport	=> 8000,
	listenaddr	=> '127.0.0.1',
	tablepath	=> TMOL::Platform::tablepath
};

GetOptions($CONFIG, qw(listenport=i listenaddr=s tablepath=s))
	or die "usage: $0 [OPTIONS]\n";

my $httpd = TMOL::HTTPD->new(
	LocalPort	=> $CONFIG->{listenport},
	LocalAddr	=> $CONFIG->{listenaddr},
	tablepath	=> $CONFIG->{tablepath}
) or die "can't start spawn Table::HTTPD\n";

printf "You can contact me at this URL:\n\nhttp://%s:%d/\n",
	$CONFIG->{listenaddr},
	$CONFIG->{listenport};

$httpd->mainloop;
