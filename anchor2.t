#!/usr/bin/perl

use strict;
use Data::Dumper;
use xmlparse;
use Template::Anchor;
use Test::More tests => 12;

#my $logger = Template::Anchor::get_logger();
#$logger->info_level();

my $file;

$file = 'test5.xml';

# test5.xml looks like this:
#<?xml version="1.0"?>
#<r xmlns:anc="anchor">
#  <a anc:id="a">
#    <b anc:id="b">
#      <c anc:id="c"/>
#    </b>
#  </a>
#</r>

my $ta = Template::Anchor->new(file => $file);
my $init_out = "<r></r>\n";
is($ta->out(), $init_out, "initial test");

ok(xmlparse($ta->out()), 'xml ok');


# randomised test;
my $random_test_result = 1;
my @a = qw(a b c);
foreach (0..100) {

	my $i = int(rand(3));
	my $c = $a[int(rand(3))];

	$ta->do($c);
	my $r = xmlparse($ta->out());

	unless ($r) {
		warn "$_ \n";
		warn $ta->out();
		$random_test_result = 0;
		goto DONE;
	}
}
DONE:

# $Template::Anchor::DEBUG = 1;

ok($random_test_result, 'random test result');

unless ($random_test_result) {
	print $ta->dump_inst_nodes_as_string();
}


$ta = Template::Anchor->new(file => $file);
$init_out = "<r></r>\n";
is($ta->out(), $init_out, "initial test 2: $file");


$ta->do('a');
is($ta->out(), "<r><a></a></r>\n", 'do a');

$ta->do('c');
is($ta->out(), "<r><a><c/></a></r>\n", 'do c ');

$ta->do('c');
is($ta->out(), "<r><a><c/><c/></a></r>\n", 'do 2nd c');

$ta->do('a');
is($ta->out(), "<r><a><c/><c/></a><a></a></r>\n", 'do 2nd a');

$ta->do('b');
is($ta->out(), "<r><a><c/><c/></a><a><b></b></a></r>\n", 'do b');

$ta->do('a');
is($ta->out(), "<r><a><c/><c/></a><a><b></b></a><a></a></r>\n", 'do 3rd a');

ok(xmlparse($ta->out()), 'xml ok');
ok($ta->dump_inst_nodes_as_string() =~ /c =>.* a =>.* b =>/m, 'dump_inst_nodes_as_string()');
