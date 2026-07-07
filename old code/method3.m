function skeleton = method3(bw)
bw = double(bw);
[M,N] = size(bw);
skeleton = bw;

List = getList2();

[x,y] = find(bw);
a = min(x);
b = max(x);
c = min(y);
d = max(y);

deleCount = 1;
mat = [1,2,4,8,16,32,64,128];
while deleCount>0
    deleCount = 0;
    label = zeros(M,N,'logical');
    for i = a:b
        for j = c:d
            if skeleton(i,j)
                p = [skeleton(i-1,j),skeleton(i-1,j+1),skeleton(i,j+1),skeleton(i+1,j+1),...
                    skeleton(i+1,j),skeleton(i+1,j-1),skeleton(i,j-1),skeleton(i-1,j-1)];
                idx = sum(p.*mat)+1;
                if List(idx)
                    label(i,j) = true;
                    deleCount = deleCount+1;
                end
            end
        end
    end
    skeleton(label) = 0;
end
end