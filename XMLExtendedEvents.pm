package XMLExtendedEvents;
use base 'XML::Parser';
use strict;

sub new {
	my $class = shift;
	my %ARGS = @_;

	my $patterns = $ARGS{Patterns};
	my $pattern_handler = PatternHandler->new($patterns);
	delete $ARGS{Patterns};

	my %args = ( 
		%ARGS,
		Handlers => {
			Init => \&XMLExtendedEventsHandlers::init,
			Start => \&XMLExtendedEventsHandlers::start,
			End => \&XMLExtendedEventsHandlers::end,
			Default => \&XMLExtendedEventsHandlers::default,
			Char => \&XMLExtendedEventsHandlers::char,
			Final => \&XMLExtendedEventsHandlers::final
		},
		'Non-Expat-Options' => {
			EE_pattern_handler => $pattern_handler
		}
		
	);
	my $self = $class->SUPER::new(%args);
	return bless($self, $class);
}


package XMLExtendedEventsHandlers;

sub get_pattern_handler {
	my $parser = shift;
	my $pattern_handler = $parser->{'Non-Expat-Options'}->{EE_pattern_handler};
	return $pattern_handler;
}

sub init {
	my $parser = shift;
	my $pattern_handler = get_pattern_handler($parser);
	my @patterns = $pattern_handler->init_patterns();

	foreach my $pattern (@patterns) {
		my $handler = $pattern_handler->_get_handler($pattern);
		&$handler($pattern_handler);
	}
}

sub start {
	my $parser = shift;
	my $pattern_handler = get_pattern_handler($parser);
	$pattern_handler->capture_event_data('start', $parser, @_);
	my @patterns = $pattern_handler->start_patterns();

	my $current_event = $pattern_handler->get_current_event();

	foreach my $pattern (@patterns) {
		my $handler = $pattern_handler->_get_handler($pattern);
		my $regex = $pattern_handler->_get_regex($pattern);
		if ($current_event->{elm} =~ /$regex/) {
			&$handler($pattern_handler);
		}
	}

	@patterns = $pattern_handler->attr_patterns();
	foreach my $pattern (@patterns) {
		my $handler = $pattern_handler->_get_handler($pattern);
		my $regex = $pattern_handler->_get_regex($pattern);

		foreach my $attr (keys(%{$current_event->{attr}})) {
			if ($attr =~ /$regex/) {
				&$handler($pattern_handler);
			}
		}
	}
}

sub end {
	my $parser = shift;
	my $pattern_handler = get_pattern_handler($parser);

	$pattern_handler->capture_event_data('end', $parser, @_);
	my $current_event = $pattern_handler->get_current_event();
	my @patterns = $pattern_handler->end_patterns();

	foreach my $pattern (@patterns) {
		my $handler = $pattern_handler->_get_handler($pattern);
		my $regex = $pattern_handler->_get_regex($pattern);
		if ($current_event->{elm} =~ /$regex/) {
			&$handler($pattern_handler);
		}
	}
}

sub default {
	my $parser = shift;
	my $pattern_handler = get_pattern_handler($parser);
	$pattern_handler->capture_event_data('default', $parser, @_);
	my $current_event = $pattern_handler->get_current_event();

	my $string = $current_event->{elm};
	my @patterns = $pattern_handler->default_patterns();
	foreach my $pattern (@patterns) {
		my $handler = $pattern_handler->_get_handler($pattern);
		my $regex = $pattern_handler->_get_regex($pattern);
		if ($string =~ /$regex/) {
			&$handler($pattern_handler);
		}
	}
}

sub char {
	my $parser = shift;
	my $pattern_handler = get_pattern_handler($parser);
	$pattern_handler->capture_event_data('char', $parser, @_);

	my $current_event = $pattern_handler->get_current_event();
	my $char = $current_event->{elm};
	my @patterns = $pattern_handler->char_patterns();
	foreach my $pattern (@patterns) {
		my $handler = $pattern_handler->_get_handler($pattern);
		my $regex = $pattern_handler->_get_regex($pattern);
		if ($char =~ /$regex/) {
			&$handler($pattern_handler);
		}
	}
}

sub final {
}


package PatternHandler;

sub new {
	my $class = shift;
	my $patterns = shift;
	$patterns ||= {};
	return bless {
		patterns => $patterns,
		key_val => {}
	}, $class;
}

sub _get_handler {
	my $self = shift;
	my $key = shift;

	my $pattern = $self->{patterns}->{$key};
	my $handler = $pattern->{handler};
	return $handler;
}

sub _get_regex {
	my $self = shift;
	my $key = shift;

	my $pattern = $self->{patterns}->{$key};
	my $regex = $pattern->{regex};
	return $regex;
}

sub init_patterns {
	my $self = shift;
	return ($self->_get_patterns('init'));
}

sub start_patterns {
	my $self = shift;
	return ($self->_active_pattern_filter('start'));
}

sub attr_patterns {
	my $self = shift;
	return ($self->_active_pattern_filter('attr'));
}

sub end_patterns {
	my $self = shift;
	return ($self->_active_pattern_filter('end'));
}

sub char_patterns {
	my $self = shift;
	return ($self->_active_pattern_filter('char'));
}

sub default_patterns {
	my $self = shift;
	return ($self->_active_pattern_filter('default'));
}

sub _active_pattern_filter {
	my $self = shift;
	my $type = shift;

	my %active = map {$_ => 1} @{$self->{active}};
	my @p = $self->_get_patterns($type);

	my @patterns = grep {$active{$_}} @p;
	return @patterns;
}

sub _get_patterns {
	my $self = shift;
	my $type = shift;

	my %p = %{$self->{patterns}};
	my @patterns = grep {$p{$_}->{type} eq $type} keys %p;
	return @patterns;
}

sub capture_event_data {
	my $self = shift;
	my ($type, $parser, $elm, %attr) = @_;

	my $depth = $parser->depth();
	my $orig_string = $parser->recognized_string();

	my $event_data = {
		type => $type,
		elm => $elm,
		attr => \%attr,
	};

	$self->{last_event} = $self->{current_event};
	$self->{current_event} = $event_data;
}

sub set_key {
	my $self = shift;
	my ($key, $value) = @_;
	$self->{key_val}->{$key} = $value;
}

sub set_active {
	my $self = shift;
	my @keys = @_;

	my %patterns = %{$self->{patterns}};

	@keys = grep {defined($patterns{$_})} @keys;
	$self->{active} = [@keys];
}

sub get_last_event {
	my $self = shift;
	return $self->{last_event};
}

sub get_current_event {
	my $self = shift;
	return $self->{current_event};
}

1;
