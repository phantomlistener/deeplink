use XMLExtendedEvents;
use Data::Dumper;
use strict;

my $patterns = {
	tag1 => {
		type => 'start',
		regex => qr/body/,
		handler => sub {
			my $ph = shift;
			print Dumper $ph->get_current_event();
			$ph->set_active('tag2');
		}
	},
	init => {
		type => 'init',
		handler => sub {
			my $ph = shift;
			$ph->set_active('tag1');
		}
	},
	tag2 => {
		type => 'start',
		regex => qr/p/,
		handler => sub {
			my $ph = shift;
			print Dumper $ph->get_current_event();
			$ph->set_active('tag3');
		}
	},
	tag3 => {
		type => 'char',
		regex => qr/again/,
		handler => sub {
			my $ph = shift;
			warn 'char again';
			print Dumper $ph->get_current_event();
		}
	},
};

my $ee = XMLExtendedEvents->new(Patterns => $patterns);
$ee->parsefile('test7.xml');
