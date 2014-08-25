#!/usr/bin/perl

use Template::Anchor;
use Data::Dumper;
# use Test::More tests => 9;
use strict;

my $file1 = 'test4.xml';
my $t = Template::Anchor->new(file => $file1);

# print Dumper $t->history();


$t->do('p');
$t->do('b');
$t->do('e');

print $t->out();

#print Dumper $t;
exit;

$t->set_var('x', 'hello!');
$t->repeat('p');
$t->do('b');
$t->set_var('x', 'world!');
$t->repeat('p');
$t->do('b');
$t->set_var('x', 'today!');


# print $t->out();

print Dumper $t;

warn scalar @{$t->{instance_indexes}};

