use Template::Anchor;
use Template::Anchor::Logger;
use Data::Dumper;
use strict;

my $file = shift @ARGV;

die "need file" unless -T $file;

Template::Anchor::Logger::info_level();

my $t = Template::Anchor->new(file => $file, root_id => 'root');

my @copy = Template::Anchor::Utils::get_block_copy($t, 'b');

print Dumper \@copy if @copy;

my $i = 0;
map {print "$i => " . $_ . "\n"; $i++} @{$t->{text}};

#print Dumper \$t if $t;

#my $inst = $t->instance();

#print Dumper $inst;


#$inst->set_var('v', '> first V');

#$inst->do('x');

#$inst->set_var('v', '> second V');


#print 'out ->> ' . $inst->out() . "\n";
#print 'out-x ->> ' . $inst->out('x') . "\n";


