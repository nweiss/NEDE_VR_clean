function bigFeature = AppendFeatures(varargin)

nFeatures = nargin;
nSubjects = numel(varargin{1});
bigFeature_cell = cell(nFeatures,nSubjects);

for i=1:nFeatures
    feature = varargin{i};    
    bigFeature_cell(i,:) = feature;
end

bigFeature = cell(1,nSubjects);
for j=1:nSubjects
    bigFeature{j} = cat(2,bigFeature_cell{:,j});
end