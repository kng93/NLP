import re
import os
import sys
import argparse
import time # Checking time

# Deals with file operations (error checking)
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


# Checks the name of each file and returns the overall name for the argument
def check_set_name(file, type, num, semi, name):
    if num == -1:
        arg_num = "Last argument"
    else:
        arg_num = "Argument "+str(num)

    file_ext_idx = file.rfind(".")
    dir_idx = file.rfind("/")
    dir_idx = 0 if dir_idx == -1 else dir_idx+1 # +1 to ignore the first slash
    if file_ext_idx < 0:
        sys.exit(arg_num+" is not a file")
    elif file[file_ext_idx:] != type:
        sys.exit(arg_num+" is not a "+type+" file")
    
    if semi >= 0:
        return name
    else:
        return name+file[dir_idx:file_ext_idx]

# Gets the list of class names from the arguments
def get_classes(argv):
    class_list = []
    idx = 1
    for arg in argv:
        semi = arg.find(":")
        class_name = ''
        if semi >= 0:
            class_name = arg[:semi]
            arg = arg[semi+1:]
        
        plus = arg.find("+")
        while plus >= 0:
            class_name = check_set_name(arg[:plus], ".twt", idx, semi, class_name)
            arg = arg[plus+1:]
            plus = arg.find("+")
        
        class_name = check_set_name(arg, ".twt", idx, semi, class_name)
        class_list.append(class_name)
        
        # Index for the current argument value
        idx += 1
    
    return class_list

# Create a pattern to match a list from a file
def get_pattern(filename):
    file_list = file_op(filename, "r")
    file_list = re.split(r"\n+", file_list)
    pat = re.compile(r"\s("+"|".join(filter(None, file_list))+")/", re.I)

    return pat

# Feature 1 - count first person pronouns
def fp_pronoun(str):
    lst = re.findall(r"\b(I|me|my|mine|we|us|our|ours)/", str, re.I)
    return len(lst)

# Feature 2 - count second person pronouns
def sp_pronoun(str):
    lst = re.findall(r"\b(you|your|yours|u|ur|urs)/", str, re.I)
    return len(lst)

# Feature 3 - count third person pronouns
def tp_pronoun(str):
    lst = re.findall((r"\b(he|him|his|she|her|hers|it|its|"
    "they|them|their|theirs)/"), str, re.I)
    return len(lst)

# Feature 4 - count coordinating conjunctions
def coord_conj(tags):
    return tags.count("/CC")

# Feature 5 - count past-tense verbs
def past_verb(tags):
    return tags.count("/VBD")
    
# Feature 6 - count future-tense verbs
def future_verb(str):
    lst = re.findall((r"\b((going/VBG to/TO [\w]+/VB\b)|(('ll|will|gonna)/))"), str, re.I)
    return len(lst)

# Feature 7 - count past-tense verbs
def comma(tags):
    return tags.count("/,")

# Feature 8 - count colons + semi-colons
def colon(str):
    lst = re.findall(r"(:|;)/", str, re.I)
    return len(lst)

# Feature 9 - count dashes
def dash(str):
    lst = re.findall(r"(-+)/", str, re.I)
    return len(lst)

# Feature 10 - count parentheses
def parentheses(tags):
    return tags.count(r"/(")+tags.count(r"/)")

# Feature 11 - count ellipses
def ellipses(str):
    lst = re.findall(r"\.\.+/", str, re.I)
    return len(lst)

# Feature 12 - count common nouns
def cmn_noun(tags):
    return tags.count("/NN")+tags.count("/NNS")
    
# Feature 13 - count proper nouns
def prop_noun(tags):
    return tags.count("/NNP")+tags.count("/NNPS")

# Feature 14 - count adverbs
def adverb(tags):
    return tags.count("/RB")+tags.count("/RBR")+tags.count("/RBS")

# Feature 15 - count wh-words
def wh_word(tags):
    return tags.count("/WDT")+tags.count("/WP")+tags.count("/WP$")+\
    tags.count("/WRB")

# ]Feature 16 - count modern slang acroynms
def slang(str, pattern):
    lst = re.findall(pattern, str)
    return len(lst)
    
# Feature 17 - count words all in upper case (at least 2 letters long)
def up_case(str):
    lst = re.findall(r"[A-Z][A-Z]+/", str)
    return len(lst)

# Feature 18-20 - Return total sentences, words, and characters given a string
def counter(str, pattern):
    total_words = 0
    total_chars = 0
    total_sent = 0
    
    # Get rid of the tags, tweet separators, and punctuation
    str_list = re.sub(pattern, '', str)
    str_list = re.sub(r"(\n\|\n)", '\n', str_list) 
    str_list = re.sub(r"(\.|,|\!|\?|;|:|\"|\(|\)|\$|\#|-|'\
    '\||\\|\'|/|&)", '', str_list)
    str_list = re.split(r'\n+', str_list)
    total_sent = len(str_list)
    
    # Iterate over sentences
    for sent in str_list:
        words = re.split(r"\s+", sent)
        total_words += len(words)
        
        # Iterate over words
        for word in words:
            total_chars += len(word)
    
    return [total_sent, total_words, total_chars]


def main(argv): 
    infile = ''
    outfile = ''
    numlim = -1
    list_classes = []
    
    if len(argv) < 3:
        sys.exit("Usage: run buildarff.py <twt file>+ <arff file>")
    else:
        argv = argv[1:]
        
        # Get the class tweet limit
        if argv[0][0] == '-':
            numlim = int(argv[0][1:])
            argv = argv[1:]
    
    # Check last file is an .arff file
    outfile = argv[-1]
    check_set_name(outfile, ".arff", -1, -1, '')
    
    start = time.time()

    # Initialize variables, get patterns
    argv = argv[:-1]
    idx = 0 # Idx for the current argument
    pattern = re.compile(r"/[A-Z$#.,:\(\)\"]{1,4}")
    s_pat = get_pattern("/u/cs401/Wordlists/Slang")
    fp_pat = get_pattern("/u/cs401/Wordlists/First-person")
    sp_pat = get_pattern("/u/cs401/Wordlists/Second-person")
    tp_pat = get_pattern("/u/cs401/Wordlists/Third-person")
    
    class_list = get_classes(argv)
    # Open file to write to
    try:
        file_out = open(outfile, "w")
        file_out.write("@relation tweets\n\n")
        file_out.write(file_op("./arffrelation", "r"))
        file_out.write("@attribute class {"+",".join(class_list)+"}\n")
        file_out.write("\n\n@data\n")
    except IOError as e:
        sys.exit("I/O error({0}) for file {1}: {2}".format(e.errno, outfile, e.strerror))
    except:
        sys.exit("Unexpected error for file {0}".format(outfile), sys.exc_info()[0])
    
    # Iterate over argv (now the list of twt files)
    for arg in argv:
        # Separate the filenames into a list if multiple in an argument
        arg = arg[arg.find(":")+1:]
        plus = arg.find("+")
        file_list = []
        while plus >= 0:
            file_list.append(arg[:plus])
            arg = arg[plus+1:]
            plus = arg.find("+")
        
        file_list.append(arg)
        tweet_list = []
        # Get the info from the files
        for twt in file_list:
            val = file_op(twt, "r") 
            split_tweet = re.split("\n\|\n", val)
            if (numlim >= 0):
                split_tweet = split_tweet[:numlim]
            tweet_list += split_tweet
        
        for tweet in tweet_list:
            # Get the list of tags
            tags = re.findall(pattern, tweet)
            
            # Compile the feature list
            feature_list = []
            feature_list.append(fp_pronoun(tweet)) # Count first person pronouns
            feature_list.append(sp_pronoun(tweet)) # Count second person pronouns
            feature_list.append(tp_pronoun(tweet)) # Count third person pronouns
            feature_list.append(coord_conj(tags)) # Count coordinating conjunctions
            feature_list.append(past_verb(tags)) # Count past-tense verbs
            feature_list.append(future_verb(tweet)) # Count future-tense verbs
            feature_list.append(comma(tags)) # Count commas
            feature_list.append(colon(tweet)) # Count colons and semi-colons
            feature_list.append(dash(tweet)) # Count dashes
            feature_list.append(parentheses(tags)) # Count parentheses
            feature_list.append(ellipses(tweet)) # Count ellipses
            feature_list.append(cmn_noun(tags)) # Count common nouns
            feature_list.append(prop_noun(tags)) # Count proper nouns
            feature_list.append(adverb(tags)) # Count adverbs
            feature_list.append(wh_word(tags)) # Count wh-words
            feature_list.append(slang(tweet, s_pat)) # Count modern slang acroynms
            feature_list.append(up_case(tweet)) # Count words all in upper case
    
            total_sent, total_word, total_char = counter(tweet, pattern)
            feature_list.append(round(total_word/float(total_sent),2)) # Average length of sentences
            feature_list.append(round(total_char/float(total_word),2)) # Average length of tokens
            feature_list.append(total_sent) # Number of sentences
            feature_list.append(class_list[idx]) # Class Name
            
            try:
                out_val = ",".join(map(str, feature_list))+"\n"
                file_out.write(out_val)
            except IOError as e:
                sys.exit("I/O error({0}) for file {1}: {2}".format(e.errno, outfile, e.strerror))
            except:
                sys.exit("Unexpected error for file {0}".format(outfile), sys.exc_info()[0])
       
        idx += 1 # Index for the current argument 
    file_out.close()
    
    end = time.time()
    print end - start

if __name__ == "__main__":
    sys.exit(main(sys.argv))
