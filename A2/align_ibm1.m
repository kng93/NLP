function AM = align_ibm1(trainDir, numSentences, maxIter, fn_AM)
%
%  align_ibm1
% 
%  This function implements the training of the IBM-1 word alignment algorithm. 
%  We assume that we are implementing P(foreign|english)
%
%  INPUTS:
%
%       dataDir      : (directory name) The top-level directory containing 
%                                       data from which to train or decode
%                                       e.g., '/u/cs401/A2_SMT/data/Toy/'
%       numSentences : (integer) The maximum number of training sentences to
%                                consider. 
%       maxIter      : (integer) The maximum number of iterations of the EM 
%                                algorithm.
%       fn_AM        : (filename) the location to save the alignment model,
%                                 once trained.
%
%  OUTPUT:
%       AM           : (variable) a specialized alignment model structure
%
%
%  The file fn_AM must contain the data structure called 'AM', which is a 
%  structure of structures where AM.(english_word).(foreign_word) is the
%  computed expectation that foreign_word is produced by english_word
%
%       e.g., LM.house.maison = 0.5       % TODO
% 
% Template (c) 2011 Jackie C.K. Cheung and Frank Rudzicz
  
  global CSC401_A2_DEFNS

  AM = struct();
  
  % Read in the training data
  [eng, fre] = read_hansard(trainDir, numSentences);

  % Initialize AM uniformly 
  AM = initialize(eng, fre);

  % Iterate between E and M steps
  for iter=1:maxIter,
    AM = em_step(AM, eng, fre);
  end

  % Save the alignment model
  save( fn_AM, 'AM', '-mat'); 
  end





% --------------------------------------------------------------------------------
% 
%  Support functions
%
% --------------------------------------------------------------------------------

function [eng, fre] = read_hansard(mydir, numSentences)
%
% Read 'numSentences' parallel sentences from texts in the 'dir' directory.
%
% Important: Be sure to preprocess those texts!
%
% Remember that the i^th line in fubar.e corresponds to the i^th line in fubar.f
% You can decide what form variables 'eng' and 'fre' take, although it may be easiest
% if both 'eng' and 'fre' are cell-arrays of cell-arrays, where the i^th element of 
% 'eng', for example, is a cell-array of words that you can produce with
%
%         eng{i} = strsplit(' ', preprocess(english_sentence, 'e'));
%
  eng = {};
  fre = {};

  eng_files = dir( [ mydir, filesep, '*', 'e'] );
  fre_files = dir( [ mydir, filesep, '*', 'f'] );

  num_sent = 1;
  % Should have same number of english files as french files
  for iFile = 1:length(eng_files)
    eng_lines = textread([mydir, filesep, eng_files(iFile).name], '%s','delimiter','\n');
    fre_lines = textread([mydir, filesep, fre_files(iFile).name], '%s','delimiter','\n');

    % Should have same number of english lines as french lines
    for l = 1:length(eng_lines)
      eng{num_sent} = strsplit(' ', preprocess(eng_lines{l}, 'e'));
      fre{num_sent} = strsplit(' ', preprocess(fre_lines{l}, 'f'));

      % If number of sentences exceeds max, stop looping over the file
      if (num_sent >= numSentences)
        break;
      end
      num_sent = num_sent + 1;
    end

    % If number of sentences exceeds given, stop looping over the files
    if (num_sent >= numSentences)
      break;
    end
  end
end

% Returns true if punctuation or sentinels
function punc = check_punc(word)
  punc = false;
  if regexp(word, '\<([A-Z]+)(_)\>')
    punc = true;
  end

  if strcmp(word, 'SENTSTART') || strcmp(word, 'SENTEND')
    punc = true;
  end
end

function AM = initialize(eng, fre)
%
% Initialize alignment model uniformly.
% Only set non-zero probabilities where word pairs appear in corresponding sentences.
%
    AM = struct(); % AM.(english_word).(foreign_word)

    % Iterate over the english sentences
    for l = 1:length(eng)
      % Iterate over the words in the english sentence
      for ew = 1:length(eng{l})
        eword = eng{l}{ew};
        % Check for punctuation - if so, set probability to one
        if (check_punc(eword))
          AM.(eword).(eword) = 1;
        elseif (~isempty(eword))
          for fw = 1:length(fre{l})
            fword = fre{l}{fw};
            % Ignore word if punctuation
            if (~check_punc(fword)) && (~isempty(fword))
              AM.(eword).(fword) = 0;
            end
          end
        end
      end
    end

    % Calculate the probability for AM
    efields = fieldnames(AM);
    for i = 1:length(efields)
      % If punctuation, don't do anything to the probability (leave it as 1)
      if (~check_punc(efields{i}))
        ffields = fieldnames(AM.(efields{i}));
        for j = 1:length(ffields)
          % Set the probability to 1/<number of possible french matches>
          AM.(efields{i}).(ffields{j}) = 1/length(ffields);
        end
      end      
    end
end

function t = em_step(t, eng, fre)
% 
% One step in the EM algorithm.
%
  % Initialize tcount(f, e) and total(e)
  % Iterate over the english sentences
   for l = 1:length(eng)
     % Iterate over the words in the english sentence
     for ew = 1:length(eng{l})
       if (~isempty(eng{l}{ew}))
         if (check_punc(eng{l}{ew}))
           tcount.(eng{l}{ew}).(eng{l}{ew}) = 1;
         else
           % Iterate over the words in the french sentence
           for fw = 1:length(fre{l})
             if (~isempty(fre{l}{fw}))
               tcount.(eng{l}{ew}).(fre{l}{fw}) = 0;
             end
           end
           total.(eng{l}{ew}) = 0;
         end
       end
     end
   end
  
  % Iterate over english sentences (same number as french sentences b/c already aligned)
  for l = 1:length(eng) 
    funiq = unique(fre{l});
    % Iterate over unique french words in sentence
    for f = 1:length(funiq)
      denom_c = 0;
      euniq = unique(eng{l});
      fword = funiq{f};

      % Ignore if punctuation or empty
      if (~check_punc(fword)) && (~isempty(fword))
        % Iterate over unique english words in sentence
        for e = 1:length(euniq)
          % Ignore if punctuation
          if (~check_punc(euniq{e})) && (~isempty(euniq{e}))
            denom_c = denom_c + (t.(euniq{e}).(fword) * sum(strcmp(fre{l}, fword)));
          end
        end

        % Iterate over unique english wors in sentence
        for e = 1:length(euniq)
          eword = euniq{e};
          % Ignore if punctuation
          if (~check_punc(eword)) && (~isempty(eword))
            fcount = sum(strcmp(fre{l}, fword));
            ecount = sum(strcmp(eng{l}, eword));
            % Calculate tcount(f, e) and total(e)
            tcount.(eword).(fword) = tcount.(eword).(fword) + (t.(eword).(fword) * fcount * ecount / denom_c);
            total.(eword) = total.(eword) + (t.(eword).(fword) * fcount * ecount / denom_c);
          end
        end
      end
    end      
  end

  efields = fieldnames(total);
  for e = 1:length(efields)
    eword = efields{e};
    % Don't calculate if punctuation or empty
    if (~check_punc(eword)) && (~isempty(eword))
      ffields = fieldnames(tcount.(eword));
      for f = 1:length(ffields)
        fword = ffields{f};
        % Don't calculate if punctuation
        if (~check_punc(fword)) && (~isempty(fword))
          % Calculate the new probability
          t.(eword).(fword) = tcount.(eword).(fword) / total.(eword);
        end
      end
    % If punctuation but not empty
    elseif (~isempty(eword))
      t.(eword).(eword) = tcount.(eword).(fword); 
    end
  end
end


