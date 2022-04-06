#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM DATA_DIR
";

### Settings ###
my $NAME_SPACE = "http://purl.org/net/orthordf/hOP";

my $ORGANISM_PREFIX = "organism:";

### Analyze arguments ###
my %OPT;
getopts('', \%OPT);

if (@ARGV != 1) {
    print STDERR $USAGE;
    exit 1;
}
my ($DIR) = @ARGV;
if (-d $DIR) {
} else {
    die $USAGE;
}

my ($PROFILE_FILE, $ORGANISM_FILE, $GENE2ORTHOLOGS_FILE) = ("$DIR/profile", "$DIR/organism", "$DIR/humanGene");
if (-f $PROFILE_FILE and -f $ORGANISM_FILE and -f $GENE2ORTHOLOGS_FILE) {
} else {
    die $USAGE;
}

### Output header ###
print '@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .' . "\n";
print '@prefix dct: <http://purl.org/dc/terms/> .' . "\n";
print '@prefix orth: <http://purl.jp/bio/11/orth#> .' . "\n";
print '@prefix group: ', "<${NAME_SPACE}/group/> .\n";
print '@prefix organism: ', "<${NAME_SPACE}/organism/> .\n";
print '@prefix gene: ', "<http://identifiers.org/ncbigene/> .\n";
print "\n";

### Organism ###
my $N_ORGANISM = 0;
open(ORGANISM, $ORGANISM_FILE) || die;
while (<ORGANISM>) {
    my ($organism_no, $scientific_name, $simple_name) = split("\t", $_);

    print "organism:$organism_no\n";
    print "    a orth:Organism ;\n";
    print "    rdfs:label \"$simple_name\" ;\n";
    print "    dct:description \"$scientific_name\" ;\n";
    print "    dct:identifier $organism_no .\n";
    print "\n";

    $N_ORGANISM ++;
}
close(ORGANISM);

### Genes ###
my %MEMBER = ();
open(GENE2ORTHOLOGS, "$GENE2ORTHOLOGS_FILE") || die;
while (<GENE2ORTHOLOGS>) {
    chomp;
    my ($gene_name, $gene_id, @group_no) = split("\t", $_);
    if (@group_no == 0) {
	die;
    }

    print "gene:$gene_id\n";
    print "    a orth:Gene ;\n";
    print "    rdfs:label \"$gene_name\" ;\n";
    print "    dct:identifier $gene_id .\n";
    print "\n";

    for my $group_no (@group_no) {
	if (! defined $MEMBER{$group_no}) {
	    $MEMBER{$group_no} = [$gene_id];
	} else {
	    push @{$MEMBER{$group_no}}, $gene_id;
	}
    }
}
close(GENE2ORTHOLOGS);

### Profiles ###
my @ORTHOLOG_LABEL = ();
my @PROFILE = ();
open(PROFILE, $PROFILE_FILE) || die;
while (<PROFILE>) {
    chomp;
    my ($group_no, $label, $profile) = split("\t", $_);
    push @ORTHOLOG_LABEL, $label;

    my @x = split(" ", $profile);
    if (@x != $N_ORGANISM) {
	die;
    }
    push @PROFILE, \@x;
}
close(PROFILE);
if (@PROFILE != @ORTHOLOG_LABEL) {
    die;
}

for (my $i=0; $i<@PROFILE; $i++) {
    my $group_no = $i + 1;
    my @organism_uri = ();
    for (my $j=0; $j<@{$PROFILE[$i]}; $j++) {
	if ($PROFILE[$i][$j]) {
	    my $organism_no = $j + 1;
	    push @organism_uri, "organism:$organism_no";
	}
    }
    if (@organism_uri == 0) {
	print STDERR "WARNING: group $group_no has no member\n";
    }
    if (! defined $MEMBER{$group_no}) {
	print STDERR "No member of $group_no\n";
	exit;
    }
    my @member_uri = ();
    for my $member (@{$MEMBER{$group_no}}) {
	push @member_uri, "gene:$member";
    }
    print "group:$group_no\n";
    print "    a orth:OrthologGroup ;\n";
    print "    rdfs:label \"$ORTHOLOG_LABEL[$i]\" ;\n";
    print "    dct:identifier $group_no ;\n";
    print "    orth:member ", join(" ,\n                ", @member_uri), " ;\n";
    print "    orth:organism ", join(" ,\n                  ", @organism_uri), " .\n";
    print "\n";
}
