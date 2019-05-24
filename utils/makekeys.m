function [keysout,out] = makekeys(scale,scaletype,nnotes,addoct)
noteref = csvread('NoteIDX.csv');
noteIDX = noteref(scaletype,:)-1;
noteIDX(isnan(noteIDX)) = [];
numoct = ceil(nnotes/numel(noteIDX));
keys = noteIDX+scale-1;
keysout = [];
for i = 1:numoct
    keysout = [keysout keys+(i-1)*12];
end
keybuff = 64-max(keysout);
keysout = keysout+12*floor(keybuff/24)+addoct*12+25;
if max(keysout) > 64+25 
    out = 0; 
    return
else
    out = 1; 
end
