package TMOL::Table;

use base qw(Class::Accessor);
use strict;
use warnings;

TMOL::Table->follow_best_practice;
TMOL::Table->mk_accessors(qw(tablepath slots high low));

use Scalar::Util qw(blessed);
use Carp qw(cluck croak);
use TMOL::Slot;
use File::Spec::Functions qw(catfile);
use Data::Dumper;

sub random {
	my $self = shift;
	my $range = 1 + ($self->get_high - $self->get_low);
	my $result = $self->{_cache}->{int(rand($range)) + $self->get_low};
	return $result->action;
}

sub one_of_each {
	my $self = shift;
	my @results;
	for my $slot (@{$self->get_slots}) {
		push @results, $slot->action;
	}
	return @results;
}

sub add {
	my $self = shift;
	for my $new (@_) {
		if (ref($new) && $new->isa('TMOL::Slot')) {
			push @{$self->{slots}}, $new;
			for my $cacheslot ($new->get_low .. $new->get_high) {
				$self->{_cache}->{$cacheslot} = $new;
			}
			if (!defined($self->get_high) || $self->get_high < $new->get_high) {
				$self->set_high($new->get_high);
			}
			if (!defined($self->get_low) || $self->get_low > $new->get_low) {
				$self->set_low($new->get_low);
			}
		} else {
			croak "TMOL::Table::add expects TMOL::Slot refs only";
		}
	}
}

sub decode_table_entry {
	my ($self, $line) = @_;
	# split input into the major parts - low, high and specification
	my ($low, $high, $what);
	if ($line =~ /^(\d+)\s+(\S+.*)/) {
		($low, $high, $what) = ($1, $1, $2);
	} elsif ($line =~ /^(\d+)-(\d+)\s+(\S+.*)/) {
		($low, $high, $what) = ($1, $2, $3);
	} else {
		cluck("[$.:WARN] skipping malformed input\n");
		next LINE;
	}

	# what kind of dumbass even does this?
	if ($low > $high) {
		cluck("[$.:WARN] low is higher than high, swapping\n");
		my $t = $high;
		$high = $low;
		$low = $t;
	}

	# decode percent spec
	my $percent = undef;
	if ($what =~ s/^(\d+)%\s*//) {
		$percent = $1;
	}

	# decode value spec
	my $vdice = undef;
	if ($what =~ s/^value\s+(\d+d\d+([+-]\d+)?(x\d+)?)\s*//i) {
		$vdice = $1;
	}

	# decode multi/group dice spec
	my ($dice, $multimode) = (undef,undef);
	if ($what =~ s/^(oneofeach|group|multi)\s+(\d+d\d+([+-]\d+)?(x\d+)?)\s*//i) {
		($multimode, $dice) = ($1, $2);
	}

	# decode append-table spec
	my $append = undef;
	if ($what =~ s/^append\s+@([\w-]+.table)\s*//i) {
		$append = TMOL::Table->new({tablepath => $self->get_tablepath});
		$append->add_from_file($1);
	}

	# decode subtable spec and load up the subtable
	# happens again every time the table is loaded
	# blehhh RAM cheap programmer lazy
	my $subtable = undef;
	if ($what =~ s/^@(.+)//) {
		$subtable = TMOL::Table->new({
			tablepath => $self->get_tablepath,
			append => $append
		});
		$subtable->add_from_file($1);
	}
	return (
		low		=> $low,
		high		=> $high,
		percent		=> $percent,
		dice		=> $dice,
		multimode	=> $multimode,
		append		=> $append,
		subtable	=> $subtable,
		valuespec	=> $vdice,
		what		=> $what
	);
}

sub add_from_file {
	my ($self, $file) = @_;
	my $path = catfile($self->get_tablepath, $file);
	open(my $fh, '<', $path) or croak "can't open $path: $!\n";
	LINE: while (my $line = <$fh>) {
		# trim whitespace and skip empty lines/comments
		$line =~ s/^\s*//;
		$line =~ s/\s*$//;
		next LINE if ($line =~ /^#/ || $line =~ /^$/);

		# decode everything except for inline subtables
		my %bits = $self->decode_table_entry($line);
		$bits{append} ||= $self->{append};
		# decode an inline subtable entry (no inline nesting!)
		if ($bits{what} =~ /{\s*(even:)?\s*\s*([^;]+(\s*;\s*[^;]+){0,})\s*(;)?}/) {
			my @ents = split(/\s*;\s*/, $2);
			if ($1 && $1 eq 'even:') {
				$bits{subtable} = $self->new_even_subtable(\%bits, @ents);
			} else {
				$bits{subtable} = $self->new_subtable(\%bits, @ents);
			}
		}
		$self->add(TMOL::Slot->new({%bits}));
	}
}

sub new_subtable {
	my ($self, $parentbits, @ents) = @_;
	my $subtable = TMOL::Table->new;
	for my $ent (@ents) {
		my %childbits = $self->decode_table_entry($ent);
		# pass down inheritable properties
		for my $prop (qw(valuespec append)) {
			$childbits{$prop} ||= $parentbits->{$prop};
		}
		$subtable->add(TMOL::Slot->new({ %childbits }));
	}
	return $subtable;
}

sub new_even_subtable {
	my ($self, $parentbits, @ents) = @_;
	my $subtable = TMOL::Table->new;
	my $i = 1;
	for my $ent (@ents) {
		# decode, but even-type specs don't have slot numbers...
		# so we fudge one and then ignore it afterwards
		my %childbits = $self->decode_table_entry("1 $ent");
		$childbits{high} = $childbits{low} = $i;
		# pass down inheritable properties
		for my $prop (qw(valuespec append)) {
			$childbits{$prop} ||= $parentbits->{$prop};
		}
		$subtable->add(TMOL::Slot->new({%childbits}));
		$i++;
	}
	return $subtable;
}

1;
