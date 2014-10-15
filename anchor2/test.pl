use Template::Anchor;
use Template::Anchor::Logger;
use Data::Dumper;
use strict;

my $file = shift @ARGV;

die "need file" unless -T $file;

Template::Anchor::Logger::info_level();

my $t = Template::Anchor->new(file => $file, root_id => 'root');

# print Dumper \$t if $t;

my $inst = $t->instance();

#print Dumper $inst;


$inst->set_var('v', '> first V');

# $inst->do('x');
$inst->set_var('v', '> second V');


print $inst->out() . "\n";
print $inst->out('x') . "\n";

# print Dumper $t;

