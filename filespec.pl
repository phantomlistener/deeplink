use File::Spec;
use URI::file;
use strict;

warn File::Spec->catfile('a', 'b');

my $u1 = URI::file->new('foo/bar');

warn $u1->file();

my $u2 = URI::file->new('foo/bar');

warn $u1->new_abs();
