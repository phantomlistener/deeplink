package Template::Anchor;

use strict;
use XML::Parser;
use Data::Dumper;
use Template::Anchor::Logger;

our $LOG = Template::Anchor::Logger->new();

my $ANCHOR_TAGS = {
	'var' => 1,
	'include' => 1
};

sub new {
	my $class = shift;
	my %args = @_;

	my $self = bless {%args}, $class;

	my $file = $args{file};
	my $stream = $args{stream};
	
	unless ($file or $stream) {
		$LOG->fatal("$class needs file or stream");
		return undef;
	}

	if ($self->_do_parse()) {
		# only return self on successful parse
		return $self
	}

	return undef;
}

my $xmldecl;
my $xmlend;
my @text;
my @content;
my $text_ref;
my %block_depths;
my @block_id_stack;
# my %blocks;
my $current_parse_self;

sub _do_parse {
	my $self = shift;
	$current_parse_self = $self;

	my $parser = XML::Parser->new(
		Handlers => {
			Init => \&init,
			Final => \&final,
			Start => \&start,
			End => \&end,
			Char => \&dhandler,
			Proc => \&dhandler,
			Comment => \&dhandler,
			CdataStart => \&dhandler,
			CdataEnd => \&dhandler,
			Default => \&dhandler,
			XMLDecl => \&xmldecl,
		}
	);


	# Catch XML parse failures
	eval {
		if ($self->{stream}) {
			$parser->parse($self->{stream});
		}
		else {
			$parser->parsefile($self->{file});
		}
	};

	if ($@) {
		# capture any parse errors and bail out here
		$LOG->fatal($@);
		return undef;
	}


	init();
	return 1;
}

sub init {
	$xmldecl = '';
	$xmlend = '';
	@text = ();
	@content = ();
	$text_ref = undef;
	%block_depths = ();
	@block_id_stack = ();
	# %blocks = ();
}

sub event {
	my $type = shift;
	my $p = shift;
	my $element = shift @_;

	my $string = $p->original_string();
	my $depth = $p->depth();
	my %attr = @_;
	my $block_depth = $element . $depth;

	# print ">>$type: $string\n";

	my $event = {
		string => $string,
		element => $element,
		attr => \%attr,
		block_depth => $block_depth,
		depth => $depth,
		type => $type
	};

	if ($type eq 'start') {
		process_attributes($event);
	}

	my $block_id = $block_depths{$event->{block_depth}};
	if ($block_id) {
		# must be an end of a block
		$event->{block_id} = $block_id;
	}

	return $event;
}

sub process_attributes {
	my $event = shift;
	my %attr = %{$event->{attr}};
	my $string = $event->{string};
	my $type = $event->{type};
	my $element = $event->{element};

	if ($attr{'anc:id'}) {
		my $block_id = $attr{'anc:id'};

		$string =~ s/(.*)(\s+anc:id\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;
		$string =~ s/ >/>/;

		$event->{string} = $string;
		$event->{block_id} = $block_id;
	}

	if ($attr{'xmlns:anc'}) {
		$string =~ s/(.*)\s+xmlns:anc\s*=\s*['"][^'"]+['"](.*)/$1$2/;
		$string =~ s/ >/>/;
		$event->{string} = $string;
	}

	if ($element =~ /^anc:(\S+)/) {
		my $anchor_tag = $1;
		unless ($ANCHOR_TAGS->{$anchor_tag}) {
			die "unrecognised anchor tag ($anchor_tag): $string";
		}
		
		$event->{string} = '';
		my $id = $attr{'id'};
		die "missing id in anchor tag: $type: $string" unless ($id && $type eq 'start');

		$event->{id} = $id;
		$event->{anchor_tag} = $anchor_tag;
	}
}

sub final {
	dhandler(@_);

	$current_parse_self->{xmldecl} = $xmldecl;
	$current_parse_self->{xmlend} = $xmlend;
	$current_parse_self->{text} = [@text];
	$current_parse_self->{content} = [@content];
	# $current_parse_self->{blocks} = {%blocks};

	#print $xmldecl;
	#my $i = -1;
	#my @c = map {my $s = $_; $s =~ s/\n/\\n/g ; $i++; "$i -> $s"} @text;
	#print Dumper \@c;
	#print  Dumper \%blocks;
}

sub start {
	my $event = event('start', @_);
	if ($event->{depth} == 0 ) {
		$event->{block_id} = 'root';
	}

	my $anchor_tag = $event->{anchor_tag};

	if (defined($event->{block_id})) {
		new_add_push($event);
		my $block_id = $event->{block_id};
		$block_depths{$event->{block_depth}} = $block_id;
		push @block_id_stack, $block_id;

		unless($block_id eq 'root') {
			my $last_block_id_in_stack = $block_id_stack[$#block_id_stack - 1];
			die unless $last_block_id_in_stack;
			# push @{$blocks{$last_block_id_in_stack}}, {type => 'block', id => $block_id};
		}

		push @content, {type => 'block_start', id => $block_id, idx => $#text};
	}
	elsif (defined($anchor_tag)) {
		my $id = $event->{id};
		my $last_block_id_in_stack = $block_id_stack[$#block_id_stack];
		die unless $last_block_id_in_stack;

		# push @{$blocks{$last_block_id_in_stack}}, $anchor_element;
		new_add_push($event);
		push @content, {type => $anchor_tag, id => $id}; #, idx => $#text};
	}
	else {
		dhandler(@_);
	}
}

sub new_add_push {
	my $event = shift;
	push(@text, '');
	$text_ref = \$text[$#text];
	add_text($event);

	my $block_id = $event->{block_id};
	if ($block_id) {
		# $blocks{$block_id} = [] unless $blocks{$block_id};
		# push @{$blocks{$block_id}}, {cdx => $#text};
		#push @content, {type => 'text', idx => $#text};
	}
}

sub add_new_pop {
	my $event = shift;
	add_text($event);

	my $block_id = $event->{block_id};

	my $last_block_idx = $content[$#content]->{idx};
	my $last_type = $content[$#content]->{type};
	# my $last_block_idx_idx = $blocks{$block_id}->[$last_block_idx]->{cdx} if ($last_block_idx >= 0);

	if ($last_type && $last_type eq 'block_start' && $last_block_idx == $#text) {
		$content[$#content]->{type} = 'block';
	}
	else {
		push @content, {type => 'block_end', id => $block_id, idx => $#text};
		# push @{$blocks{$block_id}}, {cdx => $#text};
		# push @content, {type => 'text', idx => $#text};
	}

	if ($block_id eq 'root') {
		$text_ref = \$xmlend;
	}
	else {
		push(@text, '');
		$text_ref = \$text[$#text];
		pop @block_id_stack;
	}
}

sub add_text {
	my $event = shift;
	$$text_ref .= $event->{string};
}

sub end {
	my $event = event('end', @_);
	my $block_id = $event->{block_id};
	
	# if ($block_depths{$event->{block_depth}} && $event->{depth} > 0) {
	if ($block_id)  {
		add_new_pop($event);
	}
	else {
		dhandler(@_);
	}
}

sub xmldecl {
	my $event = event('xmldecl', @_);
	$xmldecl .= $event->{string};
	$text_ref = \$xmldecl;
}

sub dhandler {
	my $event = event('dhandler', @_);
	add_text($event);
}

sub instance {
	my $self = shift;
	my $instance = Template::Anchor::Instance->new($self);
	return $instance;
}

package Template::Anchor::Instance;

sub new {
	my $class = shift;
	my $template = shift;

	my $self = bless {template => $template}, $class;

	# clone the content list
	my @instance = map {my %h = %$_ ; \%h} @{$template->{content}};
	$self->{instance} = \@instance;

	return $self;
}

sub out {
	my $self = shift;
	my $out = '';

	my $text = $self->{template}->{text};
	foreach my $c (@{$self->{instance}}) {
		if (defined($c->{idx})) {
			$out .= $text->[$c->{idx}];
		}
		elsif (defined($c->{value})) {
			$out .= $text->[$c->{value}];
		}
	}
	return $out;
}


1;
