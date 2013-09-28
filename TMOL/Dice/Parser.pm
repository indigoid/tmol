package TMOL::Dice::Parser;

use strict;
use warnings;
use base 'Class::Accessor';
use Parse::RecDescent;
use TMOL::Dice::Spec;
use Carp;
TMOL::Dice::Parser->follow_best_practice;
TMOL::Dice::Parser->mk_accessors(qw/parser spec/);

sub grammar {
	return <<'END_GRAMMAR';
		<autotree>
		number		: /\d+/
		basic		: number 'd' number
				{ { ndice => $item[1], dicetype => $item[-1] }; }
		addsubtract	: /[+-]/ number
				{ { sign => $item[1], amount => $item[2] } } 
		multiply	: 'x' number
				{ { multiply => $item[-1] } }
		spec		: basic addsubtract(?) multiply(?)
		startrule	: spec
END_GRAMMAR
}

sub emit {
	my ($self, $spec) = @_;
	my $r = $self->get_parser->startrule($spec);
	unless ($r) {
		cluck("could not parse dice spec\n");
		return undef;
	};
	my $sf = { ndice => 1, type => 6, addsub => 0, multiply => 1 };
	$r = $r->{spec};
	$self->set_spec($r);
	$sf->{ndice} = $r->{basic}->{ndice}->{__VALUE__};
	$sf->{type} = $r->{basic}->{dicetype}->{__VALUE__};
	my $mul = $r->{'multiply(?)'};
	if (defined $mul && $mul->[0]) {
		$sf->{multiply} = $mul->[0]->{multiply}->{__VALUE__};
	}
	my $addsub = $r->{'addsubtract(?)'};
	if (defined $addsub && $addsub->[0]) {
		my $amount = $addsub->[0]->{amount}->{__VALUE__};
		my $sign = $addsub->[0]->{sign};
		$sf->{addsub} = $sign eq '-' ? -$amount : $amount;
	}
	$self->set_spec(TMOL::Dice::Spec->new($sf));
	return $self->get_spec;
}

sub generate {
	my ($class, $args) = @_;
	my $self = $class->new($args);
	$self->set_parser(Parse::RecDescent->new($self->grammar));
	return $self;
}

1;
