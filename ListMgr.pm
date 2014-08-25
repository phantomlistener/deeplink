package ListMgr;
use strict;

=cut 

my @a = (0, 1, 2, 3, 4, 5, 6);


my $node_idx = {
	r => [0, 6],
	h => [1, 2],
	b => [3, 5],
	c => [4, 4],
};

=cut 

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my $node_idx = shift;

	my $node_idx_inst = {};
	my $node_len = {};
	$self->{'node_idx'} = $node_idx;
	$self->{'node_idx_inst'} = $node_idx_inst;
	$self->{'node_len'} = $node_len;

	my $max = 0;
	foreach my $node (keys(%$node_idx)) {
		my @node_indexes = @{$node_idx->{$node}};

		# build an instance copy of node_idx;
		$node_idx_inst->{$node} = \@node_indexes;

		my $start_index = $node_indexes[0];
		my $end_index = $node_indexes[1];

		# workout the last index overall - max
		$max = $end_index if ($end_index > $max);

		# determine the length of all nodes.
		my $len = $end_index - $start_index + 1;
		$node_len->{$node} = $len;
	}

	# build overall index list
	my @indexes = (0..$max);
	$self->{'indexes'} = [@indexes];
	$self->{'indexes_inst'} = [@indexes];

	return $self;
}

sub repeat {
	my $self = shift;
	my $node_name = shift;

	my $node_idx = $self->{'node_idx'};
	my $node_idx_inst = $self->{'node_idx_inst'};
	my $indexes_inst = $self->{'indexes_inst'};
	my $node_len = $self->{'node_len'};

	my $start_idx = $node_idx->{$node_name}->[0];
	my $new_start_idx = $node_idx_inst->{$node_name}->[0];
	my $end_idx = $node_idx->{$node_name}->[1];
	my $new_end_idx = $node_idx_inst->{$node_name}->[1];

	my $next = $new_end_idx + 1;
	# where 6 is where the 3..5 ends
	splice(@{$indexes_inst}, $next, 0, ($start_idx..$end_idx));

	my $len = $node_len->{$node_name};

	my @values = values(%$node_idx_inst);
	foreach my $pair (@values) {
		if ($pair->[1] >= $new_start_idx) {
			$pair->[1] += $len;
			($pair->[0] += $len) if ($pair->[0] >= $new_start_idx);
		}
	}
}

sub node_idx {
	shift->{node_idx};
}

sub node_idx_inst {
	shift->{node_idx_inst};
}

sub indexes {
	shift->{indexes};
}

sub indexes_inst {
	shift->{indexes_inst};
}

1;
