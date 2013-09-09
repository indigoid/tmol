package Table::Result;

use base qw(Class::Accessor);
use strict;
use warnings;
use Dice;

Table::Result->follow_best_practice;
Table::Result->mk_accessors(qw(what value valuespec));

sub value {
	my $self = shift;
	if (!$self->get_value && $self->get_valuespec) {
		my $dice = Dice->new;
		$dice->parse($self->get_valuespec);
		$self->set_value($dice->roll);
	}
	return $self->get_value;
}

1;
