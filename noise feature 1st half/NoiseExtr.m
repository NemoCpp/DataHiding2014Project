clear all; close all;clc;
start_time = cputime;

 file_name = 'tulipano90_t';
 G = imread(file_name,'jpg');
 
 
 %G=zeros(300,300,3);
 
 %G(100:199,100:199,1)=rand(100,100)*1;
 %G(100:199,100:199,2)=rand(100,100)*1;
 %G(100:199,100:199,3)=rand(100,100)*100;
 %figure;
 %imshow(G);
 
%G = imread('tulipano10.jpg');
% Noise estimation

%clustering with SLIC algo
% 1000 superpixels using a weighting factor of 1.5 
number_of_segment = 30;
%[l, Am, C] = slic(G, number_of_segment, 1.5, 1, 'median');
[l, Am, C] = slic(G, number_of_segment, 30, 1.5, 'median');
%Am is just a copy of l i this implementation!!!!!!!!!!

figure;
imshow(drawregionboundaries(l, G, [255 255 255]));

[imH imW] = size(l);
number_of_segment=max(max(l));
%compute matrix with neighbours
adj_matrix = zeros(number_of_segment);
for i=2:imH-1
    for j=2:imW-1
        for k=-1:1
            for x=-1:1
                if(l(i,j) ~= l(i+k,j+x))
                    adj_matrix(l(i,j), l(i+k,j+x)) = 1;
                end
            end
        end
     end
end
%l
%adj_matrix
%rgb2gray converts RGB values to grayscale values by forming 
%a weighted sum of the R, G, and B components:
I = rgb2gray(G);
%sobel operation to get edges
%G=int32(G);
H=edge(I,'sobel');
%[E,A]=Sobel(G);
%figure;
%imshow(H);%already a bitmap

Z=conv2(double(H),ones(3),'same');%not bitmap, but doesnt matter
%for plotting we make it a bitmap
for i=1:imH
    for j=1:imW
        if Z(i,j)>0
            Z(i,j)=1;
        end
    end
end
%figure;
%imshow(Z);


% creation of filters
im_red = G(:, :, 1);
im_green = G(:, :, 2);
im_blue = G(:, :, 3);

Hr1 = medfilt2(im_red);
Hg1 = medfilt2(im_green);
Hb1 = medfilt2(im_blue);
gaussian_filter = fspecial('gaussian',[3 3], 0.5);
Hr2 = imfilter(im_red, gaussian_filter, 'replicate');
Hg2 = imfilter(im_green, gaussian_filter, 'replicate');
Hb2 = imfilter(im_blue, gaussian_filter, 'replicate');
avarage_filter = fspecial('average');
Hr3 = imfilter(im_red, avarage_filter, 'replicate');
Hg3 = imfilter(im_green, avarage_filter, 'replicate');
Hb3 = imfilter(im_blue, avarage_filter, 'replicate');
Hr4 = wiener2(im_red,[3 3]);
Hg4 = wiener2(im_green,[3 3]);
Hb4 = wiener2(im_blue,[3 3]);
Hr5 = wiener2(im_red,[5 5]);
Hg5 = wiener2(im_green,[5 5]);
Hb5 = wiener2(im_blue,[5 5]);

% extraction of feature for every combination color/filter
% color_filter(color, filter)
col_fil = zeros(3, 5, imH, imW);
col_fil(1,1,:,:) = im_red - Hr1;
col_fil(2,1,:,:) = im_green - Hg1;
col_fil(3,1,:,:) = im_blue - Hb1;
col_fil(1,2,:,:) = im_red - Hr2;
col_fil(2,2,:,:) = im_green - Hg2;
col_fil(3,2,:,:) = im_blue - Hb2;
col_fil(1,3,:,:) = im_red - Hr3;
col_fil(2,3,:,:) = im_green - Hg3;
col_fil(3,3,:,:) = im_blue - Hb3;
col_fil(1,4,:,:) = im_red - Hr4;
col_fil(2,4,:,:) = im_green - Hg4;
col_fil(3,4,:,:) = im_blue - Hb4;
col_fil(1,5,:,:) = im_red - Hr5;
col_fil(2,5,:,:) = im_green - Hg5;
col_fil(3,5,:,:) = im_blue - Hb5;


F = zeros(number_of_segment, 3, 5, 2);%feature matrix
counter = zeros(number_of_segment, 3, 5);%how many in that super pixel

%fill the F multidim array with the mean--could be faster 
    for i=1:imH
        for j=1:imW
            if(Z(i,j) == 0)
                for k=1:3 %color
                    for c=1:5 %filter
                        F(l(i,j), k, c, 1) = F(l(i,j), k, c, 1) + col_fil(k,c,i,j);
                        counter(l(i,j), k, c) = counter(l(i,j), k, c) + 1;
                    end
                end
            end
        end
    end

    for i=1:number_of_segment
        for k=1:3 %color
           for c=1:5 %filter
              if(counter(i, k, c) ~= 0)
                F(i, k, c, 1) = F(i, k, c, 1)/counter(i, k, c);
              end
           end
        end
    end


    %fill the array with the standard deviation
    for i=1:imH
        for j=1:imW
            if(Z(i,j) == 0)
                for k=1:3 %color
                    for c=1:5 %filter
                        F(l(i,j), k, c, 2) = F(l(i,j), k, c, 2) + (col_fil(k,c,i,j) - F(l(i,j), k, c, 1))^2;
                    end
                end
            end
        end
    end
    
    for i=1:number_of_segment
        for k=1:3 %color
           for c=1:5 %filter
              if(counter(i, k, c) ~= 0)
                F(i, k, c, 2) = sqrt(F(i, k, c, 2))/(counter(i, k, c));
              end
           end
        end
    end
    
    %F(l(10,10),3,1,2)
    %F(l(150,150),3,1,2)
    
    %calculate F_mean that contains mean values for each feature calculate before 
    %mean over the superpixels
F_mean = zeros(3, 5, 2);
for i=1:number_of_segment
   for k=1:3 %color
      for c=1:5 %filter
          F_mean(k, c, 1) = F_mean(k, c, 1) + F(i, k, c, 1);
          F_mean(k, c, 2) = F_mean(k, c, 2) + F(i, k, c, 2);
      end
   end
end

for k=1:3 %color
   for c=1:5 %filter
        F_mean(k, c, 1) = F_mean(k, c, 1)/number_of_segment;
        F_mean(k, c, 2) = F_mean(k, c, 2)/number_of_segment;
   end
end


%now I need the most distant vector from mean in the set (using euclidian distance)
max_distance = -1;
F_max=zeros(3, 5, 2);


for i=1:number_of_segment
    distance = my_euclidian_distance(squeeze(F(i,:,:,:)), F_mean);
    if(distance > max_distance)
        max_distance = distance;
        F_max = squeeze(F(i,:,:,:));
    end
end


% now we evaluate the weight factor of every segment calculated by SLIC
w = zeros(number_of_segment, 2); 

for i=1:number_of_segment
    w(i,1) = my_euclidian_distance(squeeze(F(i,:,:,:)), F_mean);
    w(i,2) = my_euclidian_distance(squeeze(F(i,:,:,:)), F_max);
end

%w(:,2)=max_distance-w(:,1);

%w(l(5,5),1)
%w(l(5,5),2)
%w(l(150,150),1)
%w(l(150,150),2)
figure;
plot(w(:,1));
hold on;
plot(w(:,2)+max_distance+2);
hold off;



%preparation for Symplex algorithm-----------------------------------------
K = 0.1*1; %value of interaction penalty

%count number of edges with the original formation, without S,T
E=sum(sum(adj_matrix))/2;

%create neigbourhood matrix
N=zeros(number_of_segment,E);
Print_m=adj_matrix;
edge_counter=0;
for i=1:number_of_segment
    for j=1:i
        if adj_matrix(i,j)==1;
            edge_counter=edge_counter+1;
            N(i,edge_counter)=1;
            N(j,edge_counter)=-1;
            Print_m(i,j)=edge_counter;
        end
    end
end


%make weights
W=zeros(number_of_segment*2,1);
for i=1:number_of_segment
    W(i,1)                    =   w(i,1)+K*(sum(adj_matrix(i,:))/2);
    W(number_of_segment+i,1)  =   w(i,2)+K*(sum(adj_matrix(i,:))/2);
end

%add S and T, create LP matrices 
A=eye(2*E+number_of_segment*2);
Aeq=[N,-N,eye(number_of_segment),-eye(number_of_segment)];
f=[zeros(1,2*E+number_of_segment),-ones(1,number_of_segment)];
beq=zeros(number_of_segment,1);
ble=[ones(2*E,1)*K;W];


% %structure odf the lp mtrx:
%     E               E           noP         noP
% -----------------------------------------------------
% |           |            |             |            |
% |           |            |             |            |
% |   1       |            |             |            |  < Weights of edges
% |           |            |             |            |
% |           |            |             |            |
% |-----------|------------|             |            |       
% |           |            |             |            |
% |           |     1      |             |            |  
% |           |            |             |            |
% |           |            |             |            |
% |           |------------|-------------|            |         
% |           |            |             |            |
% |           |            |             |            |  
% |           |            |    1        |            |
% |           |            |             |            |
% |           |            |-------------|------------|            
% |           |            |             |            |
% |           |            |             |     1      |  
% |           |            |             |            |
% |           |            |             |            |
% -----------------------------------------------------
% |           |            |             |            |
% |           |            |             |            |
% |     N     |      -N    |             |            |  
% |           |            |       1     |      -1    |     = 0
% |           |            |             |            |
% |           |            |             |            |
%------------------------------------------------------


%minimize
% -|0000000000000000000000000000000000000011111111111111|
lb=zeros(2*E+number_of_segment*2,1);
[x,fval] = linprog(f,A,ble,Aeq,beq,lb);
%find min.cut
C=zeros(1,E);%cut

for i=1:E
    if abs(x(i,1)-ble(i,1))<10^-3 && x(E+i,1)<10^-3
       C(1,i)=1;
    end
    if  abs(x(E+i,1)-ble(E+i,1))<10^-3 && x(i,1)<10^-3
       C(1,i)=1;
    end
    
end
number_of_segment
E
[(1:(2*E+number_of_segment*2))',x,ble]%,[C;C;zeros(2*number_of_segment,1)]]
%Print_m
%adj_matrix
%fval
%sum(x((2*E+1):(2*E+number_of_segment),1))
%sum(x((2*E+number_of_segment+1):(2*E+2*number_of_segment),1))
%view(biograph(adj_matrix,[],'ShowWeights','off'));
 
 edge_counter=0;
 for i=1:number_of_segment
    for j=1:i
        if adj_matrix(i,j)==1
            edge_counter=edge_counter+1;
            if C(1,edge_counter)==1
                adj_matrix(i,j)=0;
                adj_matrix(j,i)=0;
            end
        end
    end
 end 
 %view(biograph(adj_matrix,[],'ShowWeights','off'));
 
 %extract segmentation
 O2=zeros(1,number_of_segment);
 for i=1:number_of_segment
     if abs(x((2*E+number_of_segment+i),1)-ble(2*E+number_of_segment+i,1))<10^-3
         O2(1,i)=1;
         i
     end
 end


% %--------------------------------------------------------------------------------------------------------------------------
% %preparation for max-flow-min-cut algorithm
% K = 0.1; %constant K %value of interaction penalty
%         
%                                                     
% w_adj_matrix(1:number_of_segment,1:number_of_segment)=adj_matrix*K;
% 
% %make work vertices for the triangles
% E=sum(sum(adj_matrix))/2;% number of edges in the graph
% work_vertices_right=zeros(number_of_segment+2,E);
% work_vertices_down=zeros(E,number_of_segment+2);
% 
% % -------------------------
% % | \ data  | |           |
% % |  0 \    | |     WVR   |
% % |________\|_|           |
% % |         |0|           |
% % -------------------------
% % |           |           |
% % |           |    zeros  |
% % |    WVD    |           |
% % |           |           |
% % -------------------------
% 
% % fill in the work fields
% edge_counter=0;
% 
% for j=1:number_of_segment
%     for i=1:j
%         if adj_matrix(i,j)==1
%             edge_counter=edge_counter+1;
%             work_vertices_right(j,edge_counter)=K;
%             work_vertices_down(edge_counter, i)=K;
%             
%         end
%     end
% end
% w_adj_matrix=triu(w_adj_matrix,1);
% 
% number_of_segment
% w_adj_matrix=[...
%     [w_adj_matrix, zeros(number_of_segment,1), ones(number_of_segment,1);...
%     ones(1,number_of_segment),zeros(1,2);zeros(1,number_of_segment+2);...
%     work_vertices_down...
%     ]...
%     ,[ work_vertices_right;zeros(E)]];
% 
% 
% 
% for j=1:number_of_segment
%     w_adj_matrix(number_of_segment+1,j)=w(j,1)+K*(sum(adj_matrix(j,:))/2);
%     %w_adj_matrix(number_of_segment+2,j)=w(j,2)+K*(sum(adj_matrix(j,:))/2);
%     %w_adj_matrix(j,number_of_segment+1)=w(j,1)+K*(sum(adj_matrix(j,:))/2);
%     w_adj_matrix(j,number_of_segment+2)=w(j,2)+K*(sum(adj_matrix(j,:))/2);
% end
% 
% w_adj_matrix=floor(w_adj_matrix*100);
% 
% size(w_adj_matrix)
% [~,~,Orig] = graphmaxflow(sparse(w_adj_matrix), number_of_segment+1, number_of_segment+2);
% O1=Orig(1,:)
% 
% %-------------------------------------------------------------------------------------------------------------------------


L=zeros(imH,imW); %labels

% create label matrix L
for i=1:imH
    for j=1:imW      
        L(i,j) = O2(1,l(i,j));
    end
end

% create block indicator A
A = zeros(imH, imW);
for i=1:8:imH-8
    for j=1:8:imW-8
        temp = 0;
        for k=0:7
            for z=0:7
                temp = temp + L(i+k,j+z);
            end
        end
        temp = temp / 64;
        for k=0:7
            for z=0:7
                A(i+k,j+z) = temp;
            end
        end
    end
end

for i=1:imH
    for j=1:imW
        if(A(i,j) >0)
            G(i,j,1) = 255;
            G(i,j,2) = 0;
            G(i,j,3) = 0;
        end
    end
end
figure;
imshow(G);

% print the images
%subplot(1,2,1); imshow(img);
%title(sprintf('Original %s', file_name));
% Time evaluation
stop_time = cputime;
fprintf('Execution time = %0.5f sec\n',abs( start_time - stop_time));




