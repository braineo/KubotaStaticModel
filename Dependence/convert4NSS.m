function [SALIENCYMAP, meanVec, stdVec] = convert4NSS(SALIENCYMAP, VALID)
meanVec=mean(SALIENCYMAP(VALID), 1);
SALIENCYMAP=SALIENCYMAP-repmat(meanVec, size(SALIENCYMAP));
stdVec=std(SALIENCYMAP(VALID));
z=find(stdVec==0);
if length(z)>0
    display('Alert: DIVIDE by 0 in the Whiten call!');
end
SALIENCYMAP=SALIENCYMAP./repmat(stdVec, size(SALIENCYMAP));
