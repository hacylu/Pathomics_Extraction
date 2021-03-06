%SEGMENTATION
%==========================================================================
clear all;
clc;
close all;
format long e;
name=string('g5.xls');
Img = imread('circle2.TIF');  % The same cell image in the paper is used here
Img=double(Img(:,:,1));
sigma=1.2;    % scale parameter in Gaussian kernel for smoothing.
G=fspecial('gaussian',15,sigma);
Img_smooth=conv2(Img,G,'same');  % smooth image by Gaussiin convolution
[Ix,Iy]=gradient(Img_smooth);
f=Ix.^2+Iy.^2;
g=1./(1+f);  % edge indicator function.

epsilon=1.5; % the papramater in the definition of smoothed Dirac function

timestep=5;  % time step
mu=0.02;  % coefficient of the internal (penalizing) energy term P(\phi)
          % Note: the product timestep*mu must be less than 0.25 for stability!

lambda=5; % coefficient of the weighted length term L(\phi)
alf=1.5;  % coefficient of the weighted area term A(\phi);
          % Note: Choose smaller value for weak object bounday, such as the cell image in this demo.

[nrow, ncol]=size(Img);
nContour=2;
%uiwait(msgbox(uiwait(msgbox('String','Title','modal'))));
figure;imagesc(Img, [0, 255]);colormap(gray);hold on;
text(10,10,'Left click to get points, right click to get end point');

% mouse click to define initial level set function
BW = roipoly;  % get polygon, BW is a binary image with 1 and 0 inside or outside the polygon;
c0=3; % the constant value used to define binary level set function;
initialLSF= -c0*2*(0.5-BW); % initial level set function: -c0 inside, c0 outside;

% initialLSF = binaryInitial(con, nrow, ncol);

u=initialLSF;

[c,h] = contour(u,[0 0],'r');
u=initialLSF;
figure;imagesc(Img, [0, 255]);colormap(gray);hold on;
[c,h] = contour(u,[0 0],'r');
                          
title('Initial contour');
% start level set evolution
for n=1:100
    u=EVOLUTION_PLSE(u, g ,lambda, mu, alf, epsilon, timestep, 1);  
    pause(0.001);
    if mod(n,20)==0
        imagesc(Img, [0, 255]);colormap(gray);hold on;
        [c,h] = contour(u,[0 0],'r'); 
        iterNum=[num2str(n), ' iterations'];        
        title(iterNum);
        hold off;
    end
end
imagesc(Img, [0, 255]);colormap(gray);
hold on;[c,h] = contour(u,[0 0],'r'); 
hold off;

%==========================================================================
% %Plot the contour
% figure;
% [c,h] = contour(u,[0 0],'r'); 
% totalIterNum=[num2str(n), ' iterations'];  
% title(totalIterNum);

%==========================================================================
%get the coordinates in order
points=c(:,2:size(c,2));
xy=order(points);

x_cor =xy(:,1);
y_cor =xy(:,2);
%==========================================================================
%get the centroid and area
[xc,yc,area]=centroid(xy);
figure; plot(xy(:,1),-xy(:,2),'r'); hold on; plot(xc,-yc,'o');

%==========================================================================

distance=sqrt((x_cor-xc).^2+(y_cor-yc).^2);

dist_min=min(distance);
dist_max=max(distance);

% %draw circle from centroid to min radius
% theta=[0:.01:2*pi];
% for i=1:length(theta)
%     x_c(i)=dist_min*cos(theta(i))+xc;
%     y_c(i)=dist_min*sin(theta(i))+yc;
% end
% hold on;
% plot(x_c,y_c,'k')

%draw circle from centroid to max radius
theta=[0:.01:2*pi];
for i=1:length(theta)
    x_c1(i)=dist_max*cos(theta(i))+xc;
    y_c1(i)=-dist_max*sin(theta(i))-yc;
end
hold on;
plot(x_c1,y_c1,'k')

%==========================================================================
% %get variance and standard deviation
% var=cov(distance);
% stdv=std(distance);

%==========================================================================
%get maximum area and Area Ratio
max_area=pi*dist_max^2;
Area_Ratio=area/max_area;

%==========================================================================
%Ratio between average distance and maximum distance

dist_mean=mean(distance);
Dist_Ratio=dist_mean/dist_max;
%==========================================================================
%normalizing distance to find the variance and std

dists=distance/dist_max;
dists_std=std(dists);
dists_var=cov(dists);

%==========================================================================
%new distance ratio defined
dratio=distratio(xy);
%==========================================================================
%area to perimeter ratio
[paratio,peri]=periarea(xy,area);

%==========================================================================
%the SMOOTHNESS METRIC  
D=distance;
s=length(D);
for i=1:s;
    if i==1;
        sm(i)=abs(D(i)-((D(i+1)+D(s))/2));
    else if i==s;
            sm(i)=abs(D(i)-((D(1)+D(i-1))/2));
        else if i>=2 & i<=s-1
                sm(i)=abs(D(i)-((D(i+1)+D(i-1))/2));
            end
        end
    end
end
smooth=sum(sm);
%==========================================================================
%Fourier Descriptors of boundary

z = frdescp([x_cor,y_cor]);
fd=z(1:100);

%============
%invariant moments
B=bound2im([x_cor,y_cor]);

phi=invmoments(B);
%===========================
%get the fractal dimension

frac_dim=fractal_dim([x_cor,y_cor]);
%==========================================

%para are all the features that are extracted.   

para=[Area_Ratio;Dist_Ratio;dists_std;dists_var;dratio;paratio;smooth;[phi'];frac_dim;[fd]];
%para=[Area_Ratio;Dist_Ratio;dists_std;dists_var];

%nme=fprintf('%s',name);
fid = fopen(name,'w');
        fprintf(fid,'%15.10f\n',para);
        fprintf(fid,'%15.10f \t %15.10f\n',[x_cor,y_cor]);
fclose(fid);


%to get all the features for glands and get the mean automatically.
% files=['g1.xls';'g2.xls'; 'g3.xls'; 'g4.xls'];
% for i=1:size(files,1);
%  fid = fopen(files(i,:));
%  feature(i,:) = fscanf(fid,'%g',[1 115]); %  
%  fclose(fid)
% end
% feature=feature';
% mean_feature=mean(feature,2);
% mean_feature=mean_feature';
% save mean_feature mean_feature

 % % old one
% %CAVE =[0.4999;0.7178;0.1419;0.0211];
% CAVE = [0.47542;0.70094; 0.14158; 0.021017; 0.76584];
% 
% % old one
% %BAVE =[0.2308;0.5183;0.1984;0.0450];
% BAVE = [0.27297;0.58401; 0.20965; 0.045246; 0.63293];
% 
% n1=norm(para-CAVE);
% n2=norm(para-BAVE);
% 
% if n1 < n2
%     disp('============================================')
%     disp('===============Sorry, Cancerous=============')
%     disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
% else if n2 < n1
%         disp('========================================')
%         disp('=================Benign=================')
%         disp('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~')
%     end
% end




