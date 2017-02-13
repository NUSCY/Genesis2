#!/usr/bin/perl

# Called from "index.htm" w/pre-selected QUERY_STRING parms for demos
# e.g. "newdesign=demo&file=../designs/demo/top.xml"

# Called from "choosedesign.pl" w/user-selected QUERY_STRING parms
# e.g. "newdesign=mydesign&file=../designs/tgt0/tgt0-baseline.xml"

# First, unpack the parms: $INPUT{newdesign} and $INPUT{file}

my $parms = $ENV{QUERY_STRING};
my @fv_pairs = split /\&/ , $parms;
foreach $pair (@fv_pairs) {
    if($pair=~m/([^=]+)=(.*)/) {                            # E.g. "(newdesign)=(my_design_name)"
	$field = $1; $value = $2;
        $value =~ s/\+/ /g;                                 # Change plus sign to blank space.
        $value =~ s/%([\dA-Fa-f]{2})/pack("C", hex($1))/eg; # Change e.g. "%2F" to "/"
	$INPUT{$field}=$value;                              # E.g. $INPUT{newdesign) = "my_design_name"
    }
}


print "Content-type: text/html\n\n";

my $error_header = "<head><title>ChipGen Error</title></head><h1>ChipGen Error</h1>\n\n";
my $dbg_msg = "<p><i>Found newdesign \"$INPUT{newdesign}\"<br />Found filename \"$INPUT{file}\"</i><br /><br />\n\n";

# Forgot newdesign name?
if ($INPUT{newdesign} eq "") {
    print $error_header;
    print "<p>Oops, you forgot to choose a new design name.<br />\n";
    print "Please use your browser's BACK button to go back and try again.\n";
    print $dbg_msg;
    exit;
}
# Invalid newdesign name?
elsif (! ($INPUT{newdesign} =~ /^[-a-zA-Z0-9_]+$/)) {
    print $error_header;
    print "<p>illegal name \"$INPUT{newdesign}\"<br />\n";
    print "must have letters and numbers ONLY, no spaces (e.g. \"john\" or \"mary17\")<br />\n";
    print "use BACK button on browser to try again.<br />\n";
    print $dbg_msg;
    exit;
}
# Forgot to choose an input design?
elsif ($INPUT{file} eq "") {
    print $error_header;
    print "<p>Oops, you forgot to choose an existing base design.<br />\n";
    print "Please use your browser's BACK button to go back and try again.\n";
    print $dbg_msg;
    exit;
}

my $newdesign = $INPUT{newdesign};  # E.g. "my_design_name"

# Build a javascript file that corresponds to the indicated xml file.

my $curdesign_xml = $INPUT{file};       # E.g. "../designs/tgt0/tgt0-baseline.xml"

if (! $curdesign_xml =~ /(.*)(.xml)$/) {
    my alert = "incorrect filename extension for \"$s\"; should be \".xml\"\n\n";
    print '<script type="text/javascript"><!--'."\n";
    print "alert(\'$alert\');\n";
    print '//--></script>'."\n\n";
    exit;    
}

my $curdesign_js = $1.".js";

my $curdesign = $curdesign_js;       # E.g. "../designs/tgt0/tgt0-baseline.js"

my $cmd = 
    "/home/steveri/smart_memories/Smart_design/ChipGen/gui/xml-decoder/xml2js.csh ".
    "$curdesign_xml > $curdesign_js";

my $DBG=0; if ($DBG) {
    print '<script type="text/javascript"><!--'."\n";
    print "alert(\'$cmd\');\n";
    print '//--></script>'."\n\n";
    exit;
}


# $decodedir/xml2js.csh $newdesign.xml > $newdesign.js

my $curdesign = $INPUT{file};       # E.g. "../designs/tgt0/tgt0-baseline.js"




my $alert1 = "Input filename = \"$INPUT{file}\"";
my $alert2 = "Output filename = \"$curdesign\"";

$DBG=0; if ($DBG) {
    print '<script type="text/javascript"><!--'."\n";
    print "alert(\'$alert1\');\n";
    print "alert(\'$alert2\');\n";
    print '//--></script>'."\n\n";
}

# Build and jump to the indicated design.

my $gui = "~steveri/smart_memories/Smart_design/ChipGen/gui";
my $cmd = 
       " sed 's|include *\"|include \"../|' $gui/0-main-template.php ".
       "|sed 's|../designs/tgt0/tgt0-baseline.js|$curdesign|g'       ". # Replace default design base.
       "|sed 's|CURRENT_DESIGN_FILENAME_HERE|$curdesign|g'           ".
       "|sed 's|NEW_DESIGN_BASENAME_HERE|$newdesign|g'               ".
       "|sed 's|CURRENT_BOOKMARK_HERE|top|g'                         ". # Begin at top level.
       " > $gui/scratch/tmp.php                                      ";

system($cmd);

print '<meta HTTP-EQUIV="REFRESH" content="0; url=http://www-vlsi.stanford.edu/ig/scratch/tmp.php">'."\n";
