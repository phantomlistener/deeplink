package Template::Anchor::ParsingContent;

sub new {
	my $class = shift;
	my $self = bless {content => []}, $class;
}

sub last_content_idx {
	my $self = shift;;
	return $#{$self->{content}};
}

sub content_captured {
	my $self = shift;
	if ($#{$self->{content}} < 0) {
		return undef;
	}
	return 1;
}

sub new_content {
	my $self = shift;
	my $string = shift;
	$string ||= '';
	# for scenarios when an anchor tag is adjacent to another
	# this avoids a double "new content" capture.
	my $second_new_content = $self->{_new_content};
	if ($second_new_content) {
		# report negative result for new content
		return undef;
	}
	else {
		push @{$self->{content}}, $string;
		# indicate that new content has just been added
		$self->{_new_content} = 1;
		# report positive result for new content
		return 1;
	}
}

sub add_content {
	my $self = shift;
	my $string = shift;
	my $last = $#{$self->{content}};
	$self->{content}->[$last] .= $string;
	$self->{_new_content} = undef;
}

sub all_content {
	my $self = shift;
	return(@{$self->{content}});
}

1;
