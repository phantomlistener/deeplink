use XML::Parser;
use Data::Dumper;
use strict;

my $parser = new XML::Parser;

my @stack;
my @blocks = ();
my $first = '1';
my %id_hash;
my $current_id = 'root';

$parser->setHandlers(
		Start => \&start,
		End   => \&end,
		Char  => \&char,
		Final => \&final
);

$parser->parsefile("test1.xml");

my $map_idx = 0;
print join "", map {$map_idx++, ", $_\n"} @blocks;

my $xmldoc = join "", @blocks;
print $xmldoc . "\n";

eval {$parser->parse($xmldoc)};
$@ && die 'xml parse failed: ' . $@;
$@ || warn "parse good!";

print Dumper \%id_hash;

sub nprint {
	my ($type, $depth, $tag, $string, $id) = @_;

	my $stack = '[' . join(',', map {$_->[0]} @stack) . ']';
	my $id_str = ($id) ? " id:$id" : "" ;
	print "$type:" . '  ' x $depth . $tag  . $id_str . " $string " .  " $stack\n";
}

sub start {
	my $e = shift;
	my $elm = shift;
	my @attr = @_;

	my $depth = $e->depth();
	my ($orig_string, $id) = extract_id_from_recognized_string($e);

	if ($first && ! $id) {
		$first = 0;
		$id = 'root';
		push @blocks, '';
		$id_hash{$id} = [$#blocks];
	}
	elsif ($id) {
		push @blocks, '' if (length($blocks[$#blocks]));
		$id_hash{$id} = [$#blocks];
		push(@{$id_hash{$current_id}}, $id);
		$current_id = $id;
	}

	push @stack, [$elm, $id];

	$blocks[$#blocks] .= $orig_string;

	nprint('S', $depth, $elm, $orig_string, $id);
}

sub end {
	my $e = shift;
	my $elm = shift;
	my $orig_string = $e->recognized_string();
	my $depth = $e->depth();


	#my @ids;
	#foreach my $elm (@stack) {
		#push @ids, $elm->[1];
		#last if ($#ids == 0);
	#}

	my $elm_data = pop @stack;
	my $id = $elm_data->[1];

	$elm_data = $stack[$#stack];
	$current_id = $elm_data->[1] || 'root';

	# warn "$current_id, $#blocks, $elm";
	if (@stack && $id) {
		$blocks[$#blocks] .= $orig_string;
		push @blocks, '';
		push(@{$id_hash{$current_id}}, $#blocks);
	}
	else {
		$blocks[$#blocks] .= $orig_string;
	}



	nprint('E', $depth, $elm, $orig_string);
}

sub char {
	my $e = shift;
	my $char = shift;
	my $depth = $e->depth();
	# $depth = 0;
	my $orig_string = $e->recognized_string();
	$blocks[$#blocks] .= $orig_string;

	#my $elm_stack = $stack[$#stack];
	#my $id = $elm_stack->[1];

	nprint('C', $depth, '', $orig_string);
}

sub extract_id_from_recognized_string {
	my $e = shift;
        my $orig_string = $e->recognized_string();

        # extract/remove myid attribute and capature myid value
        $orig_string =~ s/(.*)(\s+myid\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;

        my $id;
        if ($3) {
                $id = $3;
        }
	return ($orig_string, $id);
}


sub final {
	print "FINAL\n";
}
