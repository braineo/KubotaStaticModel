for i = 1:length(result)
    if(result{i}.F > 8.8123)
       fprintf('F=%f, combo is %d %d, feature: %s\n', result{i}.F,result{i}.combo,...
       result{i}.featName);
    end
end