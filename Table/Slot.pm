package Table::Slot;

use base qw(Class::Accessor);
use strict;
use warnings;
use Dice;
use Table::Result;
use Carp;
use Data::Dumper;

Table::Slot->follow_best_practice;
Table::Slot->mk_accessors(
	qw(what),	# what this slot actually yields
	qw(valuespec),	# dice-spec indicator of value
	qw(low high),	# slot boundaries in the table
	qw(percent),	# chance of this slot emitting a result
	qw(dice),	# how many instances, if random? (dice spec eg. 1d4+1)
	qw(quantity),	# how many instances, if fixed?
	qw(subtable),	# name of subtable to query instead of 'what'
	qw(append),	# another subtable to query for additional properties
	qw(multimode),	# if 'group', each item emitted once
			# if 'multi', each item emitted separately each time,
			# ie. multi with a subtable may generate non-matching
			# items
);

sub _determine_quantity {
	my $self = shift;
	if ($self->get_quantity) {
		return $self->get_quantity;
	}
	if ($self->get_dice) {
		my $dice = Dice->new;
		$dice->parse($self->get_dice);
		return $dice->roll;
	}
	return 1;
}

sub _determine_percent {
	my $self = shift;
	# unset => always succeed
	return 1 unless $self->get_percent;
	if (int(rand(100)) < $self->get_percent || ! $self->get_percent) {
		return 1;
	}
	return undef;
}

sub _get_one {
	my $self = shift;
	if ($self->get_subtable) {
		return grep { $_ ne '-' } $self->get_subtable->random;
	} else {
		return map {
			my $appendages = '';
			if ($self->get_append) {
				$appendages =
					' ('
					. join(', ',
						map { $_->get_what }
							$self->get_append->random) 
					. ')';
			}
			Table::Result->new({
				what		=> $self->get_what . $appendages,
				valuespec	=> $self->get_valuespec
			})
		} grep { $_ ne '-' } $self->get_what;
	}
}

sub action {
	my $self = shift;
	return undef unless $self->_determine_percent;
	my @result;
	my $qty = $self->_determine_quantity;
	if ($self->get_multimode && $self->get_multimode eq 'oneofeach') {
		croak "oneofeach flag requires a subtable!\n"
			unless $self->get_subtable->isa('Table');
		push @result, $self->get_subtable->one_of_each for (1 .. $qty);
	} else {
		@result = ( $self->_get_one );
		if ($qty > 1) {
			for (2 .. $qty) {
				if ($self->get_multimode eq 'group') {
					push @result, $result[0];
				} elsif ($self->get_multimode eq 'multi') {
					push @result, $self->_get_one;
				}
			}
		}
	}
	return @result;
}

1;
