package TMOL::Result;

use base qw(Class::Accessor);
use strict;
use warnings;
use TMOL::Dice;

TMOL::Result->follow_best_practice;
TMOL::Result->mk_accessors(qw(what value valuespec));

sub value {
	my $self = shift;
	if (!$self->get_value && $self->get_valuespec) {
		my $dice = TMOL::Dice->new;
		$dice->parse($self->get_valuespec);
		$self->set_value($dice->roll);
	}
	return $self->get_value;
}

1;
