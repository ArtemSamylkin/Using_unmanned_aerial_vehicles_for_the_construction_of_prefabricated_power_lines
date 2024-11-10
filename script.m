clc
clear
close all


% Блок ввода исходных данных 

Unom = 230;

P_load = input('Введите мощность нагрузки в кВт: ');
L = input('Введите расстояние между нагрузкой и источником в м: ');

% P_load =  table2array(readtable('data.xlsx', 'Range', 'A1:A2', 'ReadRowNames',false));
L =  table2array(readtable('data.xlsx', 'Range','B1:B2', 'ReadRowNames',false));
R0 =  table2array(readtable('data.xlsx', 'Range','G1:G11', 'ReadRowNames',false));
Imax = table2array(readtable('data.xlsx', 'Range','E1:E11', 'ReadRowNames',false));
m = table2array(readtable('data.xlsx', 'Range', 'H1:H11', 'ReadRowNames',false));
dL = table2array(readtable('data.xlsx', 'Range', 'C1:C2', 'ReadRowNames',false));
names = table2array(readtable('data.xlsx', 'Range', 'K1:K11', 'ReadRowNames',false));

time_to_work_mat = table2array(readtable('data.xlsx', 'Range', 'J23:J32', 'ReadRowNames',false));
time_to_power_mat = 60*table2array(readtable('data.xlsx', 'Range', 'K23:K32', 'ReadRowNames',false));

ind = 0;
if ind == 0
    for n = 1:length(R0)
    
    sim('model.slx');

    I = ans.I(2);
    U = ans.U(2);
    
    if I<Imax(n) & U>0.9*Unom
        ind = 1;
    end
    end
end

G =  table2array(readtable('data.xlsx', 'Range', 'I1:I11', 'ReadRowNames',false));
C =  table2array(readtable('data.xlsx', 'Range','J1:J11', 'ReadRowNames',false));  % цена квадрокоптера
N_QD = zeros(1, length(G));
C_sum = zeros(1, length(G));

for k = 1:length(G)
    
    N_QD(k) = ceil(m(n) / 2 / G(k)) + 1; % количество дронов, удерживающих один провод, без учета технических ограничений
    
    if N_QD(k) < L/dL - 1
    
        N_QD(k) = ceil(L/dL - 1);
    end
   count = N_QD(k);  % количество дронов
time_to_work = time_to_work_mat(k);  % время работы
time_to_power = time_to_power_mat(k);  % время зарядки
delta_t = 5;

powers = containers.Map();  % словарь для дронов на зарядке
workers = containers.Map();  % словарь для работающих дронов
for i = 1:count
    workers(sprintf('модель %d', i)) = i * delta_t;
end

count_now = count + 1;
can_fly = {};
all_powers = [];

for i = 1:288
    x = keys(powers);
    for j = 1:length(x)
        dron = x{j};
        powers(dron) = powers(dron) + delta_t;
        if powers(dron) >= time_to_power
            can_fly{end+1} = dron; %#ok<AGROW>
            remove(powers, dron);
        end
    end
    
    s = keys(workers);
    for j = 1:length(s)
        dron = s{j};
        workers(dron) = workers(dron) + delta_t;
        if workers(dron) > time_to_work - delta_t
            powers(dron) = 0;
            remove(workers, dron);
            if ~isempty(can_fly)
                zamena = can_fly{1};
                can_fly(1) = [];  % удалить первый элемент из массива
            else
                zamena = sprintf('модель %d', count_now);
                count_now = count_now + 1;
            end
            workers(zamena) = delta_t;
            fprintf('заменил %s на %s\n', dron, zamena);
        end
    end
    
    fprintf('дроны в воздухе: '); disp(workers.keys());
    
    if ~isempty(powers)
        fprintf('дроны на зарядке: '); disp(powers.keys());
    else
        disp(0);
    end
    
    all_powers(end+1) = length(powers); %#ok<AGROW>
end

fprintf('прогон сценария: %.2f ч\n', delta_t * 5000 / 60);
fprintf('дронов понадобится: %d\n', count_now);
fprintf('максимум моделей на зарядке: %d\n', max(all_powers));


C_sum(k) = 2 * count_now * C(k);
all_powers = all_powers(1:100);
x_values = 1:length(all_powers);

figure('Position', [100, 100, 1200, 600])
bar(x_values, all_powers)



title('Дроны на станции для зарядки')
xlabel('Момент времени t')
ylabel('Кол-во дронов')
set(gca, 'XTick', x_values, 'XTickLabel', x_values, 'XTickLabelRotation', 90)
grid on
    end
        
 


[C_opt, i_opt] = min(C_sum);
disp('Необходимое количество дронов')
disp(C_opt/2/C(i_opt))
disp('Модель дрона:')
disp(string(names(i_opt)))