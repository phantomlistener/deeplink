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

1;
