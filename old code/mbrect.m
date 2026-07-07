function [rectx,recty,area,perimeter,lw] = mbrect(x,y,metric)
if (nargin<3) || isempty(metric)
    metric = 'a';
elseif ~ischar(metric)
    error 'metric must be a character flag if it is supplied.'
else
    metric = lower(metric(:)');                    
    ind = strmatch(metric,{'area','perimeter'});             
    if isempty(ind)                
        error 'metric does not match either ''area'' or ''perimeter'''
    end
  metric = metric(1);
end

x=x(:);
y=y(:);

n = length(x);

if n~=length(y)                               
    error 'x and y must be the same sizes'
end

if n>3
    edges = convhull(x,y);
%     figure,imshow(edges);

    x = x(edges);
    y = y(edges);
    nedges = length(x) - 1;                       
end

Rmat = @(theta) [cos(theta) sin(theta);-sin(theta) cos(theta)];

ind = 1:(length(x)-1);
edgeangles = atan2(y(ind+1) - y(ind),x(ind+1) - x(ind));
% length(edgeangles)
edgeangles = unique(mod(edgeangles,pi/2));

nang = length(edgeangles);              
area = inf;                           
perimeter = inf;
met = inf;
xy = [x,y];
% xy(:,1)
% scatter(x,y)

for i = 1:nang
%     i
    rot = Rmat(-edgeangles(i));
%     -edgeangles(i)
    xyr = xy*rot;
%     figure;scatter(xyr(:,1),xyr(:,2))

    xymin = min(xyr,[],1);
    xymax = max(xyr,[],1);

    A_i = prod(xymax - xymin);
    P_i = 2*sum(xymax-xymin);
    lw_i = xymax-xymin;
%     A_i
    if metric=='a'
        M_i = A_i;
    else
        M_i = P_i;
    end

    if M_i<met
        % keep this one
        met = M_i;
        area = A_i;
        perimeter = P_i;
        lw = lw_i;

        rect = [xymin;[xymax(1),xymin(2)];xymax;[xymin(1),xymax(2)];xymin];
        rect = rect*rot';
        rectx = rect(:,1);
        recty = rect(:,2);
%     else
%         break;
    end
end

% for j = nang:-1:1
%     j
%     rot = Rmat(-edgeangles(j));
%     xyr = xy*rot;
% %     figure;scatter(xyr(:,1),xyr(:,2))
%     xymin = min(xyr,[],1);
%     xymax = max(xyr,[],1);
% 
%     A_j = prod(xymax - xymin);
%     P_j = 2*sum(xymax-xymin);
% 
%     if metric=='a'
%         M_j = A_j;
%     else
%         M_j = P_j;
%     end
% 
%     if M_j<met
%         % keep this one
%         met = M_j;
%         area = A_j;
%         perimeter = P_j;
% 
%         rect = [xymin;[xymax(1),xymin(2)];xymax;[xymin(1),xymax(2)];xymin];
%         rect = rect*rot';
%         rectx = rect(:,1);
%         recty = rect(:,2);
%     else
%         return;
%     end
% end
% get the final rect

% all done

end % mainline end