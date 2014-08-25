use Template::Anchor::Logger;
use strict;

my $LOG = Template::Anchor::Logger->new();

sub thing {
	$LOG->level(1);
	$LOG->error('some error or other');
	$LOG->fatal('some error or other');
}

thing();

die 'die here';
