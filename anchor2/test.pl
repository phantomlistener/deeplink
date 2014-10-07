use Template::Anchor;
use Template::Anchor::Logger;
use Data::Dumper;
use strict;

my $file = shift @ARGV;

die "need file" unless -T $file;

Template::Anchor::Logger::info_level();

my $t = Template::Anchor->new(file => $file);

# print Dumper \$t if $t;

my $inst = $t->instance();



$inst->do('x');

print $inst->out() . "\n";

# print Dumper $inst;

