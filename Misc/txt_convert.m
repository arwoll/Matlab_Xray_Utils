% A script to take a linefed text file from *nix-land to Word.  
% The problem? When word imports text, it interprets all linefeeds as
% carriage returns.  Since linefeeds are used to indicate line wraps in
% unix -- or at least in EMACS and often for regular text files, word sees
% these files as having hard returns at the end of each line. Reformatting
% has become a royal pain. The following takes a text file and concatenates
% adjacent non-empty lines.  The output is word friendly.
%
% Note that you'd think this could be done quickly with sed.
% Unfortunately, sed uses basic or extended, but not advanced regular
% expressions, and hence does not recognize \r or \n.  As far as I can tell
% this means it cannot match a carriage return or newline...

a = fgetl(infile);
while ischar(a)
    % convert, write
    if length(a) == 0
        fprintf(outfile, '\r');
        a = fgetl(infile);
        continue
    end
    b = fgetl(infile);
    if length(b)>0
        a = [a ' ' b];
    else
        fprintf(outfile,'%s\r\r', a);
        a = fgetl(infile);
    end
end
fclose(infile);
fclose(outfile);
