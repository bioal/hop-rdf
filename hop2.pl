#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Std;
my $PROGRAM = basename $0;
my $USAGE=
"Usage: $PROGRAM DATA_DIR
";

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

### Settings ###
my ($PROFILE_FILE, $ORGANISM_FILE, $GENE2ORTHOLOGS_FILE, $TIME_TREE_FILE) = ("$DIR/profile", "$DIR/organism", "$DIR/humanGene", "$DIR/time_tree");

if (-f $PROFILE_FILE && -f $ORGANISM_FILE && -f $GENE2ORTHOLOGS_FILE) {
} else {
    die $USAGE;
}

my %TIME = ();
if (-f $TIME_TREE_FILE) {
    open(TIME_TREE, $TIME_TREE_FILE) || die;
    while (<TIME_TREE>) {
	chomp;
	my ($group_no, $time) = split("\t", $_);
	if ($time) {
	    $TIME{$group_no} = $time;
	}
    }
    close(TIME_TREE);
}

my $NAME_SPACE = "http://purl.org/net/orthordf/hOP/";

### Output header ###
print '@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .' . "\n";
print '@prefix dct: <http://purl.org/dc/terms/> .' . "\n";
print '@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .' . "\n";
print '@prefix ncbigene: ', "<http://identifiers.org/ncbigene/> .\n";
print '@prefix orth: <http://purl.org/net/orth#> .' . "\n";
print '@prefix hop: ', "<${NAME_SPACE}ontology#> .\n";
print '@prefix group: ', "<${NAME_SPACE}group/> .\n";
print '@prefix organism: ', "<${NAME_SPACE}organism/> .\n";
print '@prefix branch: ', "<${NAME_SPACE}branch/> .\n";
print "\n";

print "<$NAME_SPACE>\n";
print "    a orth:OrthologyDataset ;\n";
print "    dct:title \"Human orthogroup phylogenetic (hOP) profiles\" ;\n";
print "    dct:source <http://web.stanford.edu/group/meyerlab/hOPMAPServer/index.html> ;\n";
print "    dct:description \"RDF version of human orthogroup phylogenetic (hOP) profiles is created from the original database.\" ;\n";
print "    dct:created \"", current_date_time(), "\"^^xsd:dateTime .\n";
print "\n";

### Organism to Turtle ###
my $N_ORGANISM = organism_to_ttl($ORGANISM_FILE);

### Genes to Turtle ###
my %MEMBER = ();
open(GENE2ORTHOLOGS, "$GENE2ORTHOLOGS_FILE") || die;
while (<GENE2ORTHOLOGS>) {
    chomp;
    my ($gene_name, $gene_id, @group_no) = split("\t", $_);

    print_gene_ttl($gene_id, $gene_name);

    if (@group_no == 0) {
	die;
    }
    for my $group_no (@group_no) {
	if (! defined $MEMBER{$group_no}) {
	    $MEMBER{$group_no} = [$gene_id];
	} else {
	    push @{$MEMBER{$group_no}}, $gene_id;
	}
    }
}
close(GENE2ORTHOLOGS);

### Profiles to Turtle ###
open(PROFILE, $PROFILE_FILE) || die;
while (<PROFILE>) {
    chomp;
    my ($group_no, $label, $profile) = split("\t", $_);

    print_profile($group_no, $label, $profile, \%MEMBER);
}
close(PROFILE);

################################################################################
### Functions ##################################################################
################################################################################
sub organism_to_ttl {
    my ($file) = @_;

    my $n_organism = 0;

    open(ORGANISM, $file) || die;
    while (<ORGANISM>) {
	my @f = split("\t", $_);
	if (@f != 6) {
	    die;
	}
	my ($organism_no, $scientific_name, $common_name, $taxon) = @f[0,1,2,4];

	print "organism:$organism_no\n";
	print "    a orth:Organism ;\n";
	print "    dct:identifier $organism_no ;\n";
	print "    rdfs:label \"$scientific_name\" ;\n";
    my $branch_no;
    if ($organism_no <= 25) {
        $branch_no = 1;
    } elsif ($organism_no <= 34) {
        $branch_no = 2;
    } elsif ($organism_no <= 37) {
        $branch_no = 3;
    } elsif ($organism_no <= 41) {
        $branch_no = 4;
    } elsif ($organism_no <= 54) {
        $branch_no = 5;
    } elsif ($organism_no <= 60) {
        $branch_no = 6;
    } elsif ($organism_no <= 62) {
        $branch_no = 7;
    } elsif ($organism_no <= 64) {
        $branch_no = 8;
    } elsif ($organism_no <= 67) {
        $branch_no = 9;
    } elsif ($organism_no <= 124) {
        $branch_no = 10;
    } elsif ($organism_no <= 129) {
        $branch_no = 11;
    } elsif ($organism_no <= 147) {
        $branch_no = 12;
    } else {
        $branch_no = 13;
    }
    print "    hop:branch branch:$branch_no ;\n";
	if ($TIME{$organism_no}) {
	    print "    hop:branchTimeMya \"$TIME{$organism_no}\"^^xsd:decimal ;\n";
	}
	print "    dct:description \"$common_name\" ;\n";
	print "    rdfs:comment \"$taxon\" .\n";
	print "\n";

	$n_organism ++;
    }
    close(ORGANISM);

    print "branch:1 a hop:Branch ;\n";
	print "    dct:identifier 1 ;\n";
    print "    rdfs:label \"Mammals\".\n";
	print "\n";

    print "branch:2 a hop:Branch ;\n";
	print "    dct:identifier 2 ;\n";
    print "    rdfs:label \"Other vertebrates\".\n";
	print "\n";

    print "branch:3 a hop:Branch ;\n";
	print "    dct:identifier 3 ;\n";
    print "    rdfs:label \"Lancelets/tunicates\".\n";
	print "\n";

    print "branch:4 a hop:Branch ;\n";
	print "    dct:identifier 4 ;\n";
    print "    rdfs:label \"Echinoderms/hemichordata\".\n";
	print "\n";

    print "branch:5 a hop:Branch ;\n";
	print "    dct:identifier 5 ;\n";
    print "    rdfs:label \"Arthropods\".\n";
	print "\n";

    print "branch:6 a hop:Branch ;\n";
	print "    dct:identifier 6 ;\n";
    print "    rdfs:label \"Nematodes\".\n";
	print "\n";

    print "branch:7 a hop:Branch ;\n";
	print "    dct:identifier 7 ;\n";
    print "    rdfs:label \"Cnidaria\".\n";
	print "\n";

    print "branch:8 a hop:Branch ;\n";
	print "    dct:identifier 8 ;\n";
    print "    rdfs:label \"Sponge/Placozoa\".\n";
	print "\n";

    print "branch:9 a hop:Branch ;\n";
	print "    dct:identifier 9 ;\n";
    print "    rdfs:label \"Choanoflagellates\".\n";
	print "\n";

    print "branch:10 a hop:Branch ;\n";
	print "    dct:identifier 10 ;\n";
    print "    rdfs:label \"Fungi\".\n";
	print "\n";

    print "branch:11 a hop:Branch ;\n";
	print "    dct:identifier 11 ;\n";
    print "    rdfs:label \"Amoebozoa\".\n";
	print "\n";

    print "branch:12 a hop:Branch ;\n";
	print "    dct:identifier 12 ;\n";
    print "    rdfs:label \"Plantae\".\n";
	print "\n";

    print "branch:13 a hop:Branch ;\n";
	print "    dct:identifier 13 ;\n";
    print "    rdfs:label \"Other protists\".\n";
	print "\n";

    return $n_organism;
}

sub print_gene_ttl {
    my ($gene_id, $gene_name) = @_;

    print "ncbigene:$gene_id\n";
    print "    a orth:Gene ;\n";
    print "    dct:identifier $gene_id ;\n";
    print "    rdfs:label \"$gene_name\" .\n";
    print "\n";
}

sub print_profile {
    my ($group_no, $label, $profile, $r_member) = @_;

    my @x = split(" ", $profile);
    if (@x != $N_ORGANISM) {
	die;
    }
    my @organism_uri = ();
    for (my $j=0; $j<@x; $j++) {
	if ($x[$j]) {
	    my $organism_no = $j + 1;
	    push @organism_uri, "organism:$organism_no";
	}
    }
    if (@organism_uri == 0) {
	print STDERR "WARNING: group $group_no has no member\n";
    }

    if (! defined ${$r_member}{$group_no}) {
	print STDERR "No member of $group_no\n";
	exit;
    }
    my @member_uri = ();
    for my $member (@{${$r_member}{$group_no}}) {
	push @member_uri, "ncbigene:$member";
    }

    print "group:$group_no\n";
    print "    a orth:OrthologsCluster ;\n";
    print "    orth:inDataset <$NAME_SPACE> ;\n";
    print "    dct:identifier $group_no ;\n";
    print "    rdfs:label \"$label\" ;\n";
    print "    orth:hasHomologousMember ", join(" ,\n                ", @member_uri), " ;\n";
    print "    orth:organism ", join(" ,\n                  ", @organism_uri), " .\n";
    print "\n";
}

sub current_date_time {

    my $date_time = `date +%FT%T%:z`;
    chomp($date_time);
    unless ($date_time =~ /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d/) {
	die;
    }

    return $date_time;
}
