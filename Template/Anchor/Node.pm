package Template::Anchor::Node;

sub new {
	my $class = shift;
	my ($id, $start, $end) = @_;

	my $self = {indexes => {}, id => $id};
	if (defined($start) && defined($end)) {
		my $length = $end - $start + 1;
		$self = {id => $id, 'length' => $length, start => $start, end => $end, indexes =>{}};
	}
	return bless $self, $class;
}

sub id {
	return shift->{id};
}

sub indexes {
	my $self = shift;
	my @indexes = @_;

	if (@indexes) {
		$self->{indexes} = {map {$_ => 1} @indexes};
	}

	return (sort {$a <=> $b} keys(%{$self->{indexes}}));
}

sub add_index {
	my $self = shift;
	my $index = shift;
	$self->{indexes}->{$index} = 1;
}

sub start {
	my $self = shift;
	my @indexes = sort {$a <=> $b} keys(%{$self->{indexes}});
	my $start = shift @indexes;

	return $start;
}

sub end {
	my $self = shift;
	my @indexes = sort {$a <=> $b} keys(%{$self->{indexes}});
	my $end = pop @indexes;

	return $end;
}

sub set_indexes_to_this_start {
	my $self = shift;
	my $start = shift;
	my $original_node = shift;
	my $template = shift;

	my @indexes = $original_node->indexes();

	# build a contiguous index list of this nodes indexes
	# including any intervening indexes of contained nodes
	@indexes = ($indexes[0] .. $indexes[$#indexes]);


	# determine offset for nodes
	my $delta = $start - $indexes[0];

	my %node_id_list; # hash to track nodes already processed

	# update all nodes
	foreach my $index (@indexes) {
		my $node_id = $template->{indexes_to_ids}->[$index];
		if (defined($node_id) && !defined($node_id_list{$node_id})) {
			my $node_inst = $template->{nodes_inst}->{$node_id};
			my $node = $template->{nodes}->{$node_id};

			my @node_indexes = $node->indexes();
			my @new_indexes = map {$_ + $delta} @node_indexes;
			$node_inst->indexes(@new_indexes);
			
			$node_id_list{$node_id} = 1;
		}
	}
	return %node_id_list; # return any nodes affected
}

sub increment_index_if_greater {
	my $self = shift;
	my $index_to_test = shift;
	my $increment_amount = shift;

	my $node = shift; # original node
	my $id = $node->id();

	my @indexes = (keys %{$self->{indexes}});

	my @new_indexes = ();
	foreach my $index (@indexes) {
		if ($index >= $index_to_test) {
			# $LOG->info("$id, $index increment by $increment_amount");
			my $new_index = $index + $increment_amount;
			push(@new_indexes, $new_index);
		}
		else {
			push @new_indexes, $index;
		}
	}
	$self->{indexes} = {map {$_ => 1} @new_indexes};
}

sub length {
	my $self = shift;

	my $start = $self->start();
	my $end = $self->end();

	return ($end - $start + 1);
}

sub instance {
	my $self = shift;

	my $instance = {};
	# $self->_set_start_end() unless $self->start();

	foreach my $key (keys %$self) {
		my $value = $self->{$key};
		if (ref($value) eq 'HASH') {
			$instance->{$key} = {%$value};
		}
		else {
			$instance->{$key} = $value;
		}
	}

	return bless $instance, ref($self);
}

package Template::Anchor::Node::Block;
our @ISA = 'Template::Anchor::Node';
sub type {'block'}

package Template::Anchor::Node::Var;
our @ISA = 'Template::Anchor::Node';
sub type {'var'}

package Template::Anchor::Node::Include;
our @ISA = 'Template::Anchor::Node';
sub type {'include'}

1;
