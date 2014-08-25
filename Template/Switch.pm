package Template::Switch;

# need to change this to Template::Anchor

use XML::Parser;
use Data::Dumper;
use UNIVERSAL 'can';
use strict;

my $content_blocks;
my $id_hash;
my $id_tree;
my $var_id_parents;
my %tag_depth_hash;
my @tag_depth_stack;
my @id_stack;
my $current_id;
my $root_tag;
# my %id_var_hash;


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

=cut 

How will the repeat block process work??
Just log the requests!
each

=cut

sub repeat_block {
	my $self = shift;
	my $block_id = shift;

	my $blocks = $self->{instance}->{blocks};
	my $var_values = $self->{instance}->{var_values};

	my $block_idx = $#{$blocks};
	if ($block_idx >= 0 && defined($blocks->[$block_idx]->{$block_id})) {
		# block has already been repeated at least once
		$blocks->[$block_idx]->{$block_id}++;
	}
	else {
		# new block repeat
		push(@{$blocks}, {$block_id => 1});
	}

	if ($self->{var_id_parents}->{$block_id}) {
		my @var_ids = keys %{$self->{var_id_parents}->{$block_id}};

		foreach my $var_id (@var_ids) {
			push(@{$var_values->{$var_id}}, undef);
		}
	}
}

sub set_var {
	my $self = shift;
	my $var_id = shift;
	my $var_value = shift;

	my $var_values = $self->{instance}->{var_values};

	if (exists($var_values->{$var_id})) {
		my $var_values_arr = $var_values->{$var_id};
		$var_values_arr->[$#{$var_values_arr}] = $var_value;
	}
}

sub _do_parse {
	my $self = shift;

	my $parser = XML::Parser->new(
		Handlers => {
			Init => \&init,
			Start => \&start,
			End   => \&end,
			Char  => \&char,
			Final => \&final
		}
	);

	$id_hash = {};
	$content_blocks = [];
	$id_tree = {};
	$var_id_parents = {};

	$self->{id_hash} = $id_hash;
	$self->{content_blocks} = $content_blocks;
	$self->{id_tree} = $id_tree;
	$self->{var_id_parents} = $var_id_parents;

	# print "T  dep tag     string         id    cid   tag depth\n";
	if ($self->{stream}) {
		$parser->parse($self->{stream});
	}
	else {
		$parser->parsefile($self->{file});
	}

	# Post process
	$self->_post_process_template_parse();

}

sub _post_process_template_parse {
	my $self = shift;
	my %var_values = map {$_->id() => [undef]} grep {can($_, 'id')} values (%{$self->{id_hash}});

	my $instance = {
		var_values => \%var_values,
		blocks => []
	};

	$self->{instance} = $instance;
}

sub out {
	my $self = shift;
	# index var values
	return $self->_out('root');
}

sub _out {
	my $self = shift;
	my $id = shift;

	my $string = '';

	my $node = $self->{id_hash}->{$id};
	if (can($node, 'id')) {
		# Node is a var
		my $var_values = $self->{instance}->{var_values}->{$id};
		my $var_value = shift (@{$var_values});
		$string .= $var_value;
	}
	else {
		# Node is a block - array, are there any repeats?
		my $repeat_count = $self->_handle_repeats($id);
		my $count = $self->{id_tree}->{$id}->{count} + $repeat_count;
		
		do {
			foreach my $i (1 .. $count) {
				# $string .= "[$id $i]";
				foreach my $n (@{$node}) {
					if (can($n, 'id')) {
						my $local_id = $n->id();
						$string .= $self->_out($local_id);
					}
					else {
						$string .= $self->{content_blocks}->[$n];
					}
				}
			}
			$repeat_count = $self->_handle_repeats($id);
			$count = $self->{id_tree}->{$id}->{count} + $repeat_count;
		} while ($repeat_count )
	}

	return $string;
}

sub _handle_repeats {
	my $self = shift;
	my $id = shift;

	my $instance_blocks = $self->{instance}->{blocks};
	my $repeat_count = 0;

	if ($#{$instance_blocks} >= 0) {
		my ($repeat_id) = keys %{$instance_blocks->[$#{$instance_blocks}]};
		if ($repeat_id eq $id) {
			$repeat_count = $instance_blocks->[$#{$instance_blocks}]->{$id};
			pop(@{$instance_blocks});
		}
	}
	return $repeat_count;
}

=cut

S tag                      append to current block node text
S tag + id                 create new current id, add block node text, append to current block node text 
E tag                      append to current block node text
E tag + id                 append to current block node text
C after tag + id end       create new block node, append text
C                          append to current block node text

Need to set up %id_var_hash and %id_block_count;

# initially id_var_hash will be {id => { }} as no vars will be set. Default value ??
id_var_hash = { id => { block_count . var => value, ...}

# initially {id => 1 } . Or zero? "invisible block" init count?
id_block_count = {id => n, ... }

id_2_block = {var_id => block_id, ... }

so $t->repeat(block_id) increments id_block_count->{id}++ 
so $t->set_var(varid) looks up id_2_block to find block_id. looks up id_block_count, increments if 0, then id_var_hash

=cut

sub nprint {
	my ($type, $depth, $tag, $string, $id, $init_block) = @_;
	my $tag_depth;

	$tag_depth = $tag_depth_stack[$#tag_depth_stack];
	$current_id = $id_stack[$#id_stack];

	my $close_block = 0;

	if ($type eq 'S') {

		$tag_depth = "$tag$depth";
		push @tag_depth_stack, $tag_depth;

		if ($tag eq 'myvar' && defined($id)) {
			if ($current_id) {
				push(@{$id_hash->{$current_id}}, varid($id));
				$id_hash->{$id} = varid($id);
				_populate_id_tree($id, $current_id, $init_block); 
				foreach my $block_id (@id_stack) {
					$var_id_parents->{$block_id} = {} unless $var_id_parents->{$block_id};
					$var_id_parents->{$block_id}->{$id} = 1;
				}
			}
		}
		elsif ($id) {
			# update tracking data
			$tag_depth_hash{$tag_depth} = $id;

			# update structure of "parent" block
			push(@{$id_hash->{$current_id}}, id($id)) if $current_id;

			push @{$content_blocks}, '';

			# initialise data for newly discovered block
			$id_hash->{$id} = [$#{$content_blocks}];

			_populate_id_tree($id, $current_id, $init_block); 
			$current_id = $id;
			push @id_stack, $current_id;
		}
	}
	elsif ($type eq 'E') {
		# update tracking data
		$tag_depth = pop @tag_depth_stack;

		if ($tag_depth_hash{$tag_depth}) {
			# We have reached the close of a tag which is also a block with an id
			# so we need to close properly - pop stack which keeps track of which block we are in
			# also so text can be finally added with close
			pop @id_stack;
			$close_block = 1;
		}

	}
	else {
		_add_final_block_index();
	}


#	format = 
#@< @<< @<<<<<< @<<<<<<<<<<<<< @<<<< @<<<< @<<<<<<
#($type, $depth, $tag, $string, $id, $current_id, $tag_depth)
#.

#	write;

	# add to existing string
	$content_blocks->[$#{$content_blocks}] .= $string;
	# start a new block
	push @{$content_blocks}, '' if $close_block;
}

sub _populate_id_tree {
	my ($id, $current_id, $init_block) = @_;

	if (defined($current_id)) {
		# need to populate parent node or current id
		my $cref = 	$id_tree->{$current_id};

		$cref->{ids} = {} unless(defined($cref->{ids}));
		$cref->{ids}->{$id} = {};

	}

	$id_tree->{$id} = {count => $init_block};
}

sub init {
	my $e = shift;
	# %id_var_hash = ();
	%tag_depth_hash = ();
	@tag_depth_stack = ();
	@id_stack = ();

	$root_tag = 'root';
	$current_id = $root_tag;
}

sub start {
	my $e = shift;
	my $elm = shift;
	my %attr = @_;
	my $init_block = 1;


	my $depth = $e->depth();
	my $orig_string = $e->recognized_string();
	my $id;

	# extract/remove myid attribute and capature myid value - if found
	if ($attr{myid}) {
		$orig_string =~ s/(.*)(\s+myid\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;

		if ($3) {
			$id = $3;
		}
		if (defined($attr{initblock})) {
			$orig_string =~ s/(.*)(\s+initblock\s*=\s*['"])([^'"]+)(['"])(.*)/$1$5/;
			$init_block = ($3) ? 1 : 0;
		}
	}
	elsif ($root_tag) {
		$id = $root_tag;
		undef $root_tag;
	}

	unless ($id) {
		if ($elm eq 'myvar') {
			$id = $attr{id};
			$orig_string = '';
		}
	}

	# Kick off start 'S' tag capture
	# depth, elm and orig string will always be populated
	# but id is only populated if it has been discovered above
	nprint('S', $depth, $elm, $orig_string, $id, $init_block);
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
	pop @{$content_blocks};
	#push @{$id_hash{'root'}}, $#content_blocks;
	_add_final_block_index();
	#print Dumper \%tag_depth_hash;
}

sub _add_final_block_index {
		my $latest_idx = $#{$id_hash->{$current_id}};
		if ($id_hash->{$current_id}->[$latest_idx] != $#{$content_blocks}) {
			push(@{$id_hash->{$current_id}}, $#{$content_blocks});
		}
}

sub id { Template::Switch::BlockID->new(shift); }
sub varid { Template::Switch::VarID->new(shift); }

package Template::Switch::ID;

sub new {
	my $id = pop;
	my $class = shift;
	return bless \$id, $class;
}

sub id {
	my $self = shift;
	return $$self;
}

package Template::Switch::BlockID;
our @ISA ='Template::Switch::ID';
sub type {'block'}

package Template::Switch::VarID;
our @ISA ='Template::Switch::ID';

sub type {'var'}

1;

