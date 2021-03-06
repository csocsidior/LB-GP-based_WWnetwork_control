function ciplot(lower,upper,x,colour);
     
if length(lower)~=length(upper)
    error('lower and upper vectors must be same length')
end

if nargin<4
    colour= 'yellow';
end

if nargin<3
    x=1:length(lower);
end

% convert to row vectors so fliplr can work
if find(size(x)==(max(size(x))))<2
x=x'; end
if find(size(lower)==(max(size(lower))))<2
lower=lower'; end
if find(size(upper)==(max(size(upper))))<2
upper=upper'; end

h = fill([x fliplr(x)],[upper fliplr(lower)],colour);
set(h,'facealpha',.2,'LineStyle','-','LineWidth',0.2)


