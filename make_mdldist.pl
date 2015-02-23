#!perl
use Path::Class;
use Digest::SHA1;
use Data::Dumper;
use Archive::Tar;

my $dist = shift or die 'directory required';

my $dist_dir = dir($dist);
my $name = $dist_dir->basename;
my $parent = $dist_dir->parent;

if (`cd $dist;git status --short|wc -l` > 0) {
    die 'git status is not clean';
}
chomp(my $revision = `cd $dist;git log -1 --pretty='%h'`);
my $product_id = get_php_constant("$dist/files/include.php", sprintf('%s_OSTORE_PRODUCT_ID', uc($name)));
my $version = get_php_constant("$dist/files/include.php", sprintf('%s_VERSION', uc($name)));
my $compliant_version = get_php_constant("$dist/files/include.php", sprintf('%s_COMPLIANT_VERSION', uc($name)));

my $distinfo = <<'END';
<?php
$distinfo = array(
END

$tar = Archive::Tar->new;
$Archive::Tar::DO_NOT_USE_PREFIX = 1;
my $dir = $dist_dir->subdir('files');
$dir->recurse(callback => sub {
        my $item = shift;
        -f $item or return;
        $item->basename =~ m{^\.} and return;
        (my $dest = "$item") =~ s{files/}{};
        my $sha1 = Digest::SHA1->new;
        $sha1->addfile($item->openr);
        $distinfo .= sprintf("'%s' => MODULE_REALDIR . '%s',\n", $sha1->hexdigest, file($dest)->relative($parent));
        $tar->add_data($item->relative($parent), do {local $/; $item->slurp});
    }
);
$distinfo .= ");\n";
$tar->add_data($dist_dir->file("/distinfo.php")->relative($parent), $distinfo);
$tar->write("$product_id-$name-$version-eccube-$compliant_version-$revision.tar.gz", COMPRESS_GZIP); 

sub get_php_constant {
    my ($file, $constant) = @_;
    my $result = `grep $constant $file|cut -d, -f2`;
    $result =~ s/['"); \r\n]+//g;
    return $result;
}
