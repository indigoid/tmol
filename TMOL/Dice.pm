package TMOL::Dice;

use base qw(Class::Accessor);
use Carp;
use strict;
use warnings;

TMOL::Dice->follow_best_practice;
TMOL::Dice->mk_accessors(qw(ndice dietype modifier multiplier));

sub parse {
	my ($self, $spec) = @_;
	if ($spec =~ s/^\s*(\d+)d(\d+)//i) {
		$self->set_ndice($1);
		$self->set_dietype($2);
		$self->set_modifier(0);
		$self->set_multiplier(1);
		if ($spec =~ s/^([+-]\d+)//) {
			$self->set_modifier($1);
		}
		if ($spec =~ s/^x(\d+)//) {
			$self->set_multiplier($1);
		}
	} else {
		croak("invalid dice specification\n");
	}
}

sub roll {
	my $self = shift;
	my $total = 0;
	$total += 1+ int(rand($self->get_dietype)) for 1 .. $self->get_ndice;
	$total += $self->get_modifier;
	$total *= $self->get_multiplier;
}

1;
