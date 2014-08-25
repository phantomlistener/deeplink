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
# my $init_out = "<r></r>\n";
#is($ta->out(), $init_out, "initial test 2: $file");

print Dumper $ta;
