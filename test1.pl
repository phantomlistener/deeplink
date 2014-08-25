use Template::Switch;
use Data::Dumper;
use Test::More tests => 9;
use strict;

my $file1 = 'test1.xml';
my $t = Template::Switch->new(file => $file1);

my $test1blocks = [
	'<html><head></head><body>',
	'<p x="y" q=\'p\'>this ',
	'<e/>',
	'is ',
	'<b>a</b>',
	' test</p>',
	'</body></html>'
];

my $test1id_hash = {
	'e' => [ '2' ],
	'p' => [ '1', id('e'), '3', id('b'), '5' ],
	'b' => [ '4' ],
	'root' => ['0', id('p'), '6' ]
};

is_deeply($t->{id_hash}, $test1id_hash, 'id_hash');
is_deeply($t->{content_blocks}, $test1blocks, 'blocks');

# is($t->out(), $file1content, "original content test");

my $file1content = '<html><head></head><body><p x="y" q=\'p\'>this <e/>is <b>a</b> test</p></body></html>';

is($t->out(), $file1content, 'content preserved');


my $test2content = '<html><head></head><body><p x="y" q=\'p\'>this <e myid="e"/>is <b>a</b> test</p></body></html>';

my $t2 = Template::Switch->new(stream => $test2content);

# print Dumper $t2;

my $test2blocks = [
	'<html><head></head><body><p x="y" q=\'p\'>this ',
	'<e/>',
	'is <b>a</b> test</p></body></html>'
];

my $test2id_hash = {
	'e' => [ '1' ],
	'root' => ['0', id('e'), '2' ]
};

is_deeply($t2->{id_hash}, $test2id_hash, 'id_hash 2');
is_deeply($t2->{content_blocks}, $test2blocks, 'blocks 2');

my $test2content_out = '<html><head></head><body><p x="y" q=\'p\'>this <e/>is <b>a</b> test</p></body></html>';

is($t2->out(), $test2content_out, 'content preserved 2');

my $file3 = 'test3.xml';
my $t3 = Template::Switch->new(file => $file3);



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
	'</html>'
];

my $test3id_hash = {
    'hd' => [1],
	'bod' => [3, id('p'), 9],
	'e' => [ '5' ],
	'p' => [ '4', id('e'), '6', id('b'), '8' ],
	'b' => [ '7' ],
	'root' => ['0', id('hd'), 2, id('bod'), 10]
};

is_deeply($t3->{content_blocks}, $test3blocks, 'blocks 3');
is_deeply($t3->{id_hash}, $test3id_hash, 'id_hash 3');

my $test3content_out = '<html><head>blahd</head>blab<body>blap<p x="y" q=\'p\'>this <e/>is <b>a</b> test</p>blahh</body></html>';

is($t3->out(), $test3content_out, 'content preserved 3');

#my $file4 = 'test4.xml';
#my $t4 = Template::Switch->new(file => $file4);
#print $t4->out;
# print Dumper $t4;

#$t4->set_var('x','HELLO');
#$t4->repeat_block('b');
#$t4->set_var('x','WORLD');
#$t4->repeat_block('p');
# $t4->repeat_block('p');
#$t4->set_var('x','AGAIN');

#print $t4->out;
#print "\n";
#print Dumper $t4;

sub id { Template::Switch::BlockID->new(shift); }
sub varid { Template::Switch::VarID->new(shift); }


__END__


Concept - how to capture dynamic aspects of template

template local

{
     id => id object
     id => ...
}

Create a hash of ids with objects
Objects will have a repeat count and id list
id object - can be block or var

block.repeat_count
block.id_list = {var list}
var.value_hash = {repeat_count => value
var.block_id = block_id


<html><head></head><body><p myid ="p" x="y" q='p'>this <myvar id='x'/><e myid="e"/>is <b myid="b">a</b> test</p></body></html>

<html>
	<head myid="hd">blahd</head>
	blab
	<body myid="bod">blap
		<p myid ="p" x="y" q='p'>this 
			<e myid="e"/>
			is 
			<b myid="b">a</b> 
		 test</p>
	blahh</body>
</html>

<html><head></head><body>
	<p myid ="p" x="y" q='p'>
		this 
			<e myid="e"/>
		is 
			<b myid="b">
				a
			</b>
		 test
	</p>
</body></html>
