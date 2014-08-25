#!/usr/bin/perl

use strict;
use Data::Dumper;
use Template::Anchor;
use Test::More tests => 32;
use xmlparse;

my $logger = Template::Anchor::get_logger();
# $logger->info_level();

my $file;

my $null_test = Template::Anchor->new(file => '/non_existent_template/x/y/z');

ok(!$null_test, 'non existent template create returns false');
like($logger->last_msg(), qr/no such file or directory/im, 'no such file or directory');

$file = 'test1.xml';
my $ta = Template::Anchor->new(file => $file);

my $test_raw_content = [
	'<html><head></head><body>',
	'<p x="y" q=\'p\'>this ',
	'<e/>',
	'is ',
	'<b>a</b>',
	' test</p>',
	'</body></html>',
	"\n"
];

is_deeply($ta->content(), $test_raw_content, 'content test raw content');

my $test1nonecontent = "<html><head></head><body></body></html>\n";

is($ta->out(), $test1nonecontent, 'content test - none visible');

$ta->do('p');
my $test1pcontent = '<html><head></head><body><p x="y" q=\'p\'>this is  test</p></body></html>' . "\n";

is($ta->out(), $test1pcontent, 'content test  - p visible');

$ta->do('b');


my $test1bcontent = '<html><head></head><body><p x="y" q=\'p\'>this is <b>a</b> test</p></body></html>' . "\n";

is($ta->out(), $test1bcontent, "content test - b visible");

$ta->do('e');
my $test1econtent = '<html><head></head><body><p x="y" q=\'p\'>this <e/>is <b>a</b> test</p></body></html>' . "\n";

is($ta->out(), $test1econtent, "content test - e visible");

$ta->do('p');

my $file1content_after_repeat_p =
'<html><head></head><body><p x="y" q=\'p\'>this <e/>is <b>a</b> test</p><p x="y" q=\'p\'>this is  test</p></body></html>' . "\n";

is($ta->out(), $file1content_after_repeat_p, "content test after repeat('p')");


my $test2content = '<html><head></head><body><p x="y" q=\'p\'>this <e anc:id="e"/>is <b>a</b> test</p></body></html>';

my $t2 = Template::Anchor->new(stream => $test2content);

# print Dumper $t2;

my $test2blocks = [
	'<html><head></head><body><p x="y" q=\'p\'>this ',
	'<e/>',
	'is <b>a</b> test</p></body></html>'
];

my $test2content_out = '<html><head></head><body><p x="y" q=\'p\'>this is <b>a</b> test</p></body></html>';

is($t2->out(), $test2content_out, 'content 2 no change');




my $file3 = 'test3.xml';
my $t3 = Template::Anchor->new(file => $file3);

my $test3blocks = [
	'<html>',
	'<head>blahd</head>',
	'blab',
	'<body>blap',
	'<p x="y" q=\'p\'>this ',
	'<e/>',
	'is ',
	'<b>a</b>',
	' test</p>',
	'blahh</body>',
	'</html>',
	"\n"
];

is_deeply($t3->content(), $test3blocks, 'content 3 raw');

# my $test3content_out = '<html><head>blahd</head>blab<body>blap<p x="y" q=\'p\'>this <e/>is <b>a</b> test</p>blahh</body></html>' . "\n";

my $test3content_out = '<html>blab</html>' . "\n";
is($t3->out(), $test3content_out, 'content no blocks preserved 3');

my $test3content_hd_out = '<html><head>blahd</head>blab</html>' . "\n";
$t3->do('hd');
is($t3->out(), $test3content_hd_out, 'content hd block 3');

my $test3content_bod_out = '<html><head>blahd</head>blab<body>blapblahh</body></html>' . "\n";
$t3->do('bod');
is($t3->out(), $test3content_bod_out, 'content bod block 3');

my $test3content_p_out = '<html><head>blahd</head>blab<body>blap<p x="y" q=\'p\'>this is  test</p>blahh</body></html>' . "\n";
$t3->do('p');
is($t3->out(), $test3content_p_out, 'content p block 3');

my $test3content_b_out = '<html><head>blahd</head>blab<body>blap<p x="y" q=\'p\'>this is <b>a</b> test</p>blahh</body></html>' . "\n";
$t3->do('b');
is($t3->out(), $test3content_b_out, 'content b block 3');

my $test3content_all_out = '<html><head>blahd</head>blab<body>blap<p x="y" q=\'p\'>this <e/>is <b>a</b> test</p>blahh</body></html>' . "\n";
$t3->do('e');
is($t3->out(), $test3content_all_out, 'content all 3');

=cut 

Symbolic representation of the nodes in the anchor parse tree result

html/head/body:id -> p:id -> "this "
                          -> e:id
                          -> "is "
                          -> b:id -> "x = "
                                  -> varid:x
                          -> " test"


=cut

my $file4 = 'test4.xml';
my $t4 = Template::Anchor->new(file => $file4);
# $Template::Anchor::DEBUG = 1;

# print $t4->out;


my $test4content_out = '<?xml version="1.0"?>
<html><head></head><body></body></html>
';

is($t4->out(), $test4content_out, 'content no blocks preserved 4');


$t4->set_var('x','HELLO');

is($t4->out(), $test4content_out, 'after set_var but no visible block 4');

ok(! $t4->set_var('blah','HELLO'), 'non existent id');
like($logger->last_msg(), qr/id.*not found/, 'non existent id msg');

ok(! $t4->set_var('b','HELLO'), 'attempt to set non var id');
like($logger->last_msg(), qr/id.*not var/, 'not var id msg');

$t4->do('b');

my $test4content_b1_out = '<?xml version="1.0"?>
<html><head></head><body><b>x = HELLO</b></body></html>
';

is($t4->out(), $test4content_b1_out, 'test 4 content b1');

$t4->do('b');

my $test4content_b2_out = '<?xml version="1.0"?>
<html><head></head><body><b>x = HELLO</b><b>x = WORLD</b></body></html>
';

$t4->set_var('x','WORLD');

is($t4->out(), $test4content_b2_out, 'test 4 content b2');


$t4->set_var('x','WORLD 2');



my $test4content_va_out = '<?xml version="1.0"?>
<html><head></head><body><b>x = HELLO</b><b>x = WORLD 2</b></body></html>
';

is($t4->out(), $test4content_va_out, 'content preserved after another set var');


my $test4content_p_out = '<?xml version="1.0"?>
<html><head></head><body><p x="y" q=\'p\'>this is <b>x = HELLO</b><b>x = WORLD 2</b> test</p></body></html>
';

$t4->do('p');

is($t4->out(), $test4content_p_out, 'content preserved after do p');

#print $t4->out();


$t4->do('p');
$t4->do('b');

my $test4content_ppb_out = '<?xml version="1.0"?>
<html><head></head><body><p x="y" q=\'p\'>this is <b>x = HELLO</b><b>x = WORLD 2</b> test</p><p x="y" q=\'p\'>this is <b>x = </b> test</p></body></html>
';
is($t4->out(), $test4content_ppb_out, 'content preserved after do p and b');

$t4->do('e');

ok( xmlparse($t4->out()), 'xml parse');

my $test4content_e_out = '<?xml version="1.0"?>
<html><head></head><body><p x="y" q=\'p\'>this is <b>x = HELLO</b><b>x = WORLD 2</b> test</p><p x="y" q=\'p\'>this <e/>is <b>x = </b> test</p></body></html>
';

is($t4->out(), $test4content_e_out, 'content preserved after do e');

my $test_set_var_again = '<?xml version="1.0"?>
<html><head></head><body><p x="y" q=\'p\'>this is <b>x = HELLO</b><b>x = WORLD 2</b> test</p><p x="y" q=\'p\'>this <e/>is <b>x = </b><b>x = WORLD 3</b> test</p></body></html>
';

$t4->do('b');
$t4->set_var('x','WORLD 3');

is($t4->out(), $test_set_var_again, 'content preserved after another repeat and set vars');

my $te1 = Template::Anchor->new(stream => '<invalid content>');
print $te1;
ok(! $te1, 'parse failure result');
like($logger->last_msg(), qr/not well-formed/m, 'parse failure msg');
