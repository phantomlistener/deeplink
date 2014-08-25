use File::Spec;

my $f1 = File::Spec->catfile('/tmp', 'a', 'b', './//c/');
my $f2 = File::Spec->catfile('/tmp/a/b/c');

my $rootdir = File::Spec->rootdir();

(-e $f1) ? warn "got $f1" : warn "NOT got $f1";
(-e $f2) ? warn "got $f2" : warn "NOT got $f2";


my $abs_path1 = File::Spec->rel2abs('a/b', '/');
my $abs_path2 = File::Spec->rel2abs('./a/b', '/');
my $abs_path3 = File::Spec->rel2abs('/a/b', '/');
my $abs_path4 = File::Spec->rel2abs('../../a/b', '/');

print "$abs_path1\n";
print "$abs_path2\n";
print "$abs_path3\n";
print "$abs_path4\n";
