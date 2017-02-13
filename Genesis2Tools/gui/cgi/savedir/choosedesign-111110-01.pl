#!/usr/bin/perl
use strict;

my $testmode = 0;

my $id = 0;

#######################################################################################
# This file generates a form and sends the resulting user input of new and existing
# design names to "opendesign.pl" as parameters "newdesign" and "file" respectively
# -------------------------------------------------------------------------------------
# "What is your name (e.g. "john", "mary", "shenwen")?     => "&newdesign"
#
# "Which design would you like to browse/modify?           => "&file"
#    100720-1310-ofer.htm
#    100718-2245-kyle.htm
#    ...
# "SUBMIT"
# -------------------------------------------------------------------------------------
# (Note: opendesign.pl will remove spaces and such from "name" leaving only [a-zA-Z0-9]
# (Is that true!??)
#######################################################################################

print "Content-type: text/html\n\n";

my $do_result  = do './utils.pl';     #  includes get_system_dependences(), get_input_parms()
if ($testmode) { print embed_alert_script("called include file utils.pl...\n"); }


my %SYS = get_system_dependences(); # E.g. $SYS{GUI_HOME_DIR}
my $PBUTTON = "<img height=10 src=$SYS{GUI_HOME_URL}/images/plusbutton.png />";
my $MBUTTON = "<img height=10 src=$SYS{GUI_HOME_URL}/images/minusbutton.png />";

my $DBG=0; if ($ENV{QUERY_STRING} =~ /DEBUG=true/) { $DBG = 1; }

my $qs = $ENV{QUERY_STRING};
my %INPUT = get_input_parms($qs);

my $default_design = "NO_DEFAULT"; # No default design!  Any nonsense phrase turns it off.

if ($INPUT{DELETE}) {

    # Delete "$delete" and reopen design "$design".
    my $delete = $INPUT{"DELETE"};
    my $design = $INPUT{"DESIGN"};

    # To delete, simply rename w/extension "deleteme"
    my $cmd = "mv $delete $delete.deleteme";
    my $err = `$cmd`;

    # Quick check to see if the delete part worked
    # my $cmd = "ls -l $delete"; my $err = `$cmd`; print embed_alert_script($err);

    $default_design = $design;
}

#print embed_alert_script("DEBUG=$DBG");

print_script_block(); print "\n";
print_style_block(); print "\n";
print build_title_and_intro();
print_form();

#####################################################################################################
sub print_script_block {
    my @script_block =
        (
         '<script type="text/javascript"><!--',

         'var currently_active_popuptable;',
         'function ToggleTable(id) {',
         '    var e = document.getElementById("designs_" + id);',
         '    var b = document.getElementById("button_"  + id);',
         '    if (e.style.display == "") { e.style.display = "none"; b.innerHTML = "+ " + id; }',
         '    else                       { e.style.display = "";     b.innerHTML = "- " + id; }',
         '}',

         'function showpopup(i) { ',
         '  var t = currently_active_popuptable;',
         '  if (t) { t.style.display="none"; }',
         '  t = document.getElementById("table"+i); t.style.display="inline"; ',
         '  currently_active_popuptable = t;',
         '}',

         'function visit_it(filename) {',
         '  // "newdesign" has already been set by user; we need to fill in "file"',
#       #'  alert("i think newdesign= " + document.forms[0]["newdesign"].value);',
         '  document.forms[0]["file"].value = filename;',
         '  document.forms[0].submit();',
         '}',

         'function delete_it(design,filename) {',
#       #'  alert("ima gonna delete " + filename); alert("and reopen design " + design); alert("but how?");',
         '  var update = "choosedesign.pl?DELETE="+filename+"&DESIGN="+design;',
#       #'  alert(update);',
         '  window.location = update;',
         '}',

         'function killtable(t) { document.getElementById(t).style.display="none"; }',
                       
         '//--></script>',
	'',
    );
    print join("\n",@script_block);
}

sub print_style_block {
    my @style_block =
        (
         '<style type="text/css">',
         '  button {width:100%; text-align:left}',
         '',
         '  .popupbutton:hover  { background-color:#e7d19a; }',
         '',
         '  .popuptable {',
         '     display:none; position:absolute; z-index:1; width:100%; ',
         '     border:1px solid white; border-width: 0px 40px 0px 0px; ',
         '     background-color:#e5eecc; font-size:small;',
         '  }',
	'</style>',
        ''
    );
    print join("\n",@style_block);
}

sub build_title_and_intro {

    my @intro = (
      "<head><title>Interactive Chip Generator powered by Genesis</title></head>",
      "",
      "<h2>Welcome to the Interactive Chip Generator!</h2>",
      "",
     #"<table style='width:520'><tr><td>",
      "<table><tr><td>",
      "The Interactive Chip Generator (ICG) allows you to take an existing design base",
      "and quickly modify it to produce a new design, customized for your specific needs.",
      "",
      "<p>First, choose a base name for your design.  This can be any combination of",
      "letters, numbers and hyphens, e.g. \"mydesign\" or \"smartmem-bob\".",
      "The Interactive Chip Generator will append a timestamp to the base",
      "name to create a unique version each time you save your design,",
      "e.g. \"mydesign-100815-134333\" would be the version of \"mydesign\"",
      "written on August 15, 2010 at 33 seconds after 1:43pm.",
      "</td></tr></table>",
      "",
      "<br />\n",
      "",
    );
    return join("\n", @intro);
}


sub print_form {

    my %SYS = get_system_dependences();                # E.g. $SYS{GUI_HOME_DIR}
    my $opendesign = "$SYS{CGI_URL}/opendesign.pl";    # E.g. "/cgi-bin/genesis/opendesign.pl"
    if ($testmode) { print embed_alert_script("opendesign = $opendesign\n"); }
    if ($testmode) {
	print "<form method=\"get\" action=\"$SYS{CGI_URL}/foo.htm\">\n\n";
    }
    else {
	print "<form method=\"get\" action=\"$opendesign\">\n\n";
	print "  <input type=hidden name=file />\n\n",     # Placeholder to be filled in by script.
    }

    print_base_name_request();
    print_choose_existing_design();

    print "\n\n</table>\n";
    print "<div style='text-align:right'><input type='checkbox' name='DBG' value=1>(debug)</input></div>";
    print "</form>\n";
    print "<a href=editdesigns.pl><b>Click here to edit the design database (add, subtract and edit designs).</b></a>",
}

sub print_base_name_request {

    my @instructions = (
      "<table><tr><td>",
      "  <b>Base name for your new design</b> (e.g. \"john\" or \"mary17\" or \"memtile7\"): ",
      "  <input type=\"text\" name=\"newdesign\" value=\"mydesign\"><br />",
      "",
      "  <p>",
      "  <b>Now, choose an existing design as a base for your new design.</b>",
      "  What existing design would you like to start from?",
      "",
      "</td></tr></table>",
      "",
    );

    print join("\n", @instructions);
}

sub print_choose_existing_design {

    print '<table style="border:solid white; border-left-width:100">'."\n";

    my $do_result  = do './getdesigns.pl';     #  contains subroutine "getdesigns()"

    my $designs = getdesigns($DBG);
    foreach my $k (sort keys(%$designs)) {
	
	print "  <!-- Button for design \"$k\" -->\n\n";

	print "  <tr><td><button type=button id=\"button_$k\" onclick=\"ToggleTable('$k');\">\n";
	print "    + $k\n";
	print "  </button></td></tr>\n";

	# Hide all but "default" list of config files.
	my $display = ($k eq $default_design) ? '' : ' style="display:none"';

	print "  <tr id=\"designs_$k\"$display><td>\n";

	my @list = split(" ", $designs->{$k});

        my $source_dir = `cat ../designs/$k/__SOURCEDIR__`;  # E.g. "/home/steveri/designs/mydesign\n"
        chomp $source_dir;                                   # Off with its...tail...!
#      #print embed_alert_script("source dir for $k is $source_dir");

	foreach my $design (@list) {
	    my $fullpath = "../designs/$k/$design";
            my $ls = "ls -l $source_dir/$design";    #print embed_alert_script($ls);
            my $ls_out = `$ls`;                      #print embed_alert_script($ls_out);

            my $deletable = (-e "$source_dir/$design") ? 0 : 1;

	    # Skip "old", "save" directories.
	    if ($fullpath =~ /designs.old/) { next; }
	    if ($fullpath =~ /designs.save/) { next; }

	    my $selected = "";

	    print "    <div  style='position:relative; padding:0px 20px'>\n";
            print "      <button type=button id=button$id onclick='showpopup($id)'>\n";
            print "        <tt>$design</tt>\n";
            print "      </button>\n";
            print "      <br />\n";
            print_buttons($id,$k,$fullpath,$deletable);
	    print "    </div>\n";

            $id++;
	}
        print "  </td></tr>\n\n";
    }
}

sub print_buttons {
    my $id        = shift @_;
    my $chipgen   = shift @_;
    my $fullpath  = shift @_;
    my $deletable = shift @_;

#    if ($deletable) { print embed_alert_script("$fullpath is deletable"); }
#    else            { print embed_alert_script("$fullpath is not deletable"); }

    print "    <table class=popuptable id=table$id>\n";
    print "      <tr><td onclick='visit_it(\"$fullpath\")' class=popupbutton>$PBUTTON Visit this design</td></tr>\n";

    if ($deletable) {
        print "      <tr><td onclick='delete_it(\"$chipgen\",\"$fullpath\")' class=popupbutton>$MBUTTON Delete this design</td></tr>\n";
    }

    print "      <tr><td onclick=killtable('table$id') class=popupbutton style=color:red><center><b>Cancel</b></center></td></tr>\n";
    print "    </table>\n";
}

############################################################################
# NOTES: Web resources for CGI scripts:  Google "cgi script example"
#   http://www.perlfect.com/articles/url_decoding.shtml
#   http://www.it.bton.ac.uk/~mas/mas/courses/html/html3.html
#   http://www.jmarshall.com/easy/cgi/
#   http://www.comptechdoc.org/independent/web/cgi/cgimanual/cgiexample.html
############################################################################