trainDir = '/u/cs401/speechdata/Training/';
testDir = '/u/cs401/speechdata/Testing/';
gmm_file = 'GMM_Data2';
M = 8;


if (exist(gmm_file) == 2)
  gmms = importdata(gmm_file);
else
  gmms = gmmTrain(trainDir, 30, 0.1, 8);
end

files = dir([ testDir, filesep, '*.mfcc' ]);

for iFile=1:length(files)
  all_log = [];
  % Get the name of the file
  name = strsplit('.', files(iFile).name);
  name = name(1);
  % Add all the data into a matrix with 14 columns
  data = importdata([testDir, filesep, files(iFile).name]);

  % Iterate over the speakers
  for s=1:length(gmms)
    % Get theta from gmms
    theta = struct();
    for m=1:M
      m_val = ['m',num2str(m)];
      theta.mu.(m_val) = transpose(gmms(s).means(:,1));
      theta.omega.(m_val) = gmms(s).weights(m); 
      theta.sigma.(m_val) = transpose(diag(gmms(s).cov(:,:,m)));
    end

    % Get the log likelihoods
    [p, log_L] = ComputeLikelihood(data, theta, M);
    all_log = horzcat(all_log, log_L);
  end

  fh = fopen(strcat(char(name), '.lik'), 'w');
  idxs = [1:length(gmms)];
  % Get the top 5 most likely speakers
  for i=1:5
    % Get the indices of the maximum value in the array
    top_idx = find(all_log == max(all_log));
    top_idx = find(idxs == top_idx(1)); % (1 in rare case there is a double maximum)

    % Put names to file 
    fprintf(fh, '%s\n', gmms(top_idx).name);

    % Get rid of the maximum in the array
    all_log(top_idx) = [];
    idxs(top_idx) = [];
  end
  fclose(fh);
end
