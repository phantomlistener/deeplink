package Template::AnchorSet;

=cut

This to group an anchor:

base path(s) where templat files live
relative or absolute path to template file
id for each file

method something like
add_template(id, path);
add_base_path(path);
search_paths()
parse()

add_base_path()
	check for existence of dir - warn on error

add_template(id, path)
	validate args
	check relative 
	check id - unique? - warn and continue
    circular refs? - warn and continue


search_paths()
    search through base dirs
    seek all templates; files with .html extension by default or other defined extension.
	parse after search is complete

parse() - activate parse of each added template

To include a template - needs to be by id, optionally can include prefix to apply
to all ids within included template - allows template to be included more than once
What about anc:include inside block that is repeated? What happens to ids uniqueness then?
ok - treated like any other id. - parse process absorbs/denormalises everything.

<anc:include id="foo" anc:prefix="bar"/>
<anc:include id="foo" anc:parentprefix="1"/> # default behaviour?
<anc:include id="foo" anc:noprefix="1"/>
<anc:templateid id="foo"/> # need a way to specify an id within a template

Parent prefix - concept of name space for included template's ids.
Each template will have its own set of ids.
A template may be included more than once by a single template. So you have an id clash problem.
So automatically prefix template with "parent id" of including block.
Or is this all just syntactic sugar? just go with optional anc:prefix to solve clash problems.
No prefix means no prefix.


Template may include it's own id - used in the search_paths method above
overridden by the explicit id used in add above?
<anc:template id="foo"/>

=cut

use File::Spec;
use Template::Anchor;

our $LOG;

sub new {
	my $class = shift;

	$LOG = Template::Anchor::get_logger();
	return bless {base_paths =>[], templates => {}}, $class;
}

sub add_base_path {
	my $self = shift;
	my $path = shift;
	
	if (is_full_path($path) && -d $path) {
		my $base_paths= $self->{base_paths};
		if (grep {$_ eq "$path"} @$base_paths) {
			$LOG->warn("$path already included");
			return undef; 
		}

		push @$base_paths, $path;
		return 1;
	}
	else {
		$LOG->warn("$path invalid");
		return undef
	}
}

sub add_template {
	my $self = shift;
	my $path = shift;
	my $id = shift;

	if (defined($self->{templates}->{$id})) {
		$LOG->warn("template id:$id already exists");
		return undef;
	}

	my @base_paths = @{$self->{base_paths}};
	# If no base paths configured assume all paths are absolute or relative to the root dir
	@base_paths = (File::Spec->rootdir()) unless @base_paths;

	foreach my $base_path (@base_paths) {
		my $abs_path = File::Spec->rel2abs($path, $base_path);

		# Parse Template
		my $template = Template::Anchor->new(file => $abs_path);
		if ($template) {
			$self->{templates}->{$id} = $template;
			# found template - break out of loop - do not check subsequent directories
			goto DONE;
		}
		else {
			$LOG->warn($LOG->last_msg());
		}
	}
DONE:
}

sub is_full_path {
	my $path = shift;
	my $rootdir = File::Spec->rootdir();

	return ($path =~ /^$rootdir/);
}

1;
