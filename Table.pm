package Table;

use base qw(Class::Accessor);
use strict;
use warnings;

Table->follow_best_practice;
Table->mk_accessors(qw(tablepath slots high low));

use Scalar::Util qw(blessed);
use Carp qw(cluck croak);
use Table::Slot;
use File::Spec::Functions qw(catfile);
use Data::Dumper;

sub random {
	my $self = shift;
	my $range = 1 + ($self->get_high - $self->get_low);
	my $result = $self->{_cache}->{int(rand($range)) + $self->get_low};
	return $result->action;
}

sub add {
	my $self = shift;
	for my $new (@_) {
		if (ref($new) && $new->isa('Table::Slot')) {
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
			croak "Table::add expects Table::Slot refs only";
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
	if ($what =~ s/^(group|multi)\s+(\d+d\d+([+-]\d+)?(x\d+)?)\s*//i) {
		($multimode, $dice) = ($1, $2);
	}

	# decode subtable spec and load up the subtable
	# happens again every time the table is loaded, but blehhh RAM cheap
	my $subtable = undef;
	if ($what =~ s/^@(.+)//) {
		$subtable = Table->new({tablepath => $self->get_tablepath});
		$subtable->add_from_file($1);
	}
	return (
		low		=> $low,
		high		=> $high,
		percent		=> $percent,
		dice		=> $dice,
		multimode	=> $multimode,
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

		# decode an inline subtable entry (no inline nesting!)
		if ($bits{what} =~ /{\s*(even:)?\s*\s*([^;]+(\s*;\s*[^;]+){0,})\s*(;)?}/) {
			my @ents = split(/\s*;\s*/, $2);
			if ($1 && $1 eq 'even:') {
				$bits{subtable} = $self->new_even_subtable(\%bits, @ents);
			} else {
				$bits{subtable} = $self->new_subtable(\%bits, @ents);
			}
		}
		$self->add(Table::Slot->new({%bits}));
	}
}

sub new_subtable {
	my ($self, $parentbits, @ents) = @_;
	my $subtable = Table->new;
	for my $ent (@ents) {
		my %childbits = $self->decode_table_entry($ent);
		if ($parentbits->{valuespec} && ! $childbits{valuespec}) {
			$childbits{valuespec} = $parentbits->{valuespec};
		}
		$subtable->add(Table::Slot->new({ %childbits }));
	}
	return $subtable;
}

sub new_even_subtable {
	my ($self, $parentbits, @ents) = @_;
	my $subtable = Table->new;
	my $i = 1;

	for my $ent (@ents) {
		$subtable->add(
			Table::Slot->new({
				low		=> $i,
				high 		=> $i,
				valuespec	=> $parentbits->{valuespec},
				what		=> $ent
			})
		);
		$i++;
	}
	return $subtable;
}

1;
