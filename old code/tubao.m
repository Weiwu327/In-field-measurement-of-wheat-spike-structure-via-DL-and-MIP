function edge = tubao(img,r,c)
edge = img;
k = convhull(r,c);
for i = 1:size(k,1)
%     edge(r(k(i)),c(k(i))) = 1;
    if i == size(k,1)
        y = [r(k(i)) r(k(1))];
        x = [c(k(i)) c(k(1))];
    else
        y = [r(k(i)) r(k(i+1))];
        x = [c(k(i)) c(k(i+1))];
    end
    
    nPoints = max(abs(diff(x)), abs(diff(y)))+1;    % Number of points in line
    rIndex = round(linspace(y(1), y(2), nPoints));  % Row indices
    cIndex = round(linspace(x(1), x(2), nPoints));  % Column indices
    index = sub2ind(size(edge), rIndex, cIndex);     % Linear indices
    edge(index) = 1;
end
end