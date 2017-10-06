function exportPeakAreasToFile(handles, filename, n)
%% Write data to tab-delimited file
% column 1 = peak number
% column 2 = peak area

pkAreas = handles.myData.pkAreas{n};

%% Write data to file
fileID = fopen(filename, 'w');
fprintf(fileID,'%s', handles.myData.filenames{n});
for i=1:length(pkAreas)
    fprintf(fileID, '\n');
    fprintf(fileID, '%1.0f\t%1.4E', i, pkAreas(i));
end
fclose(fileID);

end