% Charger le fichier audio du jeu de données
[x, fs] = audioread('test/section_00_0000.wav');

% Sélectionner la première seconde du signal pour une comparaison cohérente
t_max = 1;  % Durée en secondes
n_echantillons = min(round(t_max * fs), length(x));
x_segment = x(1:n_echantillons);

% Définir les paramètres d'analyse
type_fenetre = 'Hamming';          % Type de fenêtre pour réduire les fuites spectrales
fraction_chevauchement = 0.5;      % Chevauchement de 50% entre fenêtres
durees_fenetre = [0.01, 0.02, 0.04]; % Durées des fenêtres en secondes : 10 ms, 20 ms, 40 ms

% Créer une figure pour afficher les spectrogrammes
figure;

% Boucle sur les différentes durées de fenêtre
for i = 1:3
    % Calculer la longueur de la fenêtre en échantillons basée sur la fréquence d'échantillonnage
    longueur_fenetre = round(durees_fenetre(i) * fs);
    if mod(longueur_fenetre, 2) == 1
        longueur_fenetre = longueur_fenetre + 1;  % Assurer une longueur paire
    end
    
    % Spécifier les paramètres
    chevauchement = round(longueur_fenetre * fraction_chevauchement); % Chevauchement en échantillons (50%)
    nfft = longueur_fenetre;         % Taille de la TFD égale à la longueur de la fenêtre
    fenetre = hamming(longueur_fenetre); % Fenêtre de Hamming
    
    % Tracer le spectrogramme dans un sous-graphique
    subplot(3, 1, i);
    spectrogram(x_segment, fenetre, chevauchement, nfft, fs, 'yaxis');
    title(['Spectrogramme avec Durée de Fenêtre = ', num2str(durees_fenetre(i)*1000), ' ms']);
    xlabel('Temps (s)');
    ylabel('Fréquence (Hz)');
end

% Ajuster la mise en page de la figure
sgtitle('Analyse Temps-Fréquence avec Différentes Longueurs de Fenêtre');