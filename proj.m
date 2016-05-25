close all;
clear;

path = 'CAMERA1_JPEGS_TRAINING\'; frameIdComp = 4;
str = ['%s%.' num2str(frameIdComp) 'd.%s'];

nFrame = 3064;
step = 5;
th = 30;

img = imread('CAMERA1_JPEGS_TRAINING\0001.jpg');
bkg = zeros(size(img));

% ------ Background -------- %
alfa = 0.01;
for k=1 : step : nFrame
    strl = sprintf(str, path,k,'jpg');
    img = imread(strl);
    y = img;
    bkg = alfa * double(y) + (1-alfa) * double(bkg);
end
% ------ Background -------- %

% ------ Compara��o frame t / frame t-1 -------- %
for k=1 : step : nFrame
    strl = sprintf(str, path,k,'jpg');
    img = imread(strl);
     
    % Calcular a imagem binaria
    imDiff = (abs(double(img(:,:,1)) - double(bkg(:,:,1))) > th) |...
             (abs(double(img(:,:,2)) - double(bkg(:,:,2))) > th) |...
             (abs(double(img(:,:,3)) - double(bkg(:,:,3))) > th);
         
    % Opera��es de limpeza
    imDiff = medfilt2(imDiff);
    imDiff = bwareaopen(imDiff, 20, 8);
    imDiff = bwconvhull(imDiff, 'objects');
    imDiff = bwmorph(imDiff,'fill');
    
    [lb, num] = bwlabel(imDiff);
    props = regionprops(lb,'BoundingBox', 'Area');
    
    
    % ------ Excluir regioes pequenas --------%
    auxVar = 1;
    for prop = 1 : length(props)
        if (props(prop).Area > 150)
            aux(auxVar) = props(prop);
            auxVar = auxVar + 1;
        end
    end
    % ------ Excluir regioes pequenas -------- %
    
    imshow(imDiff);
    text(10,30,int2str(k),'color','r');
    
    if (k == 1) % Primeiro frame para as diferen�as
        thatBB = cell(1, length(aux));
        for n = 1 : length(aux)
            thatBB{n} = aux(n).BoundingBox; % ThatBB --> Estrutura com BoundingBoxes do frame t-1
        end
    else
        thisBB = cell(1,length(aux));
        for m = 1 : length(aux)
          thisBB{m} = aux(m).BoundingBox; % ThisBB --> Estrutura com BoundingBoxes do frame t
        end
        for i = 1 : length(thisBB) % Verificar todas as diferen�as entre as BB do frame t e t-1
            for j = 1 : length(thatBB)
                DiffX = abs(thisBB{i}(1) - thatBB{j}(1));
                DiffY = abs(thisBB{i}(2) - thatBB{j}(2));
                if ( DiffX > 8 ) && ( DiffX < 20 ) && ( DiffY > 8 ) && ( DiffY < 20 ) %Caso a diferen�a seja significativa, assinalar na Matrix
                    Matrix(i,j) = 1;
                else
                    Matrix(i,j) = 0;
                end
            end
        end
        MMatrix = transpose(Matrix);
        for a = 1 : length(thisBB)
            for b = 1 : length(thatBB)
                if (Matrix(a,b) == 1)
                    Smatrix(a) = b;
                end
                if (MMatrix(b,a) == 1)
                    Tmatrix(a) = b;
                end
            end
        end
        for l = 1 : length(thisBB) % Tratar todas as regi�es assinaladas na Matrix
            if( Matrix(l,:) == 1)
                if(thisBB{l}(3) < thisBB{l}(4)) % Caso sejam pessoas
                    rectangle('Position', [thisBB{l}(1),thisBB{l}(2),thisBB{l}(3),thisBB{l}(4)],'EdgeColor','g','LineWidth',2 )
                    text(thisBB{l}(1)-10,thisBB{l}(2)-20,'Person','color','g');
                else % Caso sejam carros
                    rectangle('Position', [thisBB{l}(1),thisBB{l}(2),thisBB{l}(3),thisBB{l}(4)],'EdgeColor','r','LineWidth',2 )
                    text(thisBB{l}(1)-10,thisBB{l}(2)-20,'Car','color','r');
                end
                drawnow;
            end
        end
        thatBB = thisBB; % Preparar as BB do frame t para estarem presentes como t-1 no pr�ximo frame
    end

    drawnow
end