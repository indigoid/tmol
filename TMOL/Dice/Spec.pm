package TMOL::Dice::Spec;

use strict;
use warnings;
use base 'Class::Accessor';
use Parse::RecDescent;
use Data::Dumper;
TMOL::Dice::Spec->follow_best_practice;
TMOL::Dice::Spec->mk_accessors(qw/ndice type addsub multiply/);

sub roll {
	my $self = shift;
	my $total = $self->get_addsub;
	$total += (int rand $self->get_type) + 1 for (1 .. $self->get_ndice);
	$total *= $self->get_multiply;
	return $total;
}

1;
