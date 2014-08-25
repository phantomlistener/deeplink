use Template::Switch;
use Data::Dumper;
use strict;

my $file4 = 'test4.xml';
my $t4 = Template::Switch->new(file => $file4);
#print $t4->out;
print Dumper $t4;

$t4->set_var('x','HELLO');
$t4->repeat_block('b');
$t4->set_var('x','WORLD');
$t4->repeat_block('p');
 $t4->repeat_block('p');
$t4->set_var('x','AGAIN');

#print $t4->out;
#print "\n";
#print Dumper $t4;
