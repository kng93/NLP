import re
import os
import sys
import HTMLParser
import NLPlib # For tagging
import itertools

def file_op(filename, op, str=''):
    try:
        file = open(filename, op)
        try:
            if op == "r":
                str = file.read()
            else:
                file.write(str)
        except IOError as e:
            sys.exit("I/O error({0}) for file {1}: {2}".format(e.errno, filename, e.strerror))
        except:
            sys.exit("Unexpected error for file {0}".format(filename), sys.exc_info()[0])
        finally:
            file.close()
    except IOError as e:
        sys.exit("I/O error({0}) for file {1}: {2}".format(e.errno, filename, e.strerror))
    except:
        sys.exit("Unexpected error for file {0}".format(filename), sys.exc_info()[0])
    
    return str

# Get rid of hashtags + username @ signs
def user_hash_repl(matchobj):
    return matchobj.group(2)
    
# Replace HTML character codes made of numbers
def html_num_repl(matchobj):
    return chr(int(matchobj.group(2)))
    
# Replace HTML character codes using abbrv
def html_type_repl(matchobj):
    return HTMLParser.HTMLParser().unescape(matchobj.group())

# Add newline to end of sentence
def add_newline(matchobj):
    return " "+matchobj.group(1)+matchobj.group(2)+" \n"
    
# Undo newline for abbreviations
def undo_abv(matchobj):
    return matchobj.group(1)+matchobj.group(3)+matchobj.group(4)
    
# Separate punctuation
def sep_punc(matchobj):
    return " "+matchobj.group(2)+" "+matchobj.group(3)

# Separate clitics
def sep_clitic(matchobj):
    return matchobj.group(1)+" "+matchobj.group(2)


def main(argv): 
    infile = ''
    outfile = ''
    
    if len(argv) != 3:
        sys.exit('Usage: run twtt.py <input file> <output file>')
    else:
        infile = argv[1]
        outfile = argv[2]
    
    # Get file information
    str = file_op(infile, "r")
    
    # Get rid of html tags + attributes
    str = re.sub(r'<[^>]*>', '', str) 
    
    # Replace html character codes with ASCII equivalent
    str = re.sub(r'(&#)([\d]+);', html_num_repl, str)
    str = re.sub(r'&[\w]+;', html_type_repl, str)
    
    #http://code.tutsplus.com/tutorials/8-regular-expressions-you-should-know--net-6149
    # All URLs are removed 
    str = re.sub(r'\b(https?:\/\/)?([\da-z\.-]+)\.([a-z]{2,3})([/\w\.-]*)', '', str, flags=re.I)
    
    # First character in usernames and hashtags removed
    str = re.sub(r'(@|#)([^\s]+)', user_hash_repl, str)
    
    # Separate tweets with a pipe symbol
    str = re.sub(r'\n+', '\n|\n', str)
    
    # Each sentence within a tweet is on its own line
    # Ending punctuation is padded by space
    # Note: Even if ending puncutation followed by lower case, treat as
    #   a sentence - tweets are often not gramatically correct
    str = re.sub(r'([\.\!\?]+)(?![a-zA-Z].)([\'\"]?)(\s*)', add_newline, str)
    # Split on semi-colons unless followed by digits (time) 
    str = re.sub(r'(:+)(?!\d)([\'\"]?)(\s*)', add_newline, str)
    
    # Separate normal punctuation by spaces
    # Exclude the period because already separated earlier (ending punctuation)
    # Dashes need extra space so won't split on hyphens
    str = re.sub(r'(\s*)(,+|\!+|\?+|;+|\"+|\(+|\)+|\$+'\
    '|\#+| -+|-+ )(\s*)', sep_punc, str)
    # Split on semi-colons unless followed by digits (time)
    str = re.sub(r'(\s*)(:+)(?!\d)(\s*)', sep_punc, str) 
    
    # Make it so abbreviations aren't on new lines
    # Also gets rid of spaces between abbreviation and period
    abvs = file_op('/u/cs401/Wordlists/pn_abbrev.english', "r")
    abvs = abvs + '\n' + file_op('/u/cs401/Wordlists/abbrev.english', "r")
    abvs = re.split(r'.\n+', abvs)
    str = re.sub(r'\b('+'|'.join(abvs)+'\b)(\s*)(.)(\s*)(\n)', undo_abv, str, flags=re.I)
    
    # Separate possessive apostrophe of plural
    str = re.sub(r'(\s*)(\')(\s+)', sep_punc, str)
    
    # Separate n't clitics
    str = re.sub(r'(\w+)(n\'t)', sep_clitic, str)
    
    # Separate other clitics
    str = re.sub(r'(\w*[^\WNn])(\'\w+)', sep_clitic, str)
    
    # Tag tokens
    tagger = NLPlib.NLPlib()
    str_list = re.split(r'[ \t\r\f\v]+', str)
    tag_list = tagger.tag(str_list)
    
    str = ''
    # Combine tokens with tags
    for val, tag in itertools.izip(str_list, tag_list):
        if val:
            str = str+val+'/'+tag+' '
    
    # Output the info to a file
    file_op(outfile, "w", str)

if __name__ == "__main__":
    sys.exit(main(sys.argv))
