use Template::Anchor;
use Template::Anchor::Logger;
use Data::Dumper;
use strict;

Template::Anchor::Logger::info_level();

my $t = Template::Anchor->new(file => 'test5.xml');

print Dumper \$t;
