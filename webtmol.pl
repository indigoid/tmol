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
	my %outputs = $self->table_results($tablename);
	if (scalar keys %outputs < 1) {
		return join('', p('No results returned.'));
	}
	return join("\n",
		table(
			th([qw(Qty Value Description)]),
			map {
				Tr(
					td([
						$outputs{$_},
						split(m'//SPLITHERE//', $_)
					])
				)
			} keys %outputs
		),
		end_html
	);
}

sub index_response {
	opendir(my $dh, '.') or die("can't opendir: $!\n");
	return	ul(
			li([
				map { a({href=>"/t/$_"}, $_) }
				sort
				map { s/\.table$//; $_ }
				grep { /^[\w-]+\.table$/ && -f && -s && -r }
				readdir $dh
			])
		);
}

sub html_response {
	my $self = shift;
	my $headers = HTTP::Headers->new;
	my $response = HTTP::Response->new(RC_OK);
	my $title = "web tables: " . shift;
	my $preamble = join('',
		start_html({
			-style => { -code=>$self->stylesheet },
			-title => $title
		}),
		h1($title)
	);
	$response->header('Content-Type' => 'text/html');
	$response->content(join('', $preamble, @_), end_html);
	return $response;
}

sub read_file {
	my ($self, $filename) = @_;
	open(my $fh, '<', $filename) or return undef;
	local $/ = undef;
	return scalar <$fh>
}

sub stylesheet {
	return shift->read_file('style.css');
}

sub mainloop {
	my $self = shift;
	while (my $conn = $self->accept) {
		while (my $req = $conn->get_request) {
			if ($req->method eq 'GET') {
				if ($req->uri->path =~ m|/t/([\w-]+)|) {
					$conn->send_response($self->html_response(
						$1, map { (
							h2("result #$_:"),
							$self->table_response($1)
						) } 1 .. 10,
					));
					goto DONE;
				}
				if ($req->uri->path eq '/') {
					$conn->send_response($self->html_response(
						'index',
						$self->index_response('index')
					));
					goto DONE;
				}
				ERR: $conn->send_error(RC_FORBIDDEN);
				DONE:
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

GetOptions($CONFIG, qw(listenport=i listenaddr=s tablepath=s))
	or die "usage: $0 [OPTIONS]\n";

my $httpd = Table::HTTPD->new(
	LocalPort	=> $CONFIG->{listenport},
	LocalAddr	=> $CONFIG->{listenaddr},
	tablepath	=> $CONFIG->{tablepath}
) or die "can't start spawn Table::HTTPD\n";

printf "You can contact me at this URL:\n\nhttp://%s:%d/\n",
	$CONFIG->{listenaddr},
	$CONFIG->{listenport};

$httpd->mainloop;
