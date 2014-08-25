package Template::Anchor;

use Template::Anchor::ParsingEvent;
use Template::Anchor::ParsingContent;
use Template::Anchor::Node;
use Template::Anchor::Hash;
use Template::Anchor::Logger;
use XML::Parser;
use Data::Dumper;
use UNIVERSAL 'can';
use strict;

=cut

<img anc:attrid="image1" src="abc.gif" alt="blah"/>

<table anc:attrid="table1" class="tblc1" alt="blah">

$tp->set_attr('image1', src => "def.gif");
$tp->set_attr('table1', class => "tblc2");

what about "id" attribute

include and var can contain a switch element:
<switch key="value"/>
<switch key="value2" default="1"/>

or a
<switchinclude id="x"/>

with a template group:
<switchinclude id="x">
<switch key="value"/>
<switch key="value2" default="1"/>
</switchinclude>

so

<anc:var id="y">
<switch key="value"/>
<switch key="value2" default="1"/>
</anc:var>

or 
<anc:var id="y"><switchinclude id="x"/></anc:var>

attributes anc:var get the same treatment but:
<table anc:attr="x:style">
     

=cut


our $LOG = Template::Anchor::Logger->new();

sub set_logger {
	my $log = pop;

	my @missing_methods = grep {! can($log, $_)} qw(warn fatal info);
	if (@missing_methods) {
		$LOG->warn('invalid logger');
		return undef;
	}

	$LOG = $log;
	return 1;
}

sub get_logger {
	return $LOG;
}

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

sub set_var {
	my $self = shift;
	my $var_id = shift;
	my $var_value = shift;
	
	my $var_index;
	eval {
		$var_index = $self->{nodes_inst}->{$var_id}->start();
	};

	if (defined($var_index)) {
		my $index_thing =  $self->{instance_indexes}->[$var_index];
		if ($index_thing->type() eq 'var') {
			$index_thing->value($var_value);
			$LOG->info("set_var $var_id:$var_value");
			return 1;
		}
		else {
			$LOG->warn("id:$var_id not var");
			return undef;
		}
	}
	else {
		$LOG->warn("id:$var_id not found");
		return undef;
	}
}

sub _dump_nodes {
	my $self = shift;
	my $type = shift;
	my $nodes_ref = $self->{$type};
	my %nodes;

	foreach my $key (keys(%$nodes_ref)) {
		my @indexes = sort {$a <=> $b} keys %{$nodes_ref->{$key}->{indexes}};
		$nodes{$key} = \@indexes;
	}
	return \%nodes;
}

sub dump_inst_nodes {
	my $self = shift;
	return $self->_dump_nodes('nodes_inst');
}

sub dump_nodes {
	my $self = shift;
	return $self->_dump_nodes('nodes');
}

sub dump_inst_nodes_as_string {
	my $self= shift;
	my $inst_node_dump = $self->dump_inst_nodes();

	my $str = '';
	foreach my $key (sort {$a <=> $b} keys %$inst_node_dump) {
		$str .= "$key => ";
		my $indexes = '[' . join(',', @{$inst_node_dump->{$key}}) . '], ';
		$str .= $indexes;
	}
	$str .= "\n\n";

	my @inst_indexes = map {$_->value()} @{$self->{'instance_indexes'}};
	my @content_sample = map { $self->{'content'}->[$_] =~ /(\w+)/ ; $1 } @inst_indexes;

	my $i = 0;
	$str .= join('', map {sprintf '%-3s ', $i++} @inst_indexes) . "\n";
	$str .= join('', map {sprintf '%-3s ', $_} @inst_indexes) . "\n";
	$str .= join('', map {sprintf '%-3s ', $_} @content_sample) . "\n";

	return $str;
}

sub repeat { &do(@_); }

sub do {
	my $self = shift;
	my $node_id = shift;

	my $nodes_inst = $self->{'nodes_inst'};
	my $nodes = $self->{'nodes'};
	my $instance = $self->{'instance_indexes'};

	my $node_inst = $nodes_inst->{$node_id};
	my $node = $nodes->{$node_id};

	my $start_idx = $node->start();
	my $end_idx = $node->end();

	my $new_start_idx = $node_inst->start();
	my $new_end_idx = $node_inst->end();

	# Node may simply be "invisble" and just needs to be switched on
	unless ($instance->[$new_start_idx]->visible()) {
		$self->_make_node_visible($node_id);
		$LOG->info("do: $node_id - make visible");
		return 1;
	}

	$LOG->info("do: $node_id");

	my $next = $new_end_idx + 1;
	# where 6 is where the 3..5 ends
	# build array of stuff to splice;

	# Create new list of index nodes to insert into content list
	my @to_splice;
	foreach my $index ($start_idx..$end_idx) {
		my $content_index = $self->{content_indexes}->[$index]->instance();
		push @to_splice, $content_index;
	}

	# Insert new node instance into list of instance content
	splice(@{$instance}, $next, 0, @to_splice);


	# deref nodes_inst list
	my %nodes_inst = (%$nodes_inst);

	my %nodes_updated = $node_inst->set_indexes_to_this_start($next, $node, $self);
	foreach my $id (keys %nodes_updated) {
		delete $nodes_inst{$id};
	}

	# update indexes of surrounding nodes
	my $len = $node->length();
	foreach my $id (keys %nodes_inst) {
		my $node_inst = $nodes_inst->{$id};
		my $node = $nodes->{$id};

		my @node_inst_indexes = $node_inst->indexes();
		$node_inst->increment_index_if_greater($new_start_idx, $len, $node);
	}

	# Update existing node indexes to make them visible
	$self->_make_node_visible($node_id);
	$LOG->info("node done: $node_id");
}

sub _make_node_visible {
	my $self = shift;
	my $node_id = shift;
	my $node = $self->{'nodes_inst'}->{$node_id};

	foreach my $index ($node->indexes()) {
		$self->{instance_indexes}->[$index]->visible(1);
	}
}

sub history {
	my $self = shift;
	my @history;
	my %count;
	foreach my $index (@{$self->{instance_indexes}}) {
		my $id = $index->id();
		my $value;
		if (defined($id)) {
			my $history;
			$count{$id} = 0 unless($count{$id});
			$count{$id}++;
			
			if ($index->type() eq 'var') {
				$value = $index->value();
				$history = [$id, $value];
			}
			else {
				$history = [$id, $count{$id}];
			}
			push @history, $history;
		}
	}
	return \@history;
}

sub out {
	my $self = shift;
	my $template_group = shift;
	my $no_xmldecl = shift;

	# Only the "root" or top level template should do an XML include
	# By default output any xml declaration

	my $out = '';
	my $content = $self->{'content'};
	foreach my $index (@{$self->{instance_indexes}}) {
		next unless $index->visible();
		my $value = '';
		my $index_type = $index->type();

		if ($index_type eq 'idx') {
			$value = $content->[$index->value()];
		}
		elsif ($index_type eq 'var') {
			$value = $index->value();
		} 
		elsif ($index_type eq 'include') {
			# If there is an include then template is part of a group
			# and rendering (out) is occuring as part of the group context
			# template group will be passed in as method
			# included template will have it's own "out" method called.
			$value = '';
		} 
		elsif ($index_type eq 'xmldecl' && ! $no_xmldecl) {
			$value = $content->[$index->value()];
		}

		$out .= $value;
	}
	return $out;
}

sub content {
	shift->{content};
}

sub node_idx {
	shift->{node_idx};
}

sub node_idx_inst {
	shift->{node_idx_inst};
}

sub indexes {
	my $self = shift;
	my @indexes = map {$_->value()} @{$self->{content_indexes}};
	return \@indexes;
}

{ 

# Block to contain the basic parsing process for XML::Parser
# a few globals contantined here:

my $PGLOBAL;

sub init {
	$PGLOBAL = {
		CONTENT => Template::Anchor::ParsingContent->new(),
		INDEXES => [],
		INDEXES_TO_IDS => [],
		TAGDEPTH => {},
		IDSTACK => [],
		NODES => {},
		ANCHOR_TAG => undef,
	};
}

sub _do_parse {
	my $self = shift;

	my $parser = XML::Parser->new(
		Handlers => {
			XMLDecl => \&xmldecl,
			Init => \&init,
			Start => \&start,
			End   => \&end,
			Default => \&other,
			Char  => \&char,
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

	# capture parsing results 
	my $CONTENT = $PGLOBAL->{CONTENT};
	my $NODES = $PGLOBAL->{NODES};
	my @INDEXES = @{$PGLOBAL->{INDEXES}};


	# generate indext to id lookup list
	my $indexes_to_ids = [];
	foreach my $id (keys %$NODES) {
		my $node = $NODES->{$id};
		my @indexes = $node->indexes();
		map { $indexes_to_ids->[$_] = $id } ($node->indexes());
	}

	# cover the case of nodes outside of the root node
	$NODES->{root}->add_index(0);
	$NODES->{root}->add_index($CONTENT->last_content_idx());

	# Capture results of parse
	$self->{content} = [$CONTENT->all_content()];
	$self->{indexes_to_ids} = $indexes_to_ids;
	$self->{nodes} = {%$NODES};
	$self->{nodes_inst} = {map {$_ => $NODES->{$_}->instance()} keys %$NODES};

	$self->{content_indexes} = [@INDEXES];
	$self->{instance_indexes} = [map {$_->instance()} @INDEXES]; 
	$self->_make_node_visible('root');

	# discard all working globals after parse
	$PGLOBAL = undef;

	return 1; # 
}

sub finalise_xml_event {
	my ($event) = @_;

	my $string = $event->string();
	my $CONTENT = $PGLOBAL->{CONTENT};
	my $INDEXES = $PGLOBAL->{INDEXES};
	my $IDSTACK = $PGLOBAL->{IDSTACK};
	my $NODES = $PGLOBAL->{NODES};

	unless ($CONTENT->content_captured()) {
		$CONTENT->new_content();
		my $index;
		if ($event->type() eq 'X') {
			$index = Template::Anchor::XmlDecl->new(value => $PGLOBAL->{CONTENT}->last_content_idx());
		}
		else {
			$index = _new_last_idx();
		}
		push (@$INDEXES, $index);
	}

	$CONTENT->add_content($string);
	my $id = $IDSTACK->[$#{$IDSTACK}];
	$NODES->{$id}->add_index($CONTENT->last_content_idx()) if defined($id);
}

sub _new_last_idx {
	return Template::Anchor::Idx->new(value => $PGLOBAL->{CONTENT}->last_content_idx());
}

sub start {
	my $event = Template::Anchor::ParsingEvent->new('S', @_);
	my $CONTENT = $PGLOBAL->{CONTENT};
	my $INDEXES = $PGLOBAL->{INDEXES};
	my $TAGDEPTH = $PGLOBAL->{TAGDEPTH};
	my $IDSTACK = $PGLOBAL->{IDSTACK};
	my $NODES = $PGLOBAL->{NODES};

	my $anchor_tag = $event->anchor_tag();
	my $anchor_type = $event->anchor_type();

	if ($PGLOBAL->{ANCHOR_TAG}) {
		# Processing events inside anchor tag
		warn 'start event in anchor tag: ' . $event->orig_string();
	}
	elsif ($anchor_type) {
		my $id = $event->id();
		if ($anchor_tag) {
			$PGLOBAL->{ANCHOR_TAG} = $anchor_tag;
		}

		$TAGDEPTH->{$event->tag_depth()} = $id;
		my $parent_id = $IDSTACK->[$#{$IDSTACK}];
		$CONTENT->new_content();

		push(@$IDSTACK, $id);

		my $index_type;
		my $node;

		$CONTENT->add_content($event->string());

		if ($anchor_type eq 'block') {
			$node = Template::Anchor::Node::Block->new($id);
			if ($CONTENT->content_captured()) {
				$index_type = _new_last_idx();
			}
		}
		elsif ($anchor_type eq 'var') {
			$node = Template::Anchor::Node::Var->new($id);
			$index_type = Template::Anchor::Var->new();
		}
		elsif ($anchor_type eq 'include') {
			$node = Template::Anchor::Node::Include->new($id);
			$index_type = Template::Anchor::Include->new();
		}

		$NODES->{$id} = $node;
		$node->add_index($CONTENT->last_content_idx());
		$NODES->{$parent_id}->add_index($CONTENT->last_content_idx()) if $parent_id;
	}
	elsif ($anchor_tag) {
		$PGLOBAL->{ANCHOR_TAG} = $anchor_tag;

		unless ($anchor_tag =~ /^var|include$/) {
			my $orig_string = $event->orig_string();
			die "unrecognised $orig_string";
		}

		my $id = $event->attr()->{id};

		$CONTENT->new_content();
		# warn $event->orig_string();
		$TAGDEPTH->{$event->tag_depth()} = $id;
		my $parent_id = $IDSTACK->[$#{$IDSTACK}];
		push(@$IDSTACK, $id);

		my $node;
		my $index_type;

		if ($anchor_tag eq 'var') {
			$node = Template::Anchor::Node::Var->new($id);
			$index_type = Template::Anchor::Var->new();
		}
		elsif ($anchor_tag eq 'include') {
			$node = Template::Anchor::Node::Include->new($id);
			$index_type = Template::Anchor::Include->new();
		}

		$NODES->{$id} = $node;
		$node->add_index($CONTENT->last_content_idx());

		$NODES->{$parent_id}->add_index($CONTENT->last_content_idx());
		push (@$INDEXES, $index_type);
	}
	else {
		finalise_xml_event($event);
	}
}

sub end {
	my $event = Template::Anchor::ParsingEvent->new('E', @_);

	if ($event->anchor_tag()) {
		$PGLOBAL->{ANCHOR_TAG} = undef;
		$event->set_string('');
	}
	elsif ($PGLOBAL->{ANCHOR_TAG}) {
		# warn 'end event in anchor tag';
	}

	my $CONTENT = $PGLOBAL->{CONTENT};
	my $NODES = $PGLOBAL->{NODES};
	my $INDEXES = $PGLOBAL->{INDEXES};
	my $IDSTACK = $PGLOBAL->{IDSTACK};
	my $TAGDEPTH = $PGLOBAL->{TAGDEPTH};

	my $string = $event->string();
	my $tag_depth = $event->tag_depth();

	$CONTENT->add_content($string);
	if ($TAGDEPTH->{$tag_depth}) {
		# found the end of a block, or finishing of an anchor tag event
		my $id = $TAGDEPTH->{$tag_depth};

		delete $TAGDEPTH->{$tag_depth};

		$NODES->{$id}->add_index($CONTENT->last_content_idx());

		if ($CONTENT->new_content('')) {
		# warn $event->orig_string();
			push (@$INDEXES, _new_last_idx());
			pop @$IDSTACK;
		}
	}
}

sub char {
	my $event = Template::Anchor::ParsingEvent->new('C', @_);

	if ($PGLOBAL->{ANCHOR_TAG}) {
		$event->set_string('');
		$event->set_anchor_tag($PGLOBAL->{ANCHOR_TAG});
	}
	else {
		finalise_xml_event($event);
	}
}

sub xmldecl {
	my $event = Template::Anchor::ParsingEvent->new('X', @_);
	finalise_xml_event($event);
}

sub other {
	my $event = Template::Anchor::ParsingEvent->new('O', @_);

	if ($PGLOBAL->{ANCHOR_TAG}) {
		$event->set_string('');
		$event->set_anchor_tag($PGLOBAL->{ANCHOR_TAG});
	}

	finalise_xml_event($event);
}

}

1;
