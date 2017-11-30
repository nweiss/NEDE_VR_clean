function pathLocation = convertBillboardtoPathLocation(billboardLocation)

    % billboardLocation: x,y coords in columns
    % pathLocation: : x,y coords in columns

    billboardX = billboardLocation(:,1);
    billboardY = billboardLocation(:,2);
    
    %
    pathNumber = floor((billboardX + 5)/15);
    
    pathX = 15*pathNumber;
    
    pathLocation = [pathX,billboardY];
end