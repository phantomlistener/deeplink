#!/usr/bin/perl

use strict;
use Data::Dumper;
use Template::Anchor;
use Test::More tests => 32;
use xmlparse;

my $logger = Template::Anchor::get_logger();
$logger->info_level();

=cut

my $test_var_xml = 'test_var.xml';
my $t_var = Template::Anchor->new(file => $test_var_xml);
ok( xmlparse($t_var->out()), 'xml parse template 6');


print Dumper $t_var->dump_inst_nodes();
print Dumper $t_var->content();

print Dumper $t_var;

$t_var->set_var('x', 'try this');

=cut

my $file6 = 'test6.xml';
my $t6 = Template::Anchor->new(file => $file6);

# print $t6->out();

ok( xmlparse($t6->out()), 'xml parse template 6');

#print Dumper $t6->dump_inst_nodes();

#print Dumper $t6->content();

$t6->set_var('x', 'value for x');

#print Dumper $t6;
