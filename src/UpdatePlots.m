function UpdatePlots(h)
tmp = zeros(1,size(h.H,1)); tmp(h.m.Wshow) = 1;
Wim = find(h.m.W_sf & tmp);
axes(h.axesH); cla
Hstd = std(h.H(:));
outinds = round(h.m.vstart*size(h.H,2))+1:round(h.m.vend*size(h.H,2));
t = 1/h.m.framerate:1/h.m.framerate:size(h.H,2)/h.m.framerate;
l_idx = 0;
for i = Wim
    plot(t(outinds),h.H(i,outinds)+l_idx*Hstd*3,'Color',h.cmap(i,:))
    text(-2,l_idx*Hstd*3,mat2str(i));
    l_idx = l_idx+1;
    hold on
end
colormap(h.cmap); caxis([0 size(h.cmap,1)]); %colorbar('EastOutside')
xlabel('time (sec)');
xlim([-3 t(outinds(end))])
set(gca,'YTick',[])

axes(h.axesW); cla
Wtmp = reshape(h.W(:,h.m.Wshow).*h.m.W_sf(h.m.Wshow)*h.cmap(h.m.Wshow,:),[h.m.ss(1:2) 3]);

imagesc(Wtmp)
axis equal
axis off

axes(h.axesWH); cla
sc = 256/str2num(h.clim.String);
im = reshape(h.W(:,h.m.Wshow)*diag(h.H(h.m.Wshow,h.framenum))*h.cmap(h.m.Wshow,:),[h.m.ss(1:2) 3]);
imagesc(uint8(im*sc))
caxis([0 str2num(h.clim.String)])
axis equal
axis off
drawnow

if isfield(h,'Mfinal')
    axes(h.axesMIDI)
    Mimg = zeros(numel(Wim),round(max(h.M.noteend)*h.m.framerate));
    cla
    for j = 1:numel(h.M.notestart)
        t = round(h.M.notestart(j)*h.m.framerate:h.M.noteend(j)*h.m.framerate)+1;
        Mimg(find(h.M.notekey(j)==h.m.keys),t) = h.M.notemag(j);
    end
    imagesc(1-repmat(Mimg/max(Mimg(:)),[1 1 3]))
    axis off
end
axes(h.axesW)
