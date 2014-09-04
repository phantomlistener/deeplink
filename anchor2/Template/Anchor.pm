package Template::Anchor;

use strict;
use XML::Parser;
use Data::Dumper;
use Template::Anchor::Logger;

our $LOG = Template::Anchor::Logger->new();

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
my @content;
my $content_ref;
my %block_depths;
my @block_id_stack;
my %blocks;

sub _do_parse {
	my $self = shift;

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

	$self->{
		xmldecl => $xmldecl,
		content => [@content],
		blocks => {%blocks}
	};
	init();
}

sub init {
	$xmldecl = '';
	@content = ();
	$content_ref = undef;
	%block_depths = ();
	@block_id_stack = ();
	%blocks = ();
}

sub event {
	my $type = shift;
	my $p = shift;
	my $element = shift @_;

	my $string = $p->original_string();
	my $depth = $p->depth();
	my %attr = @_;
	my $block_depth = $element . $depth;

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

	return $event;
}

sub process_attributes {
	my $event = shift;
	my %attr = %{$event->{attr}};
	my $string = $event->{string};

	if ($attr{'anc:id'}) {
		my $block_id = $attr{'anc:id'};

		$string =~ s/(.*)(\s+anc:id\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;
		$string =~ s/ >/>/;

		$event->{string} = $string;
		$event->{block_id} = $block_id;
	}
}


sub final {
	dhandler(@_);

	print $xmldecl;
	my $i = -1;
	my @c = map {my $s = $_; $s =~ s/\n/\\n/g ; $i++; "$i -> $s"} @content;
	print Dumper \@c;
	print  Dumper \%blocks;
}

sub start {
	my $event = event('start', @_);
	if ($event->{depth} == 0 ) {
		$event->{block_id} = 'root';
	}

	if (defined($event->{block_id})) {
		new_add_push($event);
		my $block_id = $event->{block_id};
		$block_depths{$event->{block_depth}} = $block_id;
		push @block_id_stack, $block_id;

		unless($block_id eq 'root') {
			my $last_block_id_in_stack = $block_id_stack[$#block_id_stack - 1];
			die unless $last_block_id_in_stack;
			push @{$blocks{$last_block_id_in_stack}}, {block => $block_id};
		}
	}
	else {
		dhandler(@_);
	}
}

sub new_add_push {
	my $event = shift;
	push(@content, '');
	$content_ref = \$content[$#content];
	add_content($event);

	my $block_id = $event->{block_id};
	if ($block_id) {
		$blocks{$block_id} = [] unless $blocks{$block_id};
		push @{$blocks{$block_id}}, {cdx => $#content};
	}
}

sub add_new_pop {
	my $event = shift;
	add_content($event);

	my $block_id = $event->{block_id};

	my $last_block_idx = $#{$blocks{$block_id}};
	my $last_block_idx_idx = $blocks{$block_id}->[$last_block_idx]->{cdx} if ($last_block_idx >= 0);

	unless (defined($last_block_idx_idx) && $last_block_idx_idx == $#content) {
		push @{$blocks{$block_id}}, {cdx => $#content};
	}


	if ($block_id ne 'root') {
		push(@content, '');
		$content_ref = \$content[$#content];
		pop @block_id_stack;
	}
}

sub add_content {
	my $event = shift;
	$$content_ref .= $event->{string};
}

sub end {
	my $event = event('end', @_);
	my $block_id = $block_depths{$event->{block_depth}};
	
	# if ($block_depths{$event->{block_depth}} && $event->{depth} > 0) {
	if ($block_id)  {
		$event->{block_id} = $block_id;
		add_new_pop($event);
	}
	else {
		dhandler(@_);
	}
}

sub xmldecl {
	my $event = event('xmldecl', @_);
	$xmldecl .= $event->{string};
	$content_ref = \$xmldecl;
}

sub dhandler {
	my $event = event('dhandler', @_);
	add_content($event);
}

1;
