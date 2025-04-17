% Paramètres de base
fs = 44100; % Fréquence d'échantillonnage (Hz)
duree = 2;  % Durée totale (s)
n0 = 0.5;   % Position de l'événement (s)
duree_event = 0.1; % Durée de l'événement (s)
tolerance = 0.05; % Tolérance pour une détection correcte (s)

% Générer le signal synthétique
t = 0:1/fs:duree-1/fs;
x = 0.1 * randn(size(t)); % Bruit blanc de faible amplitude
n0_samples = round(n0 * fs); % Position en échantillons
event_samples = round(duree_event * fs); % Durée de l'événement en échantillons
event = sin(2*pi*1000*t(1:event_samples)); % Sinusoïde de 1000 Hz
x(n0_samples:n0_samples+event_samples-1) = x(n0_samples:n0_samples+event_samples-1) + event;

% Générer le signal de référence (template)
t_ref = 0:1/fs:duree_event-1/fs;
x_ref = sin(2*pi*1000*t_ref);

% Paramètres du spectrogramme
fenetre = hamming(round(0.02*fs)); % Fenêtre de 20 ms
chevauchement = round(length(fenetre)*0.5); % 50% de chevauchement
nfft = length(fenetre);

% Calculer les spectrogrammes
[S, f, t_spec] = spectrogram(x, fenetre, chevauchement, nfft, fs);
[S_ref, ~, ~] = spectrogram(x_ref, fenetre, chevauchement, nfft, fs);

% Convertir en magnitude
X = abs(S); % Spectrogramme complet
X_ref = abs(S_ref); % Template

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
    scores(t_idx) = norm(diff, 'fro'); % Norme de Frobenius
end

% Trouver la position temporelle
[~, t_loc] = min(scores);
t_loc_sec = t_spec(t_loc); % Position en secondes

% Calcul des métriques
% 1. Précision et Rappel
true_positives = abs(t_loc_sec - n0) <= tolerance; % Vrai positif si dans la tolérance
precision = true_positives; % Une seule détection, donc 1 si correcte, 0 sinon
recall = true_positives; % Un seul événement réel, donc 1 si détecté, 0 sinon

% 2. Corrélation
X_detected = X(:, t_loc:(t_loc + n_temps_ref - 1)); % Segment détecté
correlation = corr2(X_ref, X_detected); % Corrélation 2D normalisée

% Afficher les résultats
figure;
subplot(3,1,1);
plot(t, x);
title('Signal Synthétique avec Événement à n_0 = 0.5 s');
xlabel('Temps (s)'); ylabel('Amplitude');

subplot(3,1,2);
imagesc(t_spec, f, 20*log10(X)); axis xy; colorbar;
title('Spectrogramme du Signal Complet');
xlabel('Temps (s)'); ylabel('Fréquence (Hz)');

subplot(3,1,3);
plot(t_spec(1:n_scores), scores);
title(['Score de Template Matching (Min à t = ', num2str(t_loc_sec), ' s)']);
xlabel('Temps (s)'); ylabel('Norme de Frobenius');

% Afficher les métriques
disp(['Position réelle de l’événement : ', num2str(n0), ' s']);
disp(['Position détectée : ', num2str(t_loc_sec), ' s']);
disp(['Précision : ', num2str(precision)]);
disp(['Rappel : ', num2str(recall)]);
disp(['Corrélation : ', num2str(correlation)]);