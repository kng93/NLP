%
% evalAlign
%
%  This is simply the script (not the function) that you use to perform your evaluations in 
%  Task 5. 

% some of your definitions
trainDir     = '/u/cs401/A2_SMT/data/Hansard/Training/';
testDir      = '/u/cs401/A2_SMT/data/Hansard/Testing/';
testFile     = 'Task5';
fn_LME       = 'eng_model';
fn_LMF       = 'fre_model';
lm_type      = '';
delta        = 0;
vocabSize    = 0; 
numSentences = 1000;
maxIter      = 8;

% Train your language models. This is task 2 which makes use of task 1
% Don't train again if already have the model...
if (exist(fn_LME) == 2)
  LME = importdata(fn_LME);
else
  LME = lm_train( trainDir, 'e', fn_LME );
end

if (exist(fn_LMF) == 2)
  LMF = importdata(fn_LMF);
else
  LMF = lm_train( trainDir, 'f', fn_LMF );
end

vocabSize = length(fieldnames(LME.uni));

% Train your alignment model of French, given English 
AMFE = align_ibm1( trainDir, numSentences, maxIter, 'am.mat' );

% Initialized counters
total_words = 0;
correct_words = 0;

% Read from the files
flines = textread([testDir, filesep, strcat(testFile, '.f')], '%s','delimiter','\n');
elines = textread([testDir, filesep, strcat(testFile, '.e')], '%s','delimiter','\n');

% Iterate over the sentences in the test file -- automatically assume french sentence
for l = 1:length(flines)
  fre = preprocess(flines{l}, 'f');
  % Decode the test sentence 'fre'
  eng = decode( fre, LME, AMFE, lm_type, delta, vocabSize );

  % Get the information
  eng_actual = preprocess(elines{l}, 'e');
  fwords = strsplit( ' ', fre );
  ewords = strsplit( ' ', eng_actual);

  % Perform some analysis
  for w = 1:length(fwords)
    fword = fwords{w};
    % Make sure not punctuation or the beginning/end of a sentence
    if (isempty(regexp(fword, '\<([A-Z]+)(_)\>'))) && ~strcmp(fword, 'SENTSTART') && ~strcmp(fword, 'SENTEND')
      % Compare the actual word and the decoded word
      if (length(eng) >= w) && (length(ewords) >= w)
        if (strcmp(eng{w}, ewords{w}))
          correct_words = correct_words + 1;
        end
      end
      total_words = total_words + 1;
    end
  end
end

results = [ 'Proportion - ', num2str(correct_words/total_words), ', (Correct=', num2str(correct_words), ', Total=', num2str(total_words), '); Params - delta=', num2str(delta),', numSentences=', num2str(numSentences), ', maxIter=', num2str(maxIter) ];
disp(results);
