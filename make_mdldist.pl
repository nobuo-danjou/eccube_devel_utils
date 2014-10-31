#!perl
use Path::Class;
use Digest::SHA1;
use Data::Dumper;
use Archive::Tar;

my $dist = shift or die 'directory required';

my $dist_dir = dir($dist);
my $name = $dist_dir->basename;
my $parent = $dist_dir->parent;

my $distinfo = <<'END';
<?php
$distinfo = array(
END

$tar = Archive::Tar->new;
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
$tar->write("$name.tar.gz", COMPRESS_GZIP); 
