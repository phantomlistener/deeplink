use Template::Anchor;
use Data::Dumper;
use strict;

my $t = Template::Anchor->new(file => 'test5.xml');

print Dumper \$t;
