use strict;
use XML::Parser;
use Data::Dumper;

my $file = 'test5.xml';

my $parser = XML::Parser->new(
		Handlers => {
			Init => \&init,
			Final => \&final,
			Start => \&start,
			End => \&end,
			Char => \&char,
			Proc => \&proc,
			Comment => \&comment,
			CdataStart => \&cdatastart,
			CdataEnd => \&cdataend,
			Default => \&default,
			XMLDecl => \&xmldecl,
		}
);

$parser->parsefile($file);
my $xmldecl;
my @content;
my $content_ref;
my $current_block;
my %block_depths;
my @block_id_stack;
my %blocks;
my $end_block_flag;

my @test_content = (
'<r xmlns:anc="anchor">',
'<a anc:id = "a">abc',
'<b anc:id = "b">',
'<c anc:id ="c"/>',
'def</b>',
'</a>',
"</r>\n"
);


sub init {
	$xmldecl = '';
	@content = ();
	$content_ref = undef;
	%block_depths = ();
	@block_id_stack = ();
	%blocks = ();
	$current_block = undef;
	$end_block_flag = undef;
}

sub final {
	dhandler(@_);
	# print Dumper \@content;
	print $xmldecl;
	my $i = -1;
	my @c = map {my $s = $_; $s =~ s/\n/\\n/g ; $i++; "$i -> $s"} @content;
	print Dumper \@c;
	print  Dumper \%blocks;
	# print Dumper \%block_depths;
}

sub start {
	my $event = event(@_);
	if ($event->{depth} == 0 ) {
		$event->{block_id} = 'root';
	}

	if (defined($event->{block_id})) {
		new_content($event);
		$block_depths{$event->{block_depth}} = 1;
		$current_block = $event->{block_id};

		push @block_id_stack, $current_block;

		if ($#block_id_stack > 0) {
			my $last_block_id_in_stack = $block_id_stack[$#block_id_stack - 1];
			push @{$blocks{$last_block_id_in_stack}}, {block => $current_block};
		}
	}
	else {
		dhandler(@_);
	}
}

sub new_content {
	my $event = shift;
	push(@content, '');
	$content_ref = \$content[$#content];
	add_content($event);

	my $this_block_id = $event->{block_id};
	$current_block = ($this_block_id) ? $this_block_id : $current_block;
	$blocks{$current_block} = [] unless $blocks{$current_block};
	push @{$blocks{$current_block}}, {cdx => $#content};
}

sub add_content {
	my $event = shift;
	$$content_ref .= $event->{string};
}

sub end {
	my $event = event(@_);
	
	# if ($block_depths{$event->{block_depth}} && $event->{depth} > 0) {
	if ($block_depths{$event->{block_depth}}) {

		# Deal with the special case of empty block elements
		#my $current_block_last_idx = scalar @{$blocks{$current_block}} - 1;
		#my $last_idx_value = $blocks{$current_block}->[$current_block_last_idx]->{cdx};

		if ($event->{string}) {
			die unless $current_block;
			push @{$blocks{$current_block}}, {cdx => $#content};
			new_content($event);
		}
		
		$current_block = pop @block_id_stack;
		$current_block = $block_id_stack[$#block_id_stack] if @block_id_stack;
		die unless $current_block;

		$end_block_flag = 1;
	}
	else {
		dhandler(@_);
	}
}

sub char {dhandler(@_)}
sub proc {dhandler(@_)}
sub comment {dhandler(@_)}
sub cdatastart {dhandler(@_)}
sub cdataend {dhandler(@_)}
sub default {dhandler(@_)}

sub xmldecl {
	my $event = event(@_);
	$xmldecl .= $event->{string};
	$content_ref = \$xmldecl;
}

sub event {
	my $p = shift;
	my $string = $p->original_string();
	my $depth = $p->depth();

	debuglog($p, 1, $string, @_);

	my $element = shift @_;
	my %attr = @_;

	my $block_id = $attr{'anc:id'};
	my $block_depth = $element . $depth;

	my $event = {
		string => $string,
		element => $element,
		attr => \%attr,
		block_id => $block_id,
		block_depth => $block_depth,
		depth => $depth
	};
	return $event;
}

sub debuglog {
	my $p = shift;
	my $caller_depth = shift;
	my $string = shift;

	my $event_type = (caller($caller_depth))[3];
	$event_type =~ s/.*::([^:]+)$/$1/;

	$caller_depth++;

	my $event = (caller($caller_depth))[3];
	$event =~ s/.*::([^:]+)$/$1/;

	$string =~ s/\n/\\n/g;

	my $depth = $p->depth();
	my $cdx = $#content;
	# print "$event_type:$event, d=$depth, s=\"$string\": ";
	printf '%-10s:%-9s d=%-2s cdx=%-2s cb=%s s="%s" ', $event_type, $event, $depth, $cdx, $current_block, $string;

	my @args = map {my $s = $_ ; $s =~ s/\n/\\n/g; $s} @_;
	print 'args=(' . join(', ',  map {my $s = $_ ; $s =~ s/\n/\\n/g; $s} @args) . ')' if @args;
	print "\n";
}

sub dhandler {
	my $event = event(@_);
	my $string = $event->{string};
	if ($end_block_flag) {
		new_content($event);
		$end_block_flag = undef;
	}
	else {
		add_content($event);
	}
}
