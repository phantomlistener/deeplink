package xmlparse;

use XML::Parser;
require Exporter;
our @ISA = 'Exporter';
use strict;

our @EXPORT = ('xmlparse');

our $handler_regex = qr/^Init$|^Start$|^End$|^Default$|^Char$|^Final$/;

sub xmlparse {
	my $string = shift;
	my %h = @_;

	my $p1;

	my %handlers = map {$_ => $h{$_}} grep {$_ =~ /$handler_regex/ && ref($h{$_}) eq 'CODE'} keys %h;
	if (%handlers) {
		$p1 = new XML::Parser(
			Handlers => {
				%handlers
			}
		);
	}
	else {
		$p1 = new XML::Parser();
	}


	eval {
		$p1->parse($string);
	};
	return 1 unless ($@);
	warn $@;
	return 0;
}

1;
