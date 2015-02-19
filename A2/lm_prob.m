function logProb = lm_prob(sentence, LM, type, delta, vocabSize)
%
%  lm_prob
% 
%  This function computes the LOG probability of a sentence, given a 
%  language model and whether or not to apply add-delta smoothing
%
%  INPUTS:
%
%       sentence  : (string) The sentence whose probability we wish
%                            to compute
%       LM        : (variable) the LM structure (not the filename)
%       type      : (string) either '' (default) or 'smooth' for add-delta smoothing
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% Template (c) 2011 Frank Rudzicz

  logProb = -Inf;

  % some rudimentary parameter checking
  if (nargin < 2)
    disp( 'lm_prob takes at least 2 parameters');
    return;
  elseif nargin == 2
    type = '';
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  end
  if (isempty(type))
    delta = 0;
    vocabSize = length(fieldnames(LM.uni));
  elseif strcmp(type, 'smooth')
    if (nargin < 5)  
      disp( 'lm_prob: if you specify smoothing, you need all 5 parameters');
      return;
    end
    if (delta <= 0) or (delta > 1.0)
      disp( 'lm_prob: you must specify 0 < delta <= 1.0');
      return;
    end
  else
    disp( 'type must be either '''' or ''smooth''' );
    return;
  end

  words = strsplit(sentence);
 
  % Initialize first word to be 'null' (consistent with lm_train); should always be followd by SENTSTART 
  prevWord = 'null'
  total_prob = 1;

  % Calculating the MLE estimate
  for w=1:length(words)
    word = strtrim(words{w});
    prob = 0;
 
    % If word isn't in training for uni set, leave logProb = -inf (because won't be in bi set)
    if isfield(LM.uni, word)
      uni_wcount = LM.uni.(word) + delta; % If not smooth, delta = 0 so has no effect
      bi_wcount = 0 + (delta * vocabSize); % Default until found
      % Get the bi count
      if isfield(LM.bi, prevWord) && isfield(LM.bi.(prevWord), word)
        bi_wcount = LM.bi.(prevWord).(word) + (delta * vocabSize);
      end
         
      % Get the probability for current word
      prob = bi_wcount / uni_wcount;
    end
    total_prob = total_prob * prob;
  end
  logProb = log2(total_prob);

  % TODO: Test!!!

return
