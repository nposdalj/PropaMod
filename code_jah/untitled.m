latitude = 33.483;
longitude = -122.576;

[row, col] = geographicToIntrinsic(R, latitude, longitude);

% Step 3: Find the value at the specified coordinates
value = A(round(row), round(col));
A_double = double(A);
% Step 4: Display the result
figure;
geoshow(A_double, R);
hold on;
plot(col, row, 'r.', 'MarkerSize', 10); % Mark the specified point
hold off;

disp('Value at specified coordinates:');
disp(value);