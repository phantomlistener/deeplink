package Template::Anchor::Set;

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub add {
	my $self = shift;
	my $id = shift;
	my $template = shift;

	$self->{$id} = $template;
}

sub resolve {
	my $self = shift;
	my $id = shift;

	my $template = $self->{$id};
	my $new_template = $template->resolve($self);
}

1;
