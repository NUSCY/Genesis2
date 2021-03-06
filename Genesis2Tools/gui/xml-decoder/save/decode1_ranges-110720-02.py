import re;
from decode_globals import input_lines;

def process_ranges(savelines, debug):
    """
        # Replace <Range>...</Range> block with "#RANG" comment.
        
        ####################################################
        # LIST example:
        # --------------------------------------------------
        #        <ParameterItem>
        #          <Doc>the value can be true or false</Doc>
        #          <Name>COND</Name>
        #
        #        #RANG COND = "false true"
        #        #  <Range>
        #        #    <List>false</List>
        #        #    <List>true</List>
        #        #  </Range>
        #          ...
        #        </ParameterItem>
        #
        ####################################################
        # MIN/MAX/STEP example:
        # --------------------------------------------------
        #        <ParameterItem>
        #          <Doc>Power supply</Doc>
        #          <Name>MILLIVOLTS</Name>
        #
        #        #RANG MILLIVOLTS = ",1000,12.5"
        #        #  <Range>
        #        #    <Min></Min>
        #        #    <Max>1000</Max>
        #        #    <Step>12.5</Step>
        #        #  </Range>
        #          ...
        #        </ParameterItem>
        #
        ####################################################
    """
        
    while (input_lines):
        line = input_lines[0];

        # BUG/TODO: should only do name search within the context of each ParameterItem

        # BUG/TODO: Depends on <Name> preceding <Range>
        #<Name>..</Name> => save parmname
        m = (re.compile("^\s*<Name>([^<]+)</Name>")).search(line);
        if m : parmname = m.group(1);

        # Empty <Range> tags get commented away.
        if (re.search("^\s*<Range>\S*</Range>", line)):
            savelines("#" + line); # Print and save for next pass
            input_lines.pop(0); # (pop(0) == shift);
            continue;

        # Not interested unless we find a "Range" block.
        elif (not (re.search("^\s*<Range>\S*$", line))) :
            savelines(line);    # Save lines in "output_lines" block for next pass.
            input_lines.pop(0); # (pop(0) == shift);
            continue;

        #<Range> => process Range block
        list = [];                               # Enumerated range e.g. "true false"
        min = ""; max = ""; step = "";           # Allowed range min, max, step

        #rangeblock = ["#" + line];  # Save lines until parm block is completely processed
        rangeblock = [];

        while (input_lines):
            line = input_lines[0]; input_lines.pop(0);     # (pop(0) == shift);

            # Bypass existing commented-out lines.
            if re.search(line, "^#"): rangeblock.append(line); continue;

            list_item = re.search("^\s*<List>([^<]*)</List>", line);
            min_item  = re.search("^\s*<Min>([^<]+)</Min>" , line);
            max_item  = re.search("^\s*<Max>([^<]+)</Max>" , line);
            step_item = re.search("^\s*<Step>([^<]+)</Step>" , line);

            #<List>..</List> => add to enum list
            #if ($line =~ /^\s*<List>([^<]*)<\/List>/) { push(@list, $1); }

            if (list_item):
                #print "found list item " + list_item.group(1);
                list.append(list_item.group(1));

            #<Min,Max,Step>..</Min,Max,Step> => save min,max,step
            elif (min_item):  min  =  min_item.group(1);
            elif (max_item):  max  =  max_item.group(1);
            elif (step_item): step = step_item.group(1);

            #</Range> => print range info; done
            elif (re.search("^\s*<\/Range>\s*$", line)):
            
                #print "listlen = "; print len(list);

                if (len(list) > 0) : range = " ".join(list);
                else               : range = min + "," + max + "," + step;

                tmp = "#RANG %s = \"%s\"\n" % (parmname, range); # E.g. "#RANG MILLIVOLTS = ",100,12.5"
                savelines(tmp);
                
                rangeblock.append("#" + line);           # perl: push @rangeblock, "#".$line;
                for tmp in rangeblock : savelines(tmp);
                break;                                   # perl: last

            # All processed lines become comments.
            rangeblock.append("#" + line);               # perl: push @rangeblock, "#".$line;

        # END while (input_lines)
    # END while (input_lines)

    savelines("\n");

# END def process_ranges()
