function [p, log_L] = ComputeLikelihood(X, theta, M)
  % Initialize p
  p = struct();
  b_const = struct();
  log_L = 0;

  for m=1:M
    idx = ['m',num2str(m)];
    sigma = theta.sigma.(idx);
    p.(idx) = [];
    b_const.(idx) = -(sum(((theta.mu.(idx)).^2)./(2*sigma)) + ((size(X,2)/2)*log(2*pi)) + (0.5*(log(prod(sigma)))));
  end

  % Iterate over every speech segment
  for i=1:size(X,1)
    log_b = [];

    % Calculate the b for every gmm of the current speech segment
    for m=1:M
      idx = ['m',num2str(m)];
      sigma = theta.sigma.(idx);
      b_num = -sum((0.5*((X(i,:).^2)./sigma) - ((theta.mu.(idx).*X(i,:))./sigma))); %-(0.5*sum(((X(i,:).^2 - theta.mu.(idx)).^2)./sigma));
      log_b = vertcat(log_b, b_num+b_const.(idx)); % For speech segment i, list of b varying by m
    end

    % Get the denominator of p
    p_denom = 0;
    for m=1:M
      p_denom = p_denom + theta.omega.(['m',num2str(m)])*exp(log_b(m,:));
    end

    % For every gmm, add current speech segment to list in p
    for m=1:M
      idx = ['m',num2str(m)];
      p_num = theta.omega.(idx)*exp(log_b(m,:));
      p.(idx) = vertcat(p.(idx), p_num./p_denom);
    end

    % Calculate log_L
    log_L = log_L + log(p_denom);
  end
end
