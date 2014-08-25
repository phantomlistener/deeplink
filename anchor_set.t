use Template::AnchorSet;
use Test::More tests => 1;

ok( Template::AnchorSet::is_full_path('/root/something/foobar'), 'full path test');
ok( ! Template::AnchorSet::is_full_path('root/something/foobar'), 'negative full path test');
