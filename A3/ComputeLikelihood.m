function [p, log_L] = ComputeLikelihood(X, theta, M)
  % Initialize p

  b_const = struct();
  log_L = 0;

  for m=1:M
    idx = ['m',num2str(m)];
    sigma = theta.sigma.(idx);
    p.(idx) = [];
    b_const.(idx) = -(sum(((theta.mu.(idx)).^2)./(2*sigma)) + ((size(X,2)/2)*reallog(2*pi)) + (0.5*(reallog(prod(sigma)))));
  end

  log_b = [];
  for m=1:M
    % Constants
    idx = ['m',num2str(m)];
    sigma = theta.sigma.(idx);
    p.(idx) = [];
    b_const = -(sum(((theta.mu.(idx)).^2)./(2*sigma)) + ((size(X,2)/2)*reallog(2*pi)) + (0.5*(reallog(prod(sigma)))));

    % Calculate log_b
    div_sigma = bsxfun(@rdivide, X.^2, sigma);
    mult_mu = bsxfun(@rdivide, bsxfun(@times, X, theta.mu.(idx)), sigma);
    b_num = -sum(0.5*div_sigma - mult_mu, 2);
    log_b = horzcat(log_b, b_num+b_const);
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
