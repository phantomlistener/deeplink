package Template::Snippet;

use XML::Parser;
use Data::Dumper;
use strict;

my @blocks;
my %id_hash;
my %tag_depth_hash;
my $current_id;

sub new {
	my $class = shift;
	my %args = @_;

	my $self = bless {%args}, $class;

	my $file = $args{file};
	my $stream = $args{stream};
	
	die 'need file or stream' unless ($file or $stream);

	$self->_do_parse();

	return $self;
}

sub _do_parse {
	my $self = shift;

	my $parser = XML::Parser->new(
		Handlers => {
			Start => \&start,
			End   => \&end,
			Char  => \&char,
			Final => \&final
		}
	);

	@blocks = ('');
	%id_hash = ('root' => [0]);
	%tag_depth_hash = ();
	$current_id = 'root';

	if ($self->{stream}) {
		$parser->parse($self->{stream});
	}
	else {
		$parser->parsefile($self->{file});
	}

	$self->{id_hash} = \%id_hash;
	$self->{blocks} = \@blocks;
}

sub add_to_string {
	my $str = shift;
	$blocks[$#blocks] .= $str;
}

sub nprint {
	my ($type, $depth, $tag, $string, $id) = @_;
	# print "$type:" . '  ' x $depth . $tag  . ": $id\n";

	if ($id) {

		# if we have an id block start new block content capture
		push(@blocks, '');

		# identify tag+depth for later reference
		my $tag_depth = "$tag$depth";
		# warn "$type: $tag_depth: $string";
		$tag_depth_hash{$tag_depth} = $id;

		# identify first content/block index
		$id_hash{$id} = [$#blocks];

		push(@{$id_hash{$current_id}}, $id);
		$current_id = $id;
	}

	add_to_string($string);

	if ($type eq 'E') {
		my $tag_depth = "$tag$depth";
		if (defined($tag_depth_hash{$tag_depth})) {
			# warn "$type: $tag_depth: $string";
			# push(@blocks, '');
			$current_id = $tag_depth_hash{$tag_depth};
			my $id = $tag_depth_hash{$tag_depth};
			push(@{$id_hash{$id}}, $#blocks);
			push(@blocks, '');
		}
	}

}

sub start {
	my $e = shift;
	my $elm = shift;
	my @attr = @_;


	my $depth = $e->depth();
	my $orig_string = $e->recognized_string();

	# extract/remove myid attribute and capature myid value
	$orig_string =~ s/(.*)(\s+myid\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;

	my $id;
	if ($3) {
		$id = $3;
	}

	# Kick off start 'S' tag capture
	# depth, elm and orig string will always be populated
	# but id is only populated if it has been discovered above
	nprint('S', $depth, $elm, $orig_string, $id);
}

sub end {
	my $e = shift;
	my $elm = shift;
	my $orig_string = $e->recognized_string();
	my $depth = $e->depth();
	# $depth = 0;

	nprint('E', $depth, $elm, $orig_string);

}

sub char {
	my $e = shift;
	my $char = shift;
	my $depth = $e->depth();
	# $depth = 0;
	my $orig_string = $e->recognized_string();

	nprint('C', $depth, '', $orig_string);
}

sub final {
	my $e = shift;
	$id_hash{'root'}->[1] = $#blocks;
	# print Dumper $blocks;
}

1;
