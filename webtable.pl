#!/usr/bin/perl

package Table::HTTPD;

use strict;
use warnings;
use base 'HTTP::Daemon';
use HTTP::Status;
use Carp;
use CGI::Pretty qw(:standard);
use Table;
use Cwd;
use Data::Dumper;

sub new {
	my ($class, %opts) = @_;
	if ($opts{tablepath}) {
		chdir $opts{tablepath}
			or croak "can't chdir $opts{tablepath}: $!\n";
	}
	print "cwd = " . getcwd . "\n";
	my $self = $class->SUPER::new(%opts);
}

sub format_one_thing {
	my ($self, $x) = @_;
	return ($x->value ? $x->value : '-') . '//SPLITHERE//' . $x->get_what;
}

sub table_results {
	my ($self, $tablename) = @_;
	my $table = Table->new({tablepath => '.'});
	$table->add_from_file($tablename . ".table");
	my %outputs;
	map { $outputs{$_}++ }
		map { $self->format_one_thing($_) }
		grep { defined } $table->random;
	return %outputs;
}

sub table_response {
	my ($self, $tablename) = @_;
	my $title = "webtable: $tablename";
	my $preamble = join('', start_html($title), h1($title));
	my %outputs = $self->table_results($tablename);
	if (scalar keys %outputs < 1) {
		return join('', $preamble,p('No results returned.'),end_html);
	}
	return join("\n",
		$preamble,
		table(
			th({-align=>'left'}, [qw(Qty Value Description)]),
			map {
				Tr(
					td({-align=>'left'}, [
						$outputs{$_},
						split(m'//SPLITHERE//', $_)
					])
				)
			} keys %outputs
		),
		end_html
	);
}

sub html_response {
	my $self = shift;
	my $headers = HTTP::Headers->new;
	my $response = HTTP::Response->new(RC_OK);
	$response->header('Content-Type' => 'text/html');
	$response->content(join('', @_));
	return $response;
}

sub mainloop {
	my $self = shift;
	while (my $conn = $self->accept) {
		while (my $req = $conn->get_request) {
			if ($req->method eq 'GET'
				&& $req->uri->path =~ m|/t/([\w-]+)|) {
				$conn->send_response(
					$self->html_response(
						$self->table_response($1)
					)
				);
			} else {
				$conn->send_error(RC_FORBIDDEN);
			}
		}
		undef $conn;
	}
}

1;

package main;

use strict;
use warnings;
use Getopt::Long;

my $CONFIG = {
	listenport	=> 8000,
	listenaddr	=> 'localhost',
	tablepath	=> "$ENV{HOME}/Code/tables/data"
};

my $httpd = Table::HTTPD->new(
	LocalPort	=> $CONFIG->{listenport},
	LocalAddr	=> $CONFIG->{listenaddr},
	tablepath	=> $CONFIG->{tablepath}
) or die "can't start spawn Table::HTTPD\n";

printf "You can contact me at this URL:\n\nhttp://%s:%d/\n",
	$CONFIG->{listenaddr},
	$CONFIG->{listenport};

$httpd->mainloop;
