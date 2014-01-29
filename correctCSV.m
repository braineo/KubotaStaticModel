dataSize = size(facepreference,1);
for i = 1:dataSize
%     idx = mapPref(cell2mat(facepreference(i,2)));
%     facepreference(i,1) = num2cell(idx);
    x = cell2mat(facepreference(i,3))+cell2mat(facepreference(i,5))/2;
    y = cell2mat(facepreference(i,4))+cell2mat(facepreference(i,6))/2;
    facepreference(i,3) = num2cell(x);
    facepreference(i,4) = num2cell(y);
end