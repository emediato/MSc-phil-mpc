function Pulse = FCS_CURRENT_PMSM(wpu, t, thetae, Ts, id, iq, id_ref, iq_ref)
    % Parâmetros do Motor Síncrono de Ímã Permanente (PMSM)
    L = 0.02652;    % Indutância do estator (Henries)
    R = 15.7;       % Resistência do estator (Ohms)
    Sim = 0.1716;   % Fluxo magnético do ímã permanente (Wb)
    Vdc = 500;      % Tensão do barramento de corrente contínua (Volts)

    % Matriz com os 8 estados de chaveamento possíveis de um inversor de 2 níveis
    S = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 1 1; 0 0 1; 1 0 1; 1 1 1];

    % Inicialização do vetor de custo para os 8 estados
    cost = zeros(8,1);

    % Inicialização do vetor de saída dos pulsos (6 chaves do inversor)
    Pulse = [0,0,0,0,0,0];

    % Laço de repetição para avaliar o modelo preditivo para cada um dos 8 vetores de tensão
    for i = 1:1:8
        % Extrai os estados das chaves para o vetor atual
        Sa = S(i,1);
        Sb = S(i,2);
        Sc = S(i,3);

        % Cálculo das tensões de fase do inversor referenciadas ao neutro da carga
        Vinva = (Vdc * (2*Sa - Sb - Sc)) / 3;
        Vinvb = (Vdc * (2*Sb - Sa - Sc)) / 3;
        Vinvc = (Vdc * (2*Sc - Sb - Sa)) / 3;

        % Transformação de abc para o referencial síncrono rotativo (dq)
        vsq = (2/3) * ( (Vinva*cos((wpu*t + thetae))) + (Vinvb*cos((wpu*t) + thetae + (4*pi/3))) + (Vinvc*cos((wpu*t) + thetae + (2*pi/3))) );
        vsd = (2/3) * ( (Vinva*sin((wpu*t + thetae))) + (Vinvb*sin((wpu*t) + thetae + (4*pi/3))) + (Vinvc*sin((wpu*t) + thetae + (2*pi/3))) );

        % Equações preditivas do modelo discreto do PMSM (Predição em k+1)
        id_p = ((1 - (R*Ts/L)) * id) + (Ts*wpu*iq) + (vsd*Ts/L);
        iq_p = ((1 - (R*Ts/L)) * iq) - (Ts*wpu*id) - (Sim*wpu*Ts) + (vsq*Ts/L);

        % Função de custo: Avalia o erro quadrático entre as correntes de referência e as preditas
        cost(i,1) = ((id_ref - id_p) * (id_ref - id_p)) + ((iq_ref - iq_p) * (iq_ref - iq_p));
    end

    % Ordena o vetor de custos em ordem crescente
    [~, index] = sort(cost);

    % Seleciona os pulsos de disparo (Gating Signals) com base no vetor que minimizou a função de custo
    if index(1,1) == 1
        Pulse = [0,1,0,1,0,1]; % Vetor V0 (000)
    end
    if index(1,1) == 2
        Pulse = [1,0,0,1,0,1]; % Vetor V1 (100)
    end
    if index(1,1) == 3
        Pulse = [1,0,1,0,0,1]; % Vetor V2 (110)
    end
    if index(1,1) == 4
        Pulse = [0,1,1,0,0,1]; % Vetor V3 (010)
    end
    if index(1,1) == 5
        Pulse = [0,1,1,0,1,0]; % Vetor V4 (011)
    end
    if index(1,1) == 6
        Pulse = [0,1,0,1,1,0]; % Vetor V5 (001)
    end
    if index(1,1) == 7
        Pulse = [1,0,0,1,1,0]; % Vetor V6 (101)
    end
    if index(1,1) == 8
        Pulse = [1,0,1,0,1,0]; % Vetor V7 (111)
    end
end
