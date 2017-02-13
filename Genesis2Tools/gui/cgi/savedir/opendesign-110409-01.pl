#!/usr/bin/perl
use strict;

    print '<script type="text/javascript"><!--'."\n";
    print "alert(\'hello');\n";
    print '//--></script>'."\n\n";


# Called from "index.htm" w/pre-selected QUERY_STRING parms for demos
# e.g. "newdesign=demo&file=../designs/demo/top.xml"

# Called from "choosedesign.pl" w/user-selected QUERY_STRING parms
# e.g. "newdesign=mydesign&file=../designs/tgt0/tgt0-baseline.xml"

print "calling utils\n";
my $do_result = do './utils.pl'; #  includes get_system_dependences(), get_input_parms()
#my $do_result = eval `cat ./utils.pl`; #  includes get_system_dependences(), get_input_parms()

#print "result is .$do_result.\n\n";


my %SYS = get_system_dependences();                # E.g. $SYS{GUI_HOME_DIR}
#print "hoodoo cgi dir is $SYS{CGI_DIR}\n"; exit;  # to test, uncomment this line.

# Unpack the parms: $INPUT{newdesign} and $INPUT{file}

my $parms = $ENV{QUERY_STRING};
my $testmode = 0;
if ($testmode) {
    print "Warning: standalone test mode\n";
    $parms = "newdesign=mydesign&file=..%2Fdesigns%2Ftgt0%2Ftgt0-baseline.xml";
}

my %INPUT = get_input_parms($parms);                    # from "do 'utils.pl'
#print "hoodoo newdesign is $INPUT{newdesign}\n"; exit; # to test, uncomment this line

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

if ($testmode) { print "\ncheckpoint 182\n"; }

my $newdesign = $INPUT{newdesign};  # E.g. "my_design_name"

# Build a javascript file that corresponds to the indicated xml file.

my $curdesign_xml = $INPUT{file};       # E.g. "../designs/tgt0/tgt0-baseline.xml"

if (! ($curdesign_xml =~ /(.*)(.xml)$/)) {
    my $alert = "Incorrect filename extension for \"$curdesign_xml\"; should be \".xml\"\n\n";
    print $error_header;
    print "<p>$alert\n";
    exit;    
}

# Path by which perl file finds the gui.
my $gui_dir = $SYS{GUI_HOME_DIR}; # E.g. "~steveri/smart_memories/Smart_design/ChipGen/gui";

my $curdesign_js = $1.".js"; # Root filename from split in above if-statement

my $cmd = "$gui_dir/xml-decoder/xml2js.csh $curdesign_xml > $curdesign_js";

my $DBG=1; if ($DBG) {
    print '<script type="text/javascript"><!--'."\n";
    print "alert(\'$cmd\');\n";
    print '//--></script>'."\n\n";
}

if ($testmode) { print "\ncheckpoint 900: $cmd\n"; }
#else {
    system($cmd);
#}

if ($testmode) { print "\ncheckpoint 1000\n"; }

#my $curdesign = $INPUT{file};       # E.g. "../designs/tgt0/tgt0-baseline.js"
my $curdesign = $curdesign_js;       # E.g. "../designs/tgt0/tgt0-baseline.js"

my $alert1 = "Input filename = \"$INPUT{file}\"";
my $alert2 = "Output filename = \"$curdesign\"";

$DBG+=0; if ($DBG) {
    print '<script type="text/javascript"><!--'."\n";
    print "alert(\'$alert1\');\n";
    print "alert(\'$alert2\');\n";
    print '//--></script>'."\n\n";
}

##############################################################################
# Build and jump to the indicated design.



# $curdesign = e.g. "../designs/tgt0/mydesign-<prevtimestamp>.js"

# my $design_basename = $newdesign; # E.g. "mydesign"
# my $design_id       = $newdesign; # (For updatedesign it's "$newdesign-$timestamp")


# Temp file will be "scratch/$design_id-<pid>"

# Create a new design based on the javascript pointed to by $curdesign;
# give it a new name $newdesign; place gui for design in $unique_id.php
my $newdesfname = $curdesign;

if ($testmode) { print "\ncheckpoint 2000\n"; }



##############################################################################
my $id = $newdesign;
my $php_basename = $id;

#if ($testmode) {exit;}

my $tmpfile = 
  build_new_php(
    $newdesfname,     # E.g. "
    $newdesign,       # E.g. "
    $php_basename,    # E.g. "
    "top"             # Always start at the top (module).
);

### #my $tmpfile = "tmp$$";           # $$ is process num e.g. "tmp4782"
### my $tmpfile = "$php_basename-$$"; # $$ is process num e.g. "mydesign-4782" or "mydesign-110212-133302-4028"
### 
### my $cmd = 
###        " sed 's|include *\"|include \"../|' $gui_dir/0-main-template.php ".
###        "|sed 's|../designs/tgt0/tgt0-baseline.js|$newdesfname|g'         ". # Replace default design base.
###        "|sed 's|CURRENT_DESIGN_FILENAME_HERE|$newdesfname|g'             ".
###        "|sed 's|NEW_DESIGN_BASENAME_HERE|$newdesign|g'                   ".
###        "|sed 's|CURRENT_BOOKMARK_HERE|top|g'                             ". # Begin at top level.
###        " > $gui_dir/scratch/$tmpfile.php                                 ";
### 
### #print "$cmd\n\n";
### #exit;
### 
### system($cmd);
### 
###



# Path (URL) by which the browser finds the gui.
my $gui_url = "$SYS{SERVER_URL}$SYS{GUI_HOME_URL}"; # E.g. "http://www-vlsi.stanford.edu/ig/"

print "<meta HTTP-EQUIV=\"REFRESH\" content=\"0; url=$gui_url/scratch/$tmpfile.php\">\n";

