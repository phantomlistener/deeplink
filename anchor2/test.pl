use Template::Anchor;
use Template::Anchor::Logger;
use Data::Dumper;
use strict;

my $file = shift @ARGV;

die "need file" unless -T $file;

Template::Anchor::Logger::info_level();

my $t = Template::Anchor->new(file => $file);

# print Dumper \$t if $t;

my $inst = $t->instance();
# print Dumper $inst;
print $inst->out() . "\n";

print Dumper \$inst->{template}->{content};
print Dumper \$inst->{template}->{text};
