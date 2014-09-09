package Template::Anchor::Logger;
use strict;

# Crude facsimilie of Log4Perl
# Just follows the same basic API
# To access loggout output just call $LOG->level()
# Just the act of calling this is enough to activate logging.

our %LEVELS = (
	INFO => 1,
	WARN => 2,
	FATAL => 3,
	NOLOG => 4
);

our $LEVEL = $LEVELS{NOLOG};

sub new { bless {}, shift; }

my $_log = sub {
	my $self = shift;
	my $msg = shift;

	$msg =~ s/^\s*([^\s].+[^\s])\s*$/$1/g;

	$self->{last_msg} = $msg;

	my @c = caller(1);
	$c[3] =~ /.*::(.*)/;
	my $f = uc($1);
	return unless ($LEVELS{$f} >= $LEVEL);

	my $i = 2;
	do {
		@c = caller($i++);
	} until ($c[0] !~ /^Template::Anchor/);

	my $package = $c[0];
	my $line = $c[2];

	warn "$f: $msg at $package line $line\n";
	
};


sub last_msg {
	my $self = shift;
	return $self->{last_msg};
}

sub info { &$_log }
sub warn { &$_log }
sub fatal { &$_log }

sub info_level { $LEVEL = $LEVELS{INFO} }
sub warn_level { $LEVEL = $LEVELS{WARN} }
sub fatal_level { $LEVEL = $LEVELS{FATAL} }

1;
