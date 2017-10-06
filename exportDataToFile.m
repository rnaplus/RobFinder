function exportDataToFile(handles, filename)
%% Write data to tab-delimited file
% column 1 = OH cleavage data
% column 2 = ladder (size std.) data
% ...

%% Create array to store all data values
iData = length(handles.myData.Dataset);
l = length(handles.myData.Dataset{1}{1});
dataArray = zeros(l, iData*2);
c=1;
for i=1:iData
    dataArray(:,c) = handles.myData.Dataset{i}{1};
    dataArray(:,c+1) = handles.myData.Dataset{i}{4};
    c=c+2;
end


%% Write data to file
fileID = fopen(filename, 'w');
for i=1:length(handles.myData.filenames)
    fprintf(fileID,'%s\t\t', handles.myData.filenames{i});
end
fprintf(fileID, '\n');
for i=1:length(dataArray(:,1))
    for j=1:length(dataArray(i,:))
        fprintf(fileID, '%1.0f\t', dataArray(i,j));
    end
    fprintf(fileID, '\n');
end
fclose(fileID);
end