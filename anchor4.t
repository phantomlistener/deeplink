#!/usr/bin/perl

use strict;
use Data::Dumper;
use Template::Anchor;
use Test::More tests => 12;
use xmlparse;

my $logger = Template::Anchor::get_logger();
$logger->warn_level();

=cut
my $simple1 = 'test_simple1.xml';
my $s1 = Template::Anchor->new(file => $simple1);

ok( xmlparse($s1->out()), "xml parse out $simple1");
is_deeply($s1->dump_inst_nodes(), { 'root' => [ 0, 1 ] }, "$simple1: instance node test");
is_deeply($s1->content(), ['<n/>', "\n"] , "$simple1, content dump test");

my $simple2 = 'test_simple2.xml';
my $s2 = Template::Anchor->new(file => $simple2);

ok( xmlparse($s2->out()), "xml parse out $simple2");
is_deeply($s2->dump_inst_nodes(), { 'root' => [ 0, 1, 2 ] }, "$simple2: instance node test");
is_deeply($s2->content(), ["<?xml version=\"1.0\"?>\n", '<n/>', "\n"] , "$simple2, content dump test");


my $simple3 = 'test_simple3.xml';
my $s3 = Template::Anchor->new(file => $simple3);
ok( xmlparse($s3->out()), "xml parse out $simple3");

is_deeply($s3->dump_inst_nodes(), { x => [2], 'root' => [ 0, 1, 2, 3, 4 ] }, "$simple3: instance node test");
is_deeply($s3->content(), ["<?xml version=\"1.0\"?>\n", '<n>', '', '</n>', "\n"] , "$simple3, content dump test");

=cut
warn 's4 start';
my $simple4 = 'test_simple4.xml';
my $s4 = Template::Anchor->new(file => $simple4);

#print Dumper $s4;

print $s4->out();
print "----\n";

$s4->set_var(y => 'blah');

print $s4->out();
print "----\n";


exit;



ok( xmlparse($s4->out()), "xml parse out $simple4");

is_deeply($s4->dump_inst_nodes(), { y => [3], x => [2], 'root' => [ 0, 1, 2, 3, 4, 5 ] }, "$simple4: instance node test");
is_deeply($s4->content(), ["<?xml version=\"1.0\"?>\n", '<n>', '', '', '</n>', "\n"] , "$simple4, content dump test");

#print Dumper $s4->dump_inst_nodes();
#print Dumper $s4->content();

print  "with xml decl:\n". $s4->out() . "\n";
print  "without xml decl:\n". $s4->out(undef, 1) . "\n";

# print Dumper $s4;
