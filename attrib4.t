use xmlparse;
use strict;
use Data::Dumper;

=cut

define
graft
inlay
section
slice
style
area
inject
implant
embed
enclose

=cut

my $string = <<HERE;
<root xmlns:anc="anchor">
	<blah style='anc:var=bl" anc:select="b1"' href="xyx"/>
<anc:define>
	<anc:select selectid="b1">
		<anc:prop xyz="X Y Z"/>
		<anc:prop abc="A B C"/>
	</anc:select>
</anc:define>
</root>
HERE

sub start {
	shift;
	print Dumper \@_;
	my $elm = shift;
	my %attrib = @_;
	foreach my $key (keys(%attrib)) {
		if ($attrib{$key} =~ /anc:/) {
			my $fragment = "<r $attrib{$key}/>";
			xmlparse($fragment, Start => \&attribstart);
		}
	}
}

xmlparse($string, Start => \&start);

sub attribstart {
	shift;
	shift;
	my %attrib = @_;
	foreach my $k (keys(%attrib)) {
		print "$k => $attrib{$k}\n" if ($k =~ /anc:(var|select)/);
	}
}

1;
