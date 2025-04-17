% Charger le signal complet
[x, fs] = audioread('test/section_00_0000.wav');
x = x(1:min(round(fs), length(x))); % Limiter à 1 seconde pour l'exemple

% Créer un signal de référence synthétique (0.1s à 1000 Hz)
t_ref = 0:1/fs:0.1-1/fs;
x_ref = sin(2*pi*1000*t_ref); % Assurer que la référence est assez longue

% Paramètres du spectrogramme
fenetre = hamming(round(0.02*fs)); % Fenêtre de 20 ms
chevauchement = round(length(fenetre)*0.5); % 50% de chevauchement
nfft = length(fenetre);

% Calculer les spectrogrammes
[S, f, t] = spectrogram(x, fenetre, chevauchement, nfft, fs);
[S_ref, ~, ~] = spectrogram(x_ref, fenetre, chevauchement, nfft, fs);

% Convertir en magnitude
X = abs(S); % Spectrogramme complet
X_ref = abs(S_ref); % Template

% Vérifier les dimensions
[n_freq, n_temps] = size(X);
[~, n_temps_ref] = size(X_ref);
disp(['n_temps = ', num2str(n_temps), ', n_temps_ref = ', num2str(n_temps_ref)]);

% Vérifier si le template matching est possible
if n_temps < n_temps_ref
    error('Le signal complet est trop court pour contenir le template.');
end

% Initialiser le vecteur de scores
n_scores = n_temps - n_temps_ref + 1;
scores = zeros(1, n_scores);

% Template Matching
for t_idx = 1:n_scores
    X_seg = X(:, t_idx:(t_idx + n_temps_ref - 1)); % Segment glissant
    diff = X_seg - X_ref; % Différence
    scores(t_idx) = norm(diff, 'fro'); % Norme de Frobenius
end

% Trouver la position temporelle
[~, t_loc] = min(scores);
if t_loc > length(t)
    t_loc = length(t); % Limiter à la taille maximale de t
end
t_loc_sec = t(t_loc); % Convertir en secondes

% Afficher le résultat
figure;
subplot(2,1,1);
imagesc(t, f, 20*log10(X)); axis xy; colorbar;
title('Spectrogramme du Signal Complet');
xlabel('Temps (s)'); ylabel('Fréquence (Hz)');
subplot(2,1,2);
plot(t(1:n_scores), scores);
title(['Score de Template Matching (Min à t = ', num2str(t_loc_sec), ' s)']);
xlabel('Temps (s)'); ylabel('Norme de Frobenius');

disp(['Position détectée : ', num2str(t_loc_sec), ' secondes']);