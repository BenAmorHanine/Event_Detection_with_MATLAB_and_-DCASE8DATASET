% Paramètres de base
fs = 44100; % Fréquence d'échantillonnage (Hz)
duree = 2;  % Durée totale (s)
n0 = 0.5;   % Position de l'événement (s)
duree_event = 0.1; % Durée de l'événement (s)
tolerance = 0.05; % Tolérance pour détection correcte (s)

% Générer le signal propre
t = 0:1/fs:duree-1/fs;
x_clean = 0.1 * randn(size(t)); % Bruit blanc de fond
n0_samples = round(n0 * fs);
event_samples = round(duree_event * fs);
event = sin(2*pi*1000*t(1:event_samples)); % Sinusoïde de 1000 Hz
x_clean(n0_samples:n0_samples+event_samples-1) = x_clean(n0_samples:n0_samples+event_samples-1) + event;

% Générer le template
t_ref = 0:1/fs:duree_event-1/fs;
x_ref = sin(2*pi*1000*t_ref);

% Paramètres du spectrogramme
fenetre = hamming(round(0.02*fs)); % Fenêtre de 20 ms
chevauchement = round(length(fenetre)*0.5); % 50% de chevauchement
nfft = length(fenetre);

% Niveaux de variance du bruit
sigma_b = [0.01, 0.1, 1]; % Écarts-types du bruit
n_cases = length(sigma_b);

% Initialiser les résultats
t_loc_sec = zeros(1, n_cases);
correlations = zeros(1, n_cases);
scores_min = zeros(1, n_cases);

% Boucle sur les niveaux de bruit
figure;
for i = 1:n_cases
    % Ajouter le bruit
    b = sigma_b(i) * randn(size(t)); % Bruit gaussien
    x_noisy = x_clean + b;

    % Calculer les spectrogrammes
    [S, f, t_spec] = spectrogram(x_noisy, fenetre, chevauchement, nfft, fs);
    [S_ref, ~, ~] = spectrogram(x_ref, fenetre, chevauchement, nfft, fs);

    % Convertir en magnitude
    X = abs(S);
    X_ref = abs(S_ref);

    % Dimensions
    [n_freq, n_temps] = size(X);
    [~, n_temps_ref] = size(X_ref);

    % Vérifier la faisabilité
    if n_temps < n_temps_ref
        error('Le signal est trop court pour le template.');
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
    subplot(n_cases, 1, i);
    plot(t_spec(1:n_scores), scores);
    title(['Score pour \sigma_b = ', num2str(sigma_b(i)), ' (Min à t = ', num2str(t_loc_sec(i)), ' s)']);
    xlabel('Temps (s)'); ylabel('Norme de Frobenius');
end
sgtitle('Template Matching avec Différents Niveaux de Bruit');

% Afficher les résultats
disp('Résultats :');
for i = 1:n_cases
    detection_correcte = abs(t_loc_sec(i) - n0) <= tolerance;
    disp(['\sigma_b = ', num2str(sigma_b(i))]);
    disp(['  Position détectée : ', num2str(t_loc_sec(i)), ' s']);
    disp(['  Détection correcte : ', num2str(detection_correcte)]);
    disp(['  Norme de Frobenius min : ', num2str(scores_min(i))]);
    disp(['  Corrélation : ', num2str(correlations(i))]);
end