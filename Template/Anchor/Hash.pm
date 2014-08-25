package Template::Anchor::Hash;

sub new {
	my $class = shift;
	my $self = {@_, visible => 0};
	return bless $self, $class;
}

sub visible {
	my $self = shift;
	my $state = shift;
	$self->{visible} = $state if (defined($state));

	return $self->{visible};
}

sub instance {
	my $self = shift;
	my %new = %$self;
	return bless \%new, ref($self);
}

sub value {
	my $self = shift;
	my $value = shift;
	$self->{value} = $value if defined($value);

	return $self->{value};
}

sub id {
	my $self = shift;
	my $id = shift;
	$self->{id} = $id if defined($id);

	return $self->{id};
}

package Template::Anchor::Var;
our @ISA = 'Template::Anchor::Hash';

sub type {'var'}

package Template::Anchor::Idx;
our @ISA = 'Template::Anchor::Hash';

sub type {'idx'}

package Template::Anchor::Include;
our @ISA = 'Template::Anchor::Hash';

sub type {'include'}

package Template::Anchor::XmlDecl;
our @ISA = 'Template::Anchor::Hash';

sub type {'xmldecl'}

1;

