function List = getList2()
List = zeros(256,1,'logical');
for n = 0:255
    p = bitget(n,1:8);
    Np = sum(p);
    Tp = length(find(([p(2:end),p(1)]-p) == 1));
    if Np>1 && Np<7 && Tp==1
        if (p(1)*p(3)*p(5)==0 && p(7)*p(3)*p(5)==0)||...
                (p(1)*p(3)*p(7)==0 && p(1)*p(5)*p(7)==0)
            List(n+1) = true;
        end
    end
end
end