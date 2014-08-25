use xmlparse;
use Data::Dumper;
# qr/^Init$|^Start$|^End$|^Default$|^Char$|^Final$/;


my $xml = '<?xml version="1.0"?>



<n><anc:var id="x"/></n>
';

xmlparse($xml, Start => \&start, End => \&end, Default => \&default, Char => \&char, Final => \&final);

sub start {
	print "start: ";
	any(@_);
}

sub end {
	print "end: ";
	any(@_);
}

sub default {
	print "default: ";
	any(@_);
}

sub char {
	print "char: ";
	any(@_);
}

sub final {
	print "final: ";
	any(@_);
}

sub any {
	print $_[1] . "\n";
}
