function gmms = gmmTrain( dir_train, max_iter, epsilon, M )
% gmmTain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%
%  output:  gmms       : a 1xN cell array. The i^th element is a structure
%                        with this structure:
%                            gmm.name    : string - the name of the speaker
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column 
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances. 
%                                          (:,:,i) is for i^th mixturie
  tic;
  % Set up data matrix from dir_train
  DD = dir( dir_train );
  DD = DD( [ DD.isdir ] );
  format long;
  data = struct();  
  d = 14;
  gmms = [];
  cur_speaker = 1;

  % Combine all the .mfcc data into a large matrix
  % Go through each directory and makes sure it isn't the current or prev dir
  for iDir=1:length(DD)
    if (~strcmp('.', DD(iDir).name) && ~strcmp('..', DD(iDir).name))
      data.(DD(iDir).name) = [];
      files = dir( [ dir_train, filesep, DD(iDir).name, filesep, '*.mfcc' ] );

      for iFile=1:length(files)
        % Add all the data into a matrix with 14 columns
        lines = importdata([dir_train, filesep, DD(iDir).name, filesep, files(iFile).name]);
        data.(DD(iDir).name) = vertcat(data.(DD(iDir).name), lines);
      end
    end
  end

  % For each speaker
  for iDir=1:length(DD)
    if (~strcmp('.', DD(iDir).name) && ~strcmp('..', DD(iDir).name))
      % Initialize theta
      theta = struct();
      theta.mu = struct();
      theta.sigma = struct();
      theta.omega = struct();
      for m=1:M
        num = randi([1, size(data.(DD(iDir).name),1)]);
        theta.mu.(['m',num2str(m)]) = data.(DD(iDir).name)(num, :);
        theta.sigma.(['m',num2str(m)]) = ones(1,14);
        theta.omega.(['m',num2str(m)]) = 1/M; 
      end 

      % Train the gaussian mixture models!
      i = 0;
      prev_L = -Inf;
      improvement = Inf;
      while ((i <= max_iter) && (improvement >= epsilon))
        [p, log_L] = ComputeLikelihood(data.(DD(iDir).name), theta, M); 
        theta = UpdateParameters(theta, p, data.(DD(iDir).name), M);

        improvement = log_L - prev_L; 
        prev_L = log_L;
        i = i + 1;
      end

      % Set up gmms
      gmms = set_gmms(gmms, cur_speaker, M, d, theta, DD(iDir).name);
      cur_speaker = cur_speaker + 1;
    end
  end
  toc
end

function [p, log_L] = ComputeLikelihood(X, theta, M)
  % Initialize p
  p = struct();
  b_const = struct();
  log_L = 0;

  for m=1:M
    idx = ['m',num2str(m)];
    sigma = theta.sigma.(idx);
    p.(idx) = [];
    %b_const.(idx) = -(sum(((theta.mu.(idx)).^2)./(2*sigma)) + ((size(X,2)/2)*reallog(2*pi)) + (0.5*(reallog(prod(sigma)))));
  end

  log_b = [];
  for m=1:M
    % Constants
    idx = ['m',num2str(m)];
    sigma = theta.sigma.(idx);
    p.(idx) = [];

    % Calculate log_b
    part1 = -sum(bsxfun(@rdivide, bsxfun(@minus, X, theta.mu.(idx)).^2, 2*sigma), 2);
    part2 = -(size(X,2)/2)*reallog(2*pi);
    part3 = -(1/2)*reallog(prod(sigma));
    b_num = part1 + part2 + part3;
    log_b = horzcat(log_b, b_num);
  end

  % Get the denominator of the p 
  p_denom = zeros(size(X,1),1);
  for m=1:M
    p_denom = p_denom + theta.omega.(['m',num2str(m)])*exp(log_b(:,m));
  end

  % Calculate p 
  for m=1:M
    idx = ['m',num2str(m)];
    p_num = theta.omega.(idx)*exp(log_b(:,m));
    p.(idx) = p_num ./ p_denom; 
end
 
  log_L = sum(reallog(p_denom));
end

function theta = UpdateParameters(theta, p, X, M)
  T = size(X,1);

  % For each gaussian model
  for m=1:M
    total = 0;
    mu_num = 0;
    sig_num = 0;
    idx = ['m',num2str(m)];

    total = sum(p.(idx));
    mu_num = sum(bsxfun(@times, X, p.(idx)));
    sig_num = sum(bsxfun(@times, X.^2, p.(idx)));
    %sig_num = sum(bsxfun(@times, bsxfun(@minus, X, theta.mu.(idx)).^2, p.(idx))); 
    %mu_num = sum(bsxfun(@times, X, p.(idx)));

    % Set the new theta
    theta.omega.(idx) = total/T;
    theta.mu.(idx) = mu_num/total;
    theta.sigma.(idx) = (sig_num/total); - theta.mu.(idx).^2;
    %theta.mu.(idx) = mu_num/total;
  end
end

% Using the data (mostly from theta), set gmms
function gmms = set_gmms(gmms, idx, M, d, theta, name)
  gmms(idx).name = name;
  gmms(idx).means = [];
  gmms(idx).weights = [];

  for m=1:M
    m_val = ['m',num2str(m)];
    gmms(idx).weights = horzcat(gmms(idx).weights, theta.omega.(m_val));
    gmms(idx).means = horzcat(gmms(idx).means, transpose(theta.mu.(m_val)));
    gmms(idx).cov(:,:,m) = diag(theta.sigma.(m_val));
  end
end
