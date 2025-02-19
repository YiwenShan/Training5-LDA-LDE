% 5折交叉验证
clear;
load('Yale_32.mat');
Yale = fea'; clear fea; % X:D*N  gnd:N*1
[D,N] = size(Yale);
rand('seed', 6); % 
cv5 = randperm(N)';
fold = 5; % 5-fold cross validation
Ntest = floor(N/fold);
%%
ki=4; ko=6; t=2e7;
lb_d=2; ub_d=60; len_d = ub_d-lb_d+1;
Acc_cv5 = zeros([fold, len_d]);
for f=1:fold
    is_test = false([N,1]);
    is_test((f-1)*Ntest+1:f*Ntest) = true;
    is_train = ~is_test;
    
    testset = Yale(:, cv5(is_test)); % D*Ntest
    gndtest = gnd(cv5(is_test)); % Ntest*1
    trainset = Yale(:, cv5(is_train)); % D*Ntrain
    gndtrain = gnd(cv5(is_train)); % Ntrain*1
    
    [E] = LDE(trainset, gndtrain, ki, ko, t, 0.97); % E:D*D
    for d=lb_d:ub_d
        Y_train = E(:,1:d)'*trainset; % 1:d
        Y_test  = E(:,1:d)'*testset; % 2:d+1
        acc = 0;
        for j=1:Ntest
            y = Y_test(:,j); % d*1
            dist = sum((repmat(y,[1,N-Ntest]) - Y_train).^2, 1);
            [~,idx] = sort(dist); % 距离 升序排
            pred = gndtrain(idx(1)); % 最近邻的类别 = j号测试样本的类别
            acc = acc + (pred==gndtest(j));
        end
        acc = acc/Ntest; % 
        Acc_cv5(f, d-lb_d+1) = acc;
    end
end
Acc_avg = mean(Acc_cv5)'; % len_d*1
maxAcc = Acc_avg(1); maxidx = 1;
for j=2:len_d
    if Acc_avg(j)>maxAcc
        maxAcc = Acc_avg(j);
        maxidx = j;
    end
end
fprintf('Max: %f %d\n', maxAcc, maxidx);
figure('Name',['ki',num2str(ki),'_ko',num2str(ko), '_t',num2str(t)]);
plot(lb_d:ub_d, Acc_avg, '^-', 'Color',[162,20,47]./255,'MarkerFaceColor','w','Linewidth',1.5);
xlabel('Dims', 'Fontsize', 16);
ylabel('Recognition rate (%)', 'Fontsize', 16);
%% 遍历 ki, ko
% for t=[2e7]
% l_ki = 2; u_ki = 9; len_ki = u_ki - l_ki + 1;
% l_ko = 2; u_ko = 30; s_ko=2; len_ko = floor((u_ko-l_ko)/s_ko)+1;
% Acc_kk = zeros([len_ki, len_ko, fold]);
% d = 17;
% for f=1:fold
%     is_test = false([N,1]);
%     is_test((f-1)*Ntest+1:f*Ntest) = true;
%     is_train = ~is_test;
%     
%     testset = Yale(:, cv5(is_test)); % D*Ntest
%     gndtest = gnd(cv5(is_test)); % Ntest*1
%     trainset = Yale(:, cv5(is_train)); % D*Ntrain
%     gndtrain = gnd(cv5(is_train)); % Ntrain*1
%     
%     for ki=l_ki:u_ki
%         for ko=l_ko:s_ko:u_ko
%             [E] = LDE(trainset, gndtrain, ki, ko, t, 0.97); % E:D*D
% 
%             Y_train = E(:,1:d)'*trainset; % 1:d
%             Y_test  = E(:,1:d)'*testset; % 2:d+1
%             acc = 0;
%             for j=1:Ntest
%                 y = Y_test(:,j); % d*1
%                 dist = sum((repmat(y,[1,N-Ntest]) - Y_train).^2, 1);
%                 [~,idx] = sort(dist); % 距离 升序排
%                 pred = gndtrain(idx(1)); % 最近邻的类别 = j号测试样本的类别
%                 acc = acc + (pred==gndtest(j));
%             end
%             acc = acc/Ntest; % 
%             Acc_kk(ki-l_ki+1, (ko-l_ko)/s_ko+1, f) = acc;
%         end
%     end
% end
% % 多次交叉验证的平均
% Acc_avg = mean(Acc_kk, 3); % len_ki, len_ko
% 
% figure('Name', ['t=', num2str(t)]);
% bar_3 = bar3(Acc_avg);
% for k=1:length(bar_3)
%     bar_3(k).CData = bar_3(k).ZData; % 颜色与Z取值成正比
%     bar_3(k).FaceColor = 'interp';
% end
% zlim([0.8,0.9]);
% set(gca, 'xTick', [1:2:len_ko]); % ko
% set(gca, 'xTicklabel', split(num2str( l_ko:2*s_ko:u_ko )) ); % 
% % set(gca, 'yTick', [1:len_ki]); % ki
% set(gca, 'yTicklabel', split(num2str( l_ki:u_ki )) );
% set(gca,'XGrid', 'off', 'YGrid', 'off','ZGrid', 'on')
% xlabel('$k_o$', 'Interpreter', 'latex', 'Fontsize', 14);
% ylabel('$k_i$', 'Interpreter', 'latex', 'Fontsize', 14);
% zlabel('$Accuracy$', 'Interpreter', 'latex', 'Fontsize', 14);
% view([-90, 1]); % 0度:延第二维度(↓)的反方向(↑) 正视第一维度(→)
% end