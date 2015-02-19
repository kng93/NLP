function outSentence = preprocess( inSentence, language )
%
%  preprocess
%
%  This function preprocesses the input text according to language-specific rules.
%  Specifically, we separate contractions according to the source language, convert
%  all tokens to lower-case, and separate end-of-sentence punctuation 
%
%  INPUTS:
%       inSentence     : (string) the original sentence to be processed 
%                                 (e.g., a line from the Hansard)
%       language       : (string) either 'e' (English) or 'f' (French) 
%                                 according to the language of inSentence
%
%  OUTPUT:
%       outSentence    : (string) the modified sentence
%
%  Template (c) 2011 Frank Rudzicz 

  global CSC401_A2_DEFNS
  
  % first, convert the input sentence to lower-case and add sentence marks 
  inSentence = [CSC401_A2_DEFNS.SENTSTART ' ' lower( inSentence ) ' ' CSC401_A2_DEFNS.SENTEND];

  % trim whitespaces down 
  inSentence = regexprep( inSentence, '\s+', ' '); 

  % initialize outSentence
  outSentence = inSentence;

  % perform language-agnostic changes
  % Separate final punctuation (end of sentence), as well as single quotation
  outSentence = regexprep( outSentence, '(.+?)([\.\?\!\:\;\-\'']+)(\s*)(SENTEND|$|\\n)', '$1 $2 $4');
  % Seperate commas, colons, semi-colons, parentheses
  outSentence = regexprep( outSentence, '([^\s]+?)(\s*)([\,\:\;\(\)])(\s*)', '$1 $3 ');
  % Separate dashes between parentheses -
	% Looks behind for open parentheses without following closing before dash. Similar look ahead for closing.
	% Matches anything besides parentheses dash, except space => want to make sure don't add spaces
  outSentence = regexprep( outSentence, '(?<=\([^\)]+)([^\)\(\s]+?)(\s*)(\-)(\s*)(?=[^\(]+\))', '$1 $3 ') ;
  % Separate mathematical operators (+, -, <, >, =) if there is a number on at least one side
  outSentence = regexprep( outSentence, '([\d]+?)(\s*)([\+|\-|\>|\<|=])(\s*)', '$1 $3 ');
  outSentence = regexprep( outSentence, '(\s*)([\+|\-|\>|\<|=])(\s*)([\d]+?)', ' $2 $4');
  % Separate quotation marks
  outSentence = regexprep( outSentence, '(\s*)([\"\`])(\s*)' ,' $2 ');
  outSentence = regexprep( outSentence, '(\s+|^)(\'')(\w+)', '$1$2 $3'); % Single quotation at beginning of word

  switch language
   case 'e'
    % Separate posessive apostrophe
    outSentence = regexprep( outSentence, '(\w+)(\'')(\s+)','$1 $2$3');
    % Separate n't clitics
    outSentence = regexprep( outSentence, '(\w+)(n\''t)','$1 $2'); 
    % Separate rest of the clitics
    outSentence = regexprep( outSentence, '(\w*[^\WNn])(\''\w+)','$1 $2');   
   case 'f'
    % Separate leading consonant and apostrophe (including l')
    outSentence =  regexprep( outSentence, '\<([B-DF-HJ-NP-TV-Zb-df-hj-np-tv-z]\'')([\w]+)\>', '$1 $2');
    % Separate leading qu'
    outSentence =  regexprep( outSentence, '\<(qu\'')([\w]+)\>', '$1 $2');
    % Separate following on or il
    outSentence =  regexprep( outSentence, '\<([\w]+\'')(on|il)\>', '$1 $2');
    % Undo d'abord, d'accord, d'ailleurs, d'habitude spaces
    outSentence = regexprep( outSentence, '\<(d\'')(\s*)(abord|accord|ailleurs|habitude)\>', '$1$3');
  end

  % change unpleasant characters to codes that can be keys in dictionaries
  outSentence = convertSymbols( outSentence );

  % Ensure no token is more than 63 characters
  outSentence = regexprep( outSentence, '([\w\_]{60})([\w_]{4})([\w_]*)', 'XXX$1');
