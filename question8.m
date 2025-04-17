% Paramètres de base
fs = 44100; % Fréquence d'échantillonnage (supposée, ajustez si différente)
duree_totale = 2; % Durée totale des signaux complets (s)
tolerance = 0.05; % Tolérance pour détection correcte (s)
sigma_b = 0.05; % Écart-type du bruit léger

% Charger les fichiers WAV
[b_signal, fs_b] = audioread('beeee.wav');
[d_signal, fs_d] = audioread('deeee.wav');

% Vérifier et ajuster la fréquence d'échantillonnage
if fs_b ~= fs || fs_d ~= fs
    b_signal = resample(b_signal, fs, fs_b);
    d_signal = resample(d_signal, fs, fs_d);
end

% Normaliser la durée des templates (limiter ou prolonger à 0.2 s pour cohérence)
duree_template = 0.2; % Durée fixe pour les templates
n_samples_template = round(duree_template * fs);
b_template = zeros(n_samples_template, 1);
d_template = zeros(n_samples_template, 1);
b_template(1:min(length(b_signal), n_samples_template)) = b_signal(1:min(length(b_signal), n_samples_template));
d_template(1:min(length(d_signal), n_samples_template)) = d_signal(1:min(length(d_signal), n_samples_template));

% Créer les signaux complets avec silence et bruit
t = 0:1/fs:duree_totale-1/fs;
n_samples_total = length(t);
n0_b = 0.5; % Position de "B" (s)
n0_d = 0.7; % Position de "D" (s)
n0_b_samples = round(n0_b * fs);
n0_d_samples = round(n0_d * fs);

% Signal pour "B"
x_b = zeros(n_samples_total, 1); % Silence initial
x_b(n0_b_samples:n0_b_samples+length(b_template)-1) = b_template; % Insérer "B"
x_b = x_b + sigma_b * randn(size(x_b)); % Ajouter bruit léger

% Signal pour "D"
x_d = zeros(n_samples_total, 1); % Silence initial
x_d(n0_d_samples:n0_d_samples+length(d_template)-1) = d_template; % Insérer "D"
x_d = x_d + sigma_b * randn(size(x_d)); % Ajouter bruit léger

% Paramètres du spectrogramme
fenetre = hamming(round(0.02*fs)); % Fenêtre de 20 ms
chevauchement = round(length(fenetre)*0.5); % 50% de chevauchement
nfft = length(fenetre);

% Initialiser les résultats
evenements = {'Prononciation de B', 'Prononciation de D'};
templates = {b_template, d_template};
signaux = {x_b, x_d};
n0 = [n0_b, n0_d];
t_loc_sec = zeros(1, 2);
correlations = zeros(1, 2);
scores_min = zeros(1, 2);

% Tester chaque événement
figure;
for i = 1:2
    % Calculer les spectrogrammes
    [S, f, t_spec] = spectrogram(signaux{i}, fenetre, chevauchement, nfft, fs);
    [S_ref, ~, ~] = spectrogram(templates{i}, fenetre, chevauchement, nfft, fs);
    
    % Convertir en magnitude
    X = abs(S);
    X_ref = abs(S_ref);
    
    % Dimensions
    [n_freq, n_temps] = size(X);
    [~, n_temps_ref] = size(X_ref);
    
    % Vérifier la faisabilité
    if n_temps < n_temps_ref
        error(['Signal trop court pour ', evenements{i}]);
    end
    
    % Template Matching
    n_scores = n_temps - n_temps_ref + 1;
    scores = zeros(1, n_scores);
    for t_idx = 1:n_scores
        X_seg = X(:, t_idx:(t_idx + n_temps_ref - 1));
        diff = X_seg - X_ref;
        scores(t_idx) = norm(diff, 'fro');
    end
    
    % Trouver la position temporelle
    [min_score, t_loc] = min(scores);
    t_loc_sec(i) = t_spec(t_loc);
    scores_min(i) = min_score;
    
    % Calculer la corrélation
    X_detected = X(:, t_loc:(t_loc + n_temps_ref - 1));
    correlations(i) = corr2(X_ref, X_detected);
    
    % Afficher les scores
    subplot(2, 1, i);
    plot(t_spec(1:n_scores), scores);
    title([evenements{i}, ' : Min à t = ', num2str(t_loc_sec(i)), ' s']);
    xlabel('Temps (s)'); ylabel('Norme de Frobenius');
end
sgtitle('Template Matching pour "B" et "D"');

% Afficher les résultats
disp('Résultats :');
for i = 1:2
    detection_correcte = abs(t_loc_sec(i) - n0(i)) <= tolerance;
    disp([evenements{i}]);
    disp(['  Position réelle : ', num2str(n0(i)), ' s']);
    disp(['  Position détectée : ', num2str(t_loc_sec(i)), ' s']);
    disp(['  Détection correcte : ', num2str(detection_correcte)]);
    disp(['  Norme de Frobenius min : ', num2str(scores_min(i))]);
    disp(['  Corrélation : ', num2str(correlations(i))]);
end