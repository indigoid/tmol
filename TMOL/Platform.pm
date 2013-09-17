package TMOL::Platform;

use POSIX qw(uname);

sub tablepath {
	my $uname = (uname)[0];
	if ($uname eq 'Windows') {
		return "$ENV{USERPROFILE}/tmol"
	}
	return "$ENV{HOME}/tmol"
}

1;
