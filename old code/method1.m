function skeleton = method1(bw)
bw = double(bw);
[M,N] = size(bw);
skeleton = bw;
deleCount = 1;
while deleCount>0
    
    deleCount = 0;
    label = zeros(M,N,'logical');
    for i = 2:M-1
        for j = 2:N-1
            if skeleton(i,j)
                p = [skeleton(i-1,j),skeleton(i-1,j+1),skeleton(i,j+1),skeleton(i+1,j+1),...
                    skeleton(i+1,j),skeleton(i+1,j-1),skeleton(i,j-1),skeleton(i-1,j-1)];
                Np = sum(p);
                Tp = length(find(([p(2:end),p(1)]-p) == 1));
                if Np>1 && Np<7 && Tp==1 && p(1)*p(3)*p(5)==0 && p(7)*p(3)*p(5)==0
                    deleCount = deleCount+1;
                    label(i,j) = 1;
                end
            end
        end
    end
    skeleton(label) = 0;
    
    label = zeros(M,N,'logical');
    for i = 2:M-1
        for j = 2:N-1
            if skeleton(i,j)
                p = [skeleton(i-1,j),skeleton(i-1,j+1),skeleton(i,j+1),skeleton(i+1,j+1),...
                    skeleton(i+1,j),skeleton(i+1,j-1),skeleton(i,j-1),skeleton(i-1,j-1)];
                Np = sum(p);
                Tp = length(find(([p(2:end),p(1)]-p) == 1));
                if Np>1 && Np<7 && Tp==1 && p(1)*p(3)*p(7)==0 && p(1)*p(5)*p(7)==0
                    deleCount = deleCount+1;
                    label(i,j) = 1;
                end
            end
        end
    end
    skeleton(label) = 0;
end