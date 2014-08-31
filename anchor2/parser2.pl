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
my $last_start_event;

my @test_content = (
'<r xmlns:anc="anchor">',
'<a anc:id = "a">abc',
'<b anc:id = "b">',
'<c anc:id ="c"/>',
'def</b>',
'</a>',
"</r>\n"
);

sub event {
	my $type = shift;
	my $p = shift;
	my $string = $p->original_string();
	my $depth = $p->depth();

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
		depth => $depth,
		type => $type
	};
	return $event;
}

sub init {
	$xmldecl = '';
	@content = ();
	$content_ref = undef;
	%block_depths = ();
	@block_id_stack = ();
	%blocks = ();
	$current_block = undef;
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
	my $event = event('start', @_);
	if ($event->{depth} == 0 ) {
		$event->{block_id} = 'root';
	}

	if (defined($event->{block_id})) {
		$last_start_event = $event;
		new_content();
		$block_depths{$event->{block_depth}} = 1;
		$current_block = $event->{block_id};

		push @block_id_stack, $current_block;

		unless($event->{block_id} eq 'root') {
			my $last_block_id_in_stack = $block_id_stack[$#block_id_stack - 1];
			push @{$blocks{$last_block_id_in_stack}}, {block => $current_block};
		}
	}
	else {
		dhandler(@_);
	}
}

sub new_content {
	push(@content, '');
	$content_ref = \$content[$#content];
	add_content();

	my $block_id = $last_start_event->{block_id};
	$blocks{$block_id} = [] unless $blocks{$block_id};

	push @{$blocks{$block_id}}, {cdx => $#content};
}

sub add_content {
	my $event = shift;
	$$content_ref .= $event->{string};
}

sub end {
	my $event = event('end', @_);
	
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
	my $event = event('dhandler', @_);
	my $string = $event->{string};
	if ($last_start_event->{}) {
		new_content($event);
		$end_block_flag = undef;
	}
	else {
		add_content($event);
	}
}
