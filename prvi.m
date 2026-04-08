clear;
clc;
close all;

[y, fs_old] = audioread('viva.mp3');

y = mean(y, 2);
y = y - mean(y);

fs_new = 8000;
y = resample(y, fs_new, fs_old);

window_duration_sec = 0.064;
overlap_duration_sec = 0.032;

window_samples = round(window_duration_sec * fs_new);
overlap_samples = round(overlap_duration_sec * fs_new);

[S, F, T] = spectrogram(y, window_samples, overlap_samples, [], fs_new);

figure(1);
imagesc(T, F, abs(S));
set(gca, 'ydir', 'normal');
colorbar;
xlabel('Vrijeme s');
ylabel('Frekvencija Hz');
title('Magnituda spektrograma (linearna skala)');
ylim([0 fs_new/2]);

figure(2);
S_log_magnitude = 10*log10(abs(S) + 1e-6); 
imagesc(T, F, S_log_magnitude);
set(gca, 'ydir', 'normal');
colorbar;
xlabel('Vrijeme s');
ylabel('Frekvencija Hz');
title('Log-magnituda spektrograma - dB skala');
ylim([0 fs_new/2]);


%%-------------------------------------

gs = 9; 
neighborhood_half = floor(gs / 2);
P = true(size(S_log_magnitude));

for di = -neighborhood_half : neighborhood_half
    for dj = -neighborhood_half : neighborhood_half
        if di == 0 && dj == 0
            continue;
        end
        S_shifted = circshift(S_log_magnitude, [di, dj]);
        P = P & (S_log_magnitude > S_shifted);
    end
end

figure(3);
imagesc(T, F, P);
set(gca, 'ydir', 'normal');
colormap(1-gray); 
xlabel('Vrijeme s');
ylabel('Frekvencija Hz');
title(sprintf('Mapa konstelacije za gs = %d', gs));
ylim([0 fs_new/2]);

total_peaks = sum(P(:));
total_duration_sec = T(end);
avg_peaks_per_sec = total_peaks / total_duration_sec;

fprintf('Ukupno: %d\n', total_peaks);
fprintf('Prosječno: %.2f\n', avg_peaks_per_sec);


%%---------------------------------------------------
threshold = -1;

P_thresholded = P & (S_log_magnitude > threshold);

figure(4);
imagesc(T, F, P_thresholded);
set(gca, 'ydir', 'normal');
colormap(1-gray); 
xlabel('Vrijeme s');
ylabel('Frekvencija Hz');
title(sprintf('Filtrirana mapa');
ylim([0 fs_new/2]);

total_peaks_filtered = sum(P_thresholded(:));
avg_peaks_per_sec_filtered = total_peaks_filtered / T(end);


fprintf('Prag: %.1f\n', threshold);
fprintf('Ukupan poslije filtriranja %d\n', total_peaks_filtered);
fprintf('Prosjek poslije filtiranja %.2f\n', avg_peaks_per_sec_filtered);


%%-----------------------------------------------------------------

fanout = 3;
delta_t_min_sec = 0.5;
delta_t_max_sec = 2.0;
delta_f_hz = 400;

[peak_freq_indices, peak_time_indices] = find(P_thresholded);

num_peaks = length(peak_time_indices);
hash_table = [];

figure(4);
hold on;

for i = 1:num_peaks
    
    anchor_time_idx = peak_time_indices(i);
    anchor_freq_idx = peak_freq_indices(i);
    
    t1 = T(anchor_time_idx);
    f1 = F(anchor_freq_idx);
    
    min_time_idx = anchor_time_idx + round(delta_t_min_sec / (T(2)-T(1)));
    max_time_idx = anchor_time_idx + round(delta_t_max_sec / (T(2)-T(1)));
    
    min_freq_idx = anchor_freq_idx - round(delta_f_hz / (F(2)-F(1)));
    max_freq_idx = anchor_freq_idx + round(delta_f_hz / (F(2)-F(1)));
    
    min_freq_idx = max(1, min_freq_idx);
    max_freq_idx = min(size(P_thresholded, 1), max_freq_idx);

    neighbors_found = 0;
    
    for j = (i+1):num_peaks
        
        target_time_idx = peak_time_indices(j);
        target_freq_idx = peak_freq_indices(j);

        if neighbors_found >= fanout
            break;
        end
        
        if target_time_idx >= min_time_idx && ...
           target_time_idx <= max_time_idx && ...
           target_freq_idx >= min_freq_idx && ...
           target_freq_idx <= max_freq_idx
       
            t2 = T(target_time_idx);
            f2 = F(target_freq_idx);
            
            delta_t = t2 - t1;
            
            hash_entry = [f1, f2, t1, delta_t];
            hash_table = [hash_table; hash_entry];
            
            neighbors_found = neighbors_found + 1;
            
            line([t1, t2], [f1, f2], 'Color', [0.5 0.5 0.5], 'LineWidth', 0.5);
        end
        
        if target_time_idx > max_time_idx
            break;
        end
    end
end








