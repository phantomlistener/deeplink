package Template::Anchor::ParsingEvent;

my $ANCHOR_TAGS = {
	'var' => 1,
	'include' => 1
};

sub new {
	my $class = shift;
	my $type = shift;
	my $e = shift;
	my $elm = shift;
	my %attr = @_;

	my $self = bless {}, $class;

	my $depth = $e->depth();
	$self->{depth} = $depth;
	$self->{elm} = $elm;
	$self->{attr} = \%attr;
	$self->{type} = $type;
	$self->{tag_depth} = "${elm}${depth}";

	# extract/remove anc:id attribute and capature anc:id value - if found
	# anc:id indicates a block
	my $orig_string = $e->recognized_string();
	my $string = $orig_string;
	my $id;
	if ($attr{'anc:id'}) {
		$string =~ s/(.*)(\s+anc:id\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;
		$string =~ s/ >/>/;
		if ($3) {
			$id = $3;
			$self->{id} = $id;
			$self->{anchor_type} = 'block';
		}
	}

	if (($type eq 'S' || $type eq 'X') && (!defined($id)) && $depth == 0) {
		$id = 'root';
		$self->{id} = $id;
		$self->{anchor_type} = 'block';
	}

	if ($attr{'xmlns:anc'}) {
		$string =~ s/(.*)\s+xmlns:anc\s*=\s*['"][^'"]+['"](.*)/$1$2/;
		$string =~ s/ >/>/;
	}

	my $anchor_tag;
	if ($elm =~ /^anc:(\S+)/) {
		$anchor_tag = $1;
		unless ($ANCHOR_TAGS->{$anchor_tag}) {
			die "unrecognised anchor tag ($anchor_tag): $orig_string";
		}
		
		$string = '';
		$id = $attr{'id'};
		die "missing id in anchor tag: $type: $orig_string" unless ($id && $type eq 'S');

		$self->{id} = $id;
		$self->{anchor_tag} = $anchor_tag;
		$self->{anchor_type} = $anchor_tag;
	}

	$self->{orig_string} = $orig_string;
	$self->{string} = $string;
	return $self;
}

sub set_string {
	my ($self, $string) = @_;
	$self->{string} = $string;
}

sub set_anchor_tag {
	my ($self, $tag) = @_;
	$self->{anchor_tag} = $tag;
}

sub type {shift->{type}}
sub depth {shift->{depth}}
sub elm {shift->{elm}}
sub id {shift->{id}}
sub orig_string {shift->{orig_string}}
sub string {shift->{string}}
sub attr {shift->{attr}}
sub anchor_tag {shift->{anchor_tag}}
sub anchor_type {shift->{anchor_type}}
sub tag_depth {shift->{tag_depth}}

1;
